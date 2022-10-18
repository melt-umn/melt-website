---
title: Origins
weight: 1200
---

{{< toc >}}


## High level

Silver can track the origins of nonterminals constructed in programs.
This is implemented following the paper [Origin Tracking in Attribute Grammars by Kevin Williams and Eric Van Wyk.](https://www-users.cs.umn.edu/~evw/pubs/williams14sle/index.html)
More simply: each node (instance of a nonterminal type) gains an additional piece of information called it's origin, which is a reference to the node that it 'came from.'
It may also have a similar reference called the redex to a node that catalyzed the motion of the node from one place in the tree to another.
It also gains a marker called 'er' that indicates if the transformation that produced it was trivial or not, and gains a set of 'notes' that describe the transformation that produced it.

When a node is constructed it's origin is set to the node on which the rule that constructed it was evaluated.
For example, if a node representing an expression has a rule for an attribute that constructs an expanded version of it, all of the nodes newly constructed in that rule gain the original node as their origin.
When a attribute is defined to be an attribute of a child, the value assigned to the attribute is a copy of that child with it's redex set to the node on which that rule occurs.
The redex then represents the node that catalyzed the movement of the child to the parent's position in the resulting value.



## I don't care about the theory - someone told me I could use this instead of the location annotation

OK. Here is the whirlwind porting guide:
 1. Mark everything that has a `location` annotation as `tracked`
 2. Get rid of the `location` annotation and associated swizzling 🎉🎉🎉
 4. Instead of using `top.location` for error messages instead raise errors/etc with `errFromOrigin(top, ...)`/etc
 5. Start building your project with `--no-redex` instead of `--no-origins` (if you were) and build it `--clean`ly [at least once](#build-issues)

### More complex idioms

Another way to think about adding origin tracking if all you care about is replacing `location` is that the entire codebase gets an implicit `Location` argument that is handled by the runtime.
This implicit argument always refers to the location of the nonterminal the rule currently executing was defined on (so in functions it refers to the location of the nonterminal that invoked the function.)
The implicit location argument can be altered then by way of `attachNote logicalLocationNote(loc);` which sets the implicit location argument to `loc` for the entire block of declarations it occurs on, or `attachNote logicalLocationNote(loc) on {expr}` which sets it only for the context of `expr`.

**It's more complicated + powerful + cooler than that, but that mental model will totally work for ridding yourself of `location` :)**

In cases where swizzling was not just `location=top.location` you an add an `attachNote logicalLocationNote(loc);` statement, getting `loc` from `getParsedOriginLocationOrFallback(node)`.
This statement means that that a node constructed in the body alongside that statement is traced back to a textual location that location will be used instead of the textual location of the node on which the rule was defined.

What do you want to mark `tracked`? Maybe more than just what had a `location`.
Origin tracking can also replace manually tracking the source location that definition nonterminals in environments need to keep track of.
Children in definition nonterminals representing definition location and attributes holding the same can be removed.
Marking the definition nonterminal `tracked` will (usually) do the same (assuming it is constructed in a rule on the node it originates from - if not, use `logicalLocationNote` to adjust it.)

How about cases where a `Location` is passed into a function? It can (almost always) be removed.
Generally instead of taking a location in helpers one can use the implicit origin information that flows into functions.
Origins from the call-site of the function apply to values constructed within.
If the function was called with `top.location` and that value was used to construct new nodes, the observable behavior in tracking the source location will be the exact same.
If something other than `top.location` was used, a `logicalLocationNote` can be used to adjust the origin information at the call site of the function.
If a `Location` is passed with the express purpose of raising an error it can be removed as well.
Either use `errFromOrigin` with one of the arguments as the origin, or use `errFromorigin(ambientOrigin(), ...)` to raise the error using the origin information flowing into the function.
(The source location can also be derived using `getParsedOriginLocationOrFallback(ambientOrigin())` if that is needed for e.g. an error message.)

What about cases where a lambda takes a Location?
This comes up in code where (for example) `Expr`s define a attribute that is a lambda for how to do some manipulation (e.g. take the address) of them.
Imagine we have an `Expr` type with a attribute `addressOfProd` (taken from AbleC) that is of the type `Expr ::= Location`.
The reason for this is so that when we invoke `someExpr.addressOfProd(top.location)` the resulting tree is built using the location of the address-of operator, not of the original expression.
When we rewrite this code to use origins, we can remove the `Location` argument, meaning the type will be just `Expr ::= ` and the invocation will be just `someExpr.addressOfProd()`.
Since the call site will pick up origins information from the node it is a rule on (`top`) it will flow correctly into the lambda invocation.
For example if we had a production with a rule like `top.addressOfProd = (\loc::Location -> someOtherProd(location=loc))` can can change it to a 0-argument lambda `top.addressOfProd = (\ -> someOtherProd())`.


## Origins in Silver

Nonterminals in silver are either `tracked` (which is a qualifier like `closed`) or untracked.
Tracked nonterminals have origin information attached to them at construction (and if using redexes, when they are 'moved' during a transformation.)
Untracked nonterminals don't have origin info.
There are performance implications for keeping track of origins info (both in constructing the origins info representations, doing the bookkeeping for them, and the memory overhead of pinning the things objects originate from) so it is in one's best interest to avoid tracking nonterminals that won't have their origins information asked for.

In Silver the origin of a node is represented as an instance of the nonterminal type `OriginInfo`, which has different productions for different sets of origin information a node can have.
To access the `OriginInfo` for a node one calls `getOriginInfo` (in `core`) which returns a `Maybe<OriginInfo>`.
Code using origins should handle the case that this returns `nothing()`.
The links to origins and redexes in `OriginInfo` nodes are implemented as unconstrained generics, so to handle them it is necessary to use reflection.
If you want to checked-cast a link to a known type you can use the `reify(anyAST(link))` pattern to do so without unnecessarily constructing a reflective tree.
This can fail either if a terminal is not marked as `tracked`, because the program was built with `--no-origins`, or because of a stale module not attaching origins (see later note on [build issues](#build-issues).)

In Silver notes are values of the type `OriginNote`.
A builtin `dbgNote ::= String` production is available for quick debugging notes, but for other use users are encouraged to add their own productions.
Notes are effective over domains of code and will be picked up in the origins info for any values constructed (in their origin notes) or moved (in their redex notes) in that code (and in functions it calls, etc.)
Notes can be made effective over an entire body of statements by adding a production statement of the form `attachNote dbgNote("foo");` or made effective over only part of an expression by writing `attachNote dbgNote on {expr}`.
The former is useful to describer a general operation happening, and the latter for noting a exceptional case (e.g. a nontrivial optimization taking place sometimes.)

In Silver the 'er' flag on origins is known as 'newlyConstructed' or 'isInteresting'.
The definition used to determine if a constructed node is interesting is that it _is_ considered interesting unless all of the following are true:
 - It's in the 'root position' of a rule, i.e. `bar()` is in 'root position' in `top.xform = bar()` but not in `top.xform = foo(bar())`.
 - It's the same production as the production on which the rule is defined, i.e. `...production bar... {top.xform=bar(...);}` but not `...production bar... {top.xform=foo(...);}`
 - It's not constructed in a function (including lambdas)

The purpose of this flag is to indicate if the transformation is 'trivial' or not.
If the flag is not set you can know that the transformation didn't change the 'shape' of the tree at the level of the node on which it's set.

We can follow the origin link of a node to the node it logically originates from.
Once we can do this, we can get the origin information of that node, and follow the path of origins back.
This is the 'origins chain' or 'origins trace'.
Eventually we will reach a node that has an origin describing some source other than a rule on a node (instead e.g. that it was parsed from input to Copper) or a node without origins (because it is not `tracked`.)
One can call `getOriginInfoChain` to get a list of `OriginInfo` objects representing the links between objects in this chain.
If the chain of origins is `foo ---originates-from-node---> bar ---originates-from-node---> baz ---originates-from-source-location---> file:12:30` we can call `getOriginInfoChain(foo)` to get `[originOriginInfo(..., bar, ...), originOriginInfo(..., baz, ...), parsedOriginInfo(loc('file', 12, 30, ...))]`.
One very practical application is that we can get this chain of origin information, find the last one, and find the source location the object at the end of the chain originates from.
This is what we currently do with the `location` annotation in many places.
This common use case is wrapped up with the helper functions `getUrOrigin(...)` which returns the last item in the origin chain (if there is one) and `getParsedOriginLocation(...)` which gets the last item in the origin chain and - if it is a `parsedOriginInfo` indicating it was constructed in Copper - yields the `Location`.
In situations where the logical textual origin of a node is not the textual origin of the node on which the rule which constructed it was defined one can attach a `logicalLocationNote(loc)` to it which will be used by `getParsedOriginLocation` instead.

The origin information (the LHS, notes, interesting-ness or other source information) is tracked by the runtime and generated code and flows throughout running silver code.
When a function or lambda is called the origin information from it's call site is used for values constructed in it.
This means that while it's not possible to ask for the origin of a function instantiation proper (while this does make sense from the function-as-a-node-with-a-single-attribute-called-return PoV, it's not the silver model) it is possible to get the same information by constructing a value and asking for it's origin.
There is a production in the origins runtime support specifically called for this called `ambientOrigin()` (of type `ambientOriginNT`).
For example if you have a helper function like `checkArgs :: [Message] ::= [Expr] [Expr] Location` and call it from a `binOp` production using the production's location as an argument, you can instead omit that argument and use `errFromOrigin(ambientOrigin(), ...)` to produce the error `Message`.


### Origin Types in Silver

In Silver the notion from the paper is extended and generalized to provide origins that can also encode different ways of producing nodes that are not part of the simple attribute grammar described in the paper.
Each different set of possible origin info is described by a production of `OriginInfo`.
Each production has a `OriginInfoType` member that describes where and how the node was created and contains a list of `OriginNotes` attached from code that influenced the creation of the node.
 - `originOriginInfo(typ, origin, originNotes, newlyConstructed)` contains a link to the node that this node originates from (`origin`), notes (`originNotes`) and the interesting flag (`newlyConstructed`). The possible values for `typ` (`OriginInfoType`s) are:
   - `setAtConstructionOIT()` indicating the node was constructed normally. The origin link is to the node on which the rule that constructed this node occurred.
   - `setAtNewOIT()` indicating the node was constructed in a call to `new` to undecorate something. The origin link is to the node that was `new`ed.
   - `setAtForwardingOIT()` indicating the node was forwarded to. The origin link is to a copy of this node from which you can find out where it was constructed.
   - `setFromReflectionOIT()` indicating the node is an `AST` created from `reflect`. The origin link is to the node that was reflected on.
   - `setFromReificationOIT()` indicating the node was created from an `AST` by `reify`. The origin link is to the reflective representation the node was reified from.
 - `originAndRedexOriginInfo(typ, origin, originNotes, redex, redexNotes, newlyConstructed)` contains a link to the node that this node originates from (`origin`), notes on that link (`originNotes`), a link to the node that is the redex of a transformation that moved this node (`redex`), notes on that link (`redexNotes`), and the interesting flag (`newlyConstructed`). The only value for `typ` this can have is `setAtAccessOIT()`.
 - `parsedOriginInfo(typ, source, notes)` contains a source location (`source`) of the text that caused Copper to emit this node from parsing (appears only on `concrete` productions.) The only value for `typ` this can have is `setFromParserOIT()`. `notes` is currently unused.
 - `otherOriginInfo(typ, source, notes)` contains a string describing whatever circumstance produced this node (`source`) and maybe `notes`. This is a catchall for things that do not have a logical origin either due to implementation details or concepts not present in the paper. Possible values for `typ` are:
   - `setFromParserActionOIT()` indicating the node was constructed in a parser action block.
   - `setFromFFIOIT()` indicating the node was constructed in a context where origins information had been lost as a result of passing through a FFI boundary that does not preserve it (e.g. when something is constructed in a comparison function invoked from the java runtime Silver value comparator shim)
   - `setFromEntryOIT()` indicating the node was constructed in entry function
   - `setInGlobalOIT()` indicating the node is a constant


### Implementation, runtime, and FFI

`tracked`ness is implemented in the silver compiler as part of the `nonterminalType`.
Initially it was held in the `ntDcl` for that `nonterminalType` (which is where the `closed` qualifier goes.)
That seems like it would be preferable, but the way `import` works means that that `ntDcl` is not always available.
In the situation that a production is imported (and used) without the nonterminal being imported (e.g. `import silver:langutil only err`) we can have knowledge of the production without the nonterminal to which it belongs.
Since whenever we construct or manipulate a nonterminal we need to know it's `tracked`ness this meant that the `tracked`ness had to go in the `nonterminalType`.

`tracked` nonterminals extend `TrackedNode` which in turn extend `Node`.
Non`tracked` nonterminals still directly extend `Node`.
`Node` should be used to represent an untracked node or a node of unknown trackedness.
The only case where it's possible to have to attach OI to a unknown-trackedness node is attaching a redex, which is done with a runtime `instanceof` check.
The `OriginInfo` for a node is treated as a hidden child and evaluated strictly.
It is held in the `NOriginInfo origin` field of `TrackedNode`.
It shouldn't be `null`, but it's possible if FFI produced a bad origin or if there is a bug.
These `OriginInfo`s are normal silver production instances.
They need to be un`tracked` to make it actually possible to construct them without infinite regress.
All productions of `OriginInfoType` are instantiated at startup as singletons and held in `OriginsUtil`.
The stdlib accessors for origins are Java FFI functions that call out to helpers on `OriginsUtil`.

During runtime the origin context exists as a `common.OriginContext` object.
These are analogous to all the stuff added to the left side of the turnstile in the evaluation semantics for the AG-with-origins in the paper.
These objects are immutable (since they get captured into closures and `DecoratedNode`s).
They hold information similar-to but different-than `OriginInfo` nonterminal instances, and generate `OriginInfo` nonterminal instances.
They are handed around as an additional parameter to function calls and baked into `Lazy`s/`Thunk`s as captured variables.
They are tacked onto `DecoratedNode`s as something of an ugly hack.
`FunctionNode`s extend `Node` not `TrackedNode`, since they never escape the invocation.
They are constructed and decorated with `TopNode` in order to provide an environment for evaluation of locals though, so when they are decorated the `DecoratedNode` gets the `originCtx` passed into the function invocation.

Depending on the context of the code being emitted we try to avoid passing them around/constructing them when not needed.
In expressions in rules that are defined in a block on a production we always know the left hand side and can statically determine the notes that apply, so we construct the `OriginContext` only at the sites where we need to produce an `OriginInfo`.
In expressions that occur in functions (including lambdas) we need to take the `OriginContext` as an additional parameter to `.invoke` because the context depends on the caller.
Lastly for expressions occurring in weird spots (e.g. parser actions, globals) we need to use a bogus `OriginContext`.
`translation:java:core/Origins.sv` contains the logic for what to do each of these cases.
Each `BlockContext` gains a `originsContextSource :: ContextOriginInfoSource` which is one of:
 - `useContextLhsAndRules()` indicating that the LHS and rules can be derives statically (i.e. this expression is only ever evaluated on a `DecoratedNode` where the undecoration is the LHS and the rules can be determined statically from the `originRules()` attribute on the `Expr`.)
 - `useRuntimePassedInfo` indicating the context should be retrieved from the runtime-passed java value stored in `originCtx` and swizzled through thunks and function calls etc
 - `useBogusInfo(name)` indicating the context is garbage (parser action or global) and the `name` indicates which of the special `variety`s of `OriginInfo` should be used (see below)

When they do produce `OriginInfo` nonterminals they only produce `originOriginInfo` or `otherOriginInfo`s. 
`originAndRedexOriginInfo`s are attached to nodes that have been moved *later* by expanding an existing `originOriginInfo` using the origins context at the time of tree motion to set the redex and redex notes without modifying the origin and origin notes.
They have a `variety` field which is one of:
 - `NORMAL`, indicating that the field `lhs` holds the context node and `notes` holds the nodes attached to the current context. This corresponds to `originOriginInfo(setAtConstructionOIT(), lhs, notes, isInteresting)`
 - `MAINFUNCTION` corresponding to `otherOriginInfo(setFromEntryOIT(), ...)`
 - `FFI` corresponding to `otherOriginInfo(setFromFFIOIT(), ...)`
 - `PARSERACTION` corresponding to `otherOriginInfo(setFromParserActionOIT(), ...)`
 - `GLOBAL` corresponding to `otherOriginInfo(setInGlobalOIT(), ...)`
The `lhs` and `notes` fields are meaningless unless `variety == NORMAL`.
All `variety`s except `NORMAL` are instantiated as singletons: `OriginContext.MAINFUNCTION_CONTEXT` etc.
When a node is newly constructed the context's `makeNewConstructionOrigin(bool)` function is called returning the appropriate `OriginInfo` object.

When redexes are attached (when `expr.attr` is evaluated the result gets a redex pointing to the context of the access) it is by calling `OriginContext.attrAccessCopy(TrackedNode)` (if the value is a known-to-be-tracked nonterminal) or `OriginContext.attrAccessCopyPoly(Object)` (if the value is of a parametric type and has been monomorphized to `Object` - this is a no-op if it is not actually a `TrackedNode` at runtime.)
This copies the node (using it's `.copy(newRedex, newRules)`) and returns the new copy that has a `originAndRedexOriginInfo` that got it's origin and origin notes from the old origin and it's redex and redex notes from the passed context.
Similarly when a node is produced by `new` the result of `.undecorate()` has `.duplicate` called on it which performs a deep copy where the new nodes have `originOriginInfo(setAtNewOIT(), ...)` pointing back to the node they were copied form.
Lastly when a node is used as a forward `.duplicateForForwarding` is called on it to mark that, returning a shallow copy with a `originOriginInfo(setAtForwardingOIT(), ...)` pointing to the node with the 'real' origin info (this is kind of an ugly hack, but was preferable to introducing a new and unique pair of `origin(AndRedex)AndForward` OIs.)
`.duplicate`, `.duplicateForForwarding` and `.copy` are specialized per-nonterminal.

When control flow passes into java-land and then back into silver (i.e. when the raw treemap code invokes a java operation that calls back into silver using a `SilverComparator`) a context is needed.
Since there isn't a (good) way to indicate to the comparator where in silver it was called (we could attach the context when it was constructed, but this is the creation site of the tree not the invocation site of the comparison) it just gets a garbage context: `OriginContext.FFI_CONTEXT` which turns into a `otherOriginInfo(setFromFFIOIT(), ...)` if it constructs nodes.

The last special case is the main function, which is called with `OriginContext.MAINFUNCTION_CONTEXT` by the runtime entry code.


### Limitations and contracts

 - Code shouldn't assume that the `origin` is correctly set even on `tracked` nonterminals. It might not be in the case of bugs (although there aren't any currently known) or incorrect native code (either in `foreign` blocks or in a native extension (we have those, right?))
 - `OriginInfo` can't be `tracked` (otherwise it's impossible to construct them without infinite regress)
 - `OriginInfo` productions are "sacred" (name and shape are compiler-assumed) and can't be changed without compiler and runtime support
 - `OriginInfoType` productions are "sacred" (name and shape are compiler-assumed) and can't be changed without compiler and runtime support
 - `OriginInfoType` productions are instantiated as singletons inside the runtime and don't have OI (same issue as above)
 - Some types are directly mentioned in the silver compiler as `nonterminalType`s and need to have a compiler-decided `tracked`ness. This `tracked`ness is alterable but requires compiler changes. Such types (and their current `tracked`ness) are as follows:
   - `core:Location` - no
   - `core:OriginNote` - no (see above)
   - `core:Either` - no
   - `core:reflect:*` - yes
   - `silver:rewrite:Strategy` - no
   - `core:Maybe` - no
   - `core:ParseResult` - no
   - `silver:langutil:Message` - yes
   - `ide:IdeProperty` - no
   - `core:IOVal` - no
 - Foreign types can't be `tracked`, and some FFI interfaces don't preserve origins information (see [above](#imlementation-runtime-and-ffi))

 Types that CANNOT be tracked (currently just `core:OriginInfo`, `core:OriginInfoType`, and `core:OriginNote`) are listed in `translation/java/core/origins.sv:getSpecialCaseNoOrigins` and will never be treated as tracked.

 When `--no-origins` is used it does not alter whether or not the type is considered tracked in the compiler, it just disables codegen for origins. For types need to be constructed from runtime code you should construct them using the `rtConstruct` static method that forwards to the normal constructor with or without the origin argument depending on if `--no-origins` is used.


## Example

The following silver code approximates the example attribute grammar used in the Origin Tracking in Attribute Grammars paper linked above:

```
tracked nonterminal Expr;
synthesized attribute expd :: Expr occurs on Expr;
synthesized attribute simp :: Expr occurs on Expr;

abstract production const
top::Expr ::= i::Integer
{
  top.expd = const(i);
  top.simp = const(i);
}

abstract production add
top::Expr ::= l::Expr r::Expr
{
  top.expd = add(l.expd, r.expd);
  top.simp = add(l.simp, r.simp);
}

abstract production sub
top::Expr ::= l::Expr r::Expr
{
  top.expd = sub(l.expd, r.expd);
  top.simp = sub(l.simp, r.simp);
}

abstract production mul
top::Expr ::= l::Expr r::Expr
{
  top.expd = mul(l.expd, r.expd);
  top.simp = case l.simp of
             | const(1) -> attachNote dbgNote("Multiplicative identity simplification")
                           on {r.simp}
             | _ -> mul(l.simp, r.simp)
             end;
}

abstract production negate
top::Expr ::= a::Expr
{
  attachNote dbgNote("Expanding negation to subtraction from zero");
  top.expd = sub(const(0), a.expd);
  top.simp = error("Requested negate.simp");
}
```

Computing the transformation of a tree is accomplished by demanding `expd` on the tree and then `simp` on the result (for a tree `x` the transformation is `x.expd.simp`.)
The following diagrams visualize the origins connections between the resulting value (`x.expd.simp`) and the original value (`x`.)
The nodes in green are parts of the output value (the value itself has a bold border) and the nodes in blue are part of the input value (similarly.)
Dashed lines represent origin links and dotted lines represent redex links.
Wide dashed lines represent contractum domains (essentially what is the most immediate parent on which a location-changing transformation occurred... read the paper for a formal description.)
Diamond-shaped nodes indicate the interesting/'er' flag is set on that node's origin info.

In this specific example grammar the green nodes are then `x.expd.simp`, the white nodes are `x.expd` and the blue nodes are `x`.
Due to implementation details the input tree is marked interesting (it is interesting if you consider that it's a nontrivial translation from a different CST type) but you can ignore that for the purpose of the explanation.

The tree `negate(const(1))` expands to `sub(const(0), const(1))` and then simplifies (a no-op) to `sub(const(0), const(1))`:

![](/silver/concepts/negate_1.svg)

We can see that the simplified copy of `const(1)` originates from the expanded copy which originates from the original copy.
Since the transformations for `const` are no-ops (the shape of the rule `top.expd = const(i)` trivially mirrors the shape of the production `production const top::Expr ::= i::Integer`) the expanded and simplified nodes are ovals, indicating that the rule that produced them was not 'interesting'.
We can also see that generally since the simplification for this tree are all 'boring' simplified nodes originate from the expanded nodes and are not marked interesting (are ovals).
More interesting is the step that converted the `negate` to a `sub`.
We can see that the `sub` node and the `const(0)` node are both marked as originating from the `negate` node - this is because they were produced by expressions in a rule that was evaluated on that node.
We can also see the `dbgNote` attached to the origin info for the `const(0)` and `sub` nodes (in the `originNotes` field).
The note does not appear on the origin of the `const(1)` because it was not manipulated in a nontrivial way in the rule for `expd` on `negate`.

The tree `mul(const(1), const(2))` expands to `mul(const(1), const(2))` and then simplifies to `const(2)`:

![](/silver/concepts/mul_1_2.svg)

We can see that since the expansion step is a no-op the nodes are marked uninteresting and originate simply.
The interesting change is the simplification step. The `mul(const(1), const(2))` reduces to just `const(2)` - the `mul` and `const(1)` nodes disappear and the `const(2)` is in the resulting tree in the location that the `mul` originally was.
We can see that the resulting `const(2)` originates as expected from the `const(2)` in the expanded tree, but has an additional dotted line to the `mul` node for it's redex.
This means that the `simp` rule on the `mul` node catalyzed the motion of the `const(2)` from it's previous position in the tree to it's new position where the `mul` node was.
We can also see that the redex edge for the `const(2)` node in the output has the `dbgNote` from the simplification case of the match attached to it (as a member of the `redexNotes` - but not `originNotes` - list.)
This is because the node was effective over the expression that moved the `const(2)` to it's resulting position (`r.simp` in the `simp` rule for `mul`) but not the expression that constructed it (`top.simp = const(i)` in `const`.)



## Compiler Flags

There are a few compiler flags that can be passed to `silver` to control origins tracking behavior:
 - `--force-origins` causes the compiler to treat every nonterminal as if it was marked `tracked`. This is very useful for playing around with origins in an existing codebase and for figuring out what you need to track (build with `--force-origins`; look at origins trace; track everything included.) This can be pretty (+15% to +30% vs no origins) slow.
 - `--no-origins` does the opposite, causing the compiler to completely disable origins, including the context swizzling machinery in generated code. This is recommended if you aren't going to use them since it will remove almost all overhead in generated code.
 - `--no-redex` causes the code to not track redexes. Redexes are a neat feature and a cool part of the theory but not necessary if all you want to do is avoid having to use a `location` annotation for error messages. This can be somewhat (5%) faster than leaving redexes on if you aren't using them.
 - `--tracing-origins` causes the code to attach notes indicating the control flow path that lead to constructing each node to it's origins. This can be a neat debugging feature, but is also quite slow.

Just changing compiler flags that affect the translation will not cause anything to be re-translated if none of the grammar source files have been touched.
Thus you should re-build with `--clean` when changing any of the above compiler flags.
