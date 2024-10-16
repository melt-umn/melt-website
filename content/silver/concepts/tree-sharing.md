---
title: Tree sharing
weight: 300
---

{{< toc >}}

Tree sharing permits the same [decorated tree](/silver/concepts/decorated-vs-undecorated) to be used in multiple places.  This permits inherited attributes to be supplied in one production and be used in another, without causing re-computation of attributes, or needing to specify the same equation more than once.

## Direct sharing
Consider a for loop extension in a simple imperative language:
```
production forLoop
top::Stmt ::= iVar::Name lower::Expr upper::Expr body::Stmt
{
  top.errors = 
    checkInt(lower.type, "loop lower bound") ++
    checkInt(upper.type, "loop upper bound") ++
    lower.errors ++ upper.errors ++ body.errors;
  lower.env = top.env;
  upper.env = top.env;
  body.env  = addEnv(iVar, intType(), top.env);
  local upperVar::Name = freshName(top.env);
  forwards to block(seq(
    decl(iVar, intType(), ^lower),
    seq(decl(upperVar, intType(), ^upper),
      while(intLt(var(iVar), var(upperVar)),
        seq(^body, assign(iVar,
          intAdd(var(iVar), intConst(1))))))));
}
```
This for loop forwards to an equivalent while loop, but also wants to provide more precise error messages when the children have the wrong type.  To compute `type` and `errors`, we need to supply `env` to the children, prior to forwarding.  The children are un-decorated, and supplied with `env` again in the forward tree.  

![The tree produced by a nested for loop, without sharing](/silver/concepts/forLoop_not_shared.png)

This potentially causes attributes to be computed twice on the `lower`, `upper` and `body` trees. In some situations, this sort of issue can yield a blowup in runtime that is exponential in the level of nesting.  We also would like to avoid writing these `env` equations, as they mirror the attribute values that will be supplied in the forward tree.

The solution is to share a single decorated tree between each child of the `forLoop` production, and the forward tree. 

![The tree produced by a nested for loop, with sharing](/silver/concepts/forLoop_shared.png)

This can be achieved by replacing calls to `new` with the _tree sharing operator_ `@`:
```
production forLoop
top::Stmt ::= iVar::Name lower::Expr upper::Expr body::Stmt
{
  top.errors = 
    checkInt(lower.type, "loop lower bound") ++
    checkInt(upper.type, "loop upper bound") ++
    lower.errors ++ upper.errors ++ body.errors;
  local upperVar::Name = freshName(top.env);
  forwards to block(seq(
    decl(iVar, intType(), @lower),
    seq(decl(upperVar, intType(), @upper),
      while(intLt(var(iVar), var(upperVar)),
        seq(@body, assign(iVar,
          intAdd(var(iVar), intConst(1))))))));
}
```

This operator wraps a tree of type `Decorated nt with {}` to give an undecorated value of type `nt`.  When this result is subsequently decorated in some other position, the original tree is returned.  Any attributes explicitly supplied to the original tree take precedence over the places where the attribute was originally supplied.

A small extension to the usual demand-driven attribute evaluation semantics is needed, as additional attributes are supplied during evaluation.  When a shared tree is initially decorated, it is also supplied with a lazy reference to its sharing site; if a missing inherited equation is encountered, then the sharing site is demanded to force any additional remote equations to be supplied.

### Modular well-definedness

#### Inherited completeness
Since the children of the `forLoop` production appear in fixed places in the forward tree, the [modular well-definedness analysis](/silver/concepts/modular-well-definedness) can determine that their `env` equations will be supplied by the forward tree, and thus these equations can be omitted.  The dependencies introduced by the remote productions enclosing the shared children in the forward are _projected_ by the analysis, to determine what dependencies ultimately exist on inherited attributes supplied to the forward tree.

#### Uniqueness
An important concern for the analysis is to ensure that no decoration site is shared more than once - this may result in multiple equations being supplied for the same inherited attribute; which equation is supplied first may depend on the order of evaluation, and may result in confusing non-deterministic behavior.  To enforce this, the analysis imposes several restrictions on how sharing can be used.  First, only child and local/production attribute trees can be shared, not references of an unknown origin.  Other sorts of trees, like the left side of the production or a pattern variable, may have equations supplied by other productions.  Sharing anonymously decorated trees (`decorate e with {env = ...;}`) is not currently supported.

Any use of sharing must also correspond to a known decoration site - that is, a forward or local equation, or an argument to a production application that is itself in a known decoration site.  Pattern match rules and then/else clauses of conditional expressions in known decoration sites are also acceptable.  However, a shared tree cannot be e.g. passed to an arbitrary function or placed in the environment, as we cannot track how it might subsequently be decorated and used.

Finally, there can only be at most one (non-mutually exclusive) sharing site for any shared decoration site.  For example, this would be an error:
```
production ifThen
top::Stmt ::= c::Expr body::Stmt
{
  local trans::Stmt = ifThenElse(@c, @body, nullStmt());
  forwards to
    case c of
    | trueLit() -> @body
    | _ -> @trans
    end;
}
```
However, this would be acceptable, since different pattern rules are mutually exclusive:
```
production ifThen
top::Stmt ::= c::Expr body::Stmt
{
  forwards to
    case c of
    | trueLit() -> @body
    | _ -> ifThenElse(@c, @body, nullStmt())
    end;
}
```

To avoid duplicate sharing in independent extensions, any sharing site must also be [exported by](/silver/concepts/modular-well-definedness) the decoration site.

There also needs to be some consideration in the semantics of undecorating a tree with shared children.  For example consider if an extension production wrote an aspect production
```
aspect production while
top::Stmt ::= c::Expr b::Stmt
{
  local b2::Stmt = ^b;
  b2.env = [];
  top.extThing = b2.extThing;
}

```
Then in the forward of `forLoop` tree, the `while` loop body would potentially be decorated twice, causing the the shared `body` to be decorated again. To prevent this, undecorating a tree by calling `new` must perform a deep copy, if the tree contains a shared subtree.

#### Hidden transitive dependencies
There is also a a more subtle issue possible when an inherited equation is defined for a tree that is also shared.  For example, consider the host language while loop production:
```
flowtype errors {env} on Stmt, Expr;

production while
top::Stmt ::= c::Expr body::Stmt
{
  c.env = top.env;
  body.env = top.env;
  top.errors = c.errors ++ body.errors ++ checkBool(c.type, "loop condition");
}
```
Here the equation for `body.env` only depends on `top.env`.  But now consider if an extension production `foo` forwards to this loop with tree sharing, but overrides the `env` equation with one that depends on some other attribute `extraEnv`:
```
production foo
top::Stmt ::= s::Stmt
{
  s.env = top.extraEnv ++ top.env;
  forwards to while(..., @s);
}
```
When demanding `errors` on a `foo` tree, it will be computed via forwarding to `errors` in the `while` production, which in turn depends on `body.env`.  However the `env` equation in `foo` takes precedence over the one in `while`, resulting in a dependency on `extraEnv` - which exceeds the flow type for `errors`!

To prevent this sort of hidden transitive dependency from causing problems, the analysis requires that any inherited override equation on a shared tree cannot exceed the projected dependencies of the attribute on the tree in the remote production.

### Forward production attributes

A common pattern is to use [error productions](/silver/concepts/interference/#rule-2-use-error-productions) to avoid writing interfering synthesized override equations on forwarding productions.  For example with the for loop extension, we might want to write
```
production forLoop
top::Stmt ::= iVar::Name lower::Expr upper::Expr body::Stmt
{
  local errs::[Message] = 
    checkInt(lower.type, "loop lower bound") ++
    checkInt(upper.type, "loop upper bound") ++
    lower.errors ++ upper.errors ++ body.errors;
  local upperVar::Name = freshName(top.env);
  forwards to
    if !null(errs) then errorStmt(errs)
    else block(seq(
      decl(iVar, intType(), @lower),
      seq(decl(upperVar, intType(), @upper),
        while(intLt(var(iVar), var(upperVar)),
          seq(@body, assign(iVar,
            intAdd(var(iVar), intConst(1))))))));
}
```
However, there is now a problem as the children `lower`, `upper` and `body` are only conditionally being supplied with `env` through forwarding, meaning these equations are now reported as missing.  What we want is to unconditionally decorate the forward tree with inherited attributes, but then only conditionally actually forward to it.  This can be done using a _forward production attribute_ to decorate the tree with implicit copy equations for all inherited attributes:
```
production forLoop
top::Stmt ::= iVar::Name lower::Expr upper::Expr body::Stmt
{
  local errs::[Message] = 
    checkInt(lower.type, "loop lower bound") ++
    checkInt(upper.type, "loop upper bound") ++
    lower.errors ++ upper.errors ++ body.errors;
  local upperVar::Name = freshName(top.env);
  forward fwrd =
    block(seq(
      decl(iVar, intType(), @lower),
      seq(decl(upperVar, intType(), @upper),
        while(intLt(var(iVar), var(upperVar)),
          seq(@body, assign(iVar,
            intAdd(var(iVar), intConst(1))))))));
  forwards to
    if !null(errs) then errorStmt(errs)
    else @fwrd;
}
```

The hidden transitive dependencies issue can also happen when sharing a forward production attribute, as this essentially equates to defining override equations for all attributes:
```
production bar
top::Expr ::= e::Expr
{
  forward f = @e;
  forwards to baz(@e);
}
production baz
top::Expr ::= e::Expr
{
  e.env = [];
  ...
}
```
Here the implicit copy equation for `e.env` in `bar` exceeds the dependencies of the equation in `baz`, by depending on `top.env`.  Note that we don't even know about all inherited equations on `e` introduced by independent extensions, so it isn't even possible to check that forwarding to `baz(@e)` is safe.  Thus, the analysis forbids sharing a forward production attribute anywhere other than directly in a forward/forward production attribute equation.

### Translation attributes

Sometimes extensions introduce their own nonterminals in defining an embedded domain-specific language that is translated into host-language syntax.  When extension productions contain host-language trees, we would like to share these trees in the translation that is built across multiple productions; however sharing is not permitted in ordinary [higher-order attribute](/silver/concepts/decorated-vs-undecorated/#higher-order-undecorated) equations.  This is instead possible using _translation attributes_.

Consider a simple "condition tables" extension that provides more convenient notation for Boolean expressions;
this is a simplified version of the [ableC-condition-tables extension](https://github.com/melt-umn/ableC-condition-tables).
```
var res : bool = table { b1 && b3 : T F
                         ~ b2     : T *
                         b2 || b3 : F T };
```
A condition table expression is true if the true/false/don't care flags in any column match the truth values of the row expressions.  Thus a condition table expression translates into a series of let bindings for these expressions, with a translation of the table rows as the body:
```
var res : bool =
  let _v0 : bool = b1 && b3 in
  let _v1 : bool = ~b2 in
  let _v2 : bool = b2 || b3 in
    (_v0 && _v1 && ~_v2) || (~_v0 && _v2);
```

Table rows are represented by the `TRows` nonterminal, which contains the row expressions.  The conditions are passed down the tree by the `conds` attribute, which are then wrapped in the needed let bindings for the row expressions by the translation attribute `trans`.
```
production condTable
top::Expr ::= rows::TRows
{
  top.errors = rows.errors;
  rows.conds = [];
  forwards to @rows.trans;
}

nonterminal TRows with errors, conds, trans;
inherited attribute conds::[Expr];
translation attribute trans::Expr;

production consRow
top::TRows ::= e::Expr tf::TruthFlags rest::TRows
{
  top.errors = e.errors ++ tf.errors ++ rest.errors
    ++ checkBoolean(e.type, "row expression");

  local eVar::Name = freshName(top.trans.env);
  tf.rowExpr = var(eVar);
  rest.conds =
    if null(top.conds) then tf.rowConds
    else zipWith(andOp, top.conds, tf.rowConds);
  top.trans = let_(eVar, @e, @rest.trans);
}
production nilRow
top::TRows ::=
{
  top.errors = [];
  top.trans = foldr1(orOp, top.conds);
}

nonterminal TruthFlags with errors, rowConds;
inherited attribute rowExpr::Expr;
synthesized attribute rowConds::[Expr];

...
```

Translation attributes are implicitly decorated as decoration sites, like a child or local/production attribute.  An instance of a translation attribute on a child or local (e.g. `rest.trans`) can be shared, and sharing can be used in a translation attribute equation.

![The tree produced by a condition table](/silver/concepts/cond_table.png)

If someone supplies a row expression of the wrong type, we would like to report these error messages directly, rather than getting the errors from the forward about a let binding having the wrong type.  To achieve this, the expressions are decorated with `env`, which flows down through the forward tree.  `errors` and `trans` are computed on the extension `TRows` tree, while any other host or extension attributes (such as `asm` computing an assembly translation) happen on the forward translation tree.

#### Modular well-definedness

Inherited attributes on translation attributes are treated more or less like regular inherited attributes in the flow analysis, and can appear in flow types.  For example, the flow type of `errors` on `TRows` is `{trans.env}`.  Only a single level of translation attributes is supported by the flow analysis, so `trans.foo.env` is not legal in a flow type. One can also write an override equation like `rows.trans.env = top.env;`, however this is not frequently useful in practice.  

To ensure uniqueness of sharing sites, an instance of a translation attribute on a child or local can only be shared in a grammar exported by the child/local, or the occurs-on declaration of the translation attribute.  Additionally for the translation attribute instance to be shared, the child/local cannot be shared directly.

The hidden transitive dependencies check for override equations on shared translation attribute instances is twofold: If there is an explicit inherited equation for `foo.trans.env`, then
* If `foo` is shared, the equation's dependencies cannot exceed the dependencies of `trans.env` on its sharing site.
* If `foo.trans` is shared, the equation's dependencies cannot exceed the dependencies of `env` on its sharing site.

## Dispatch sharing

The direct form of tree sharing using the `@` operator, in which inherited attributes are supplied principally by the forwarded-to production, only works when the productions supplying these inherited attributes are fixed. If determining a portion of the forward tree requires computing some analysis on shared children, which requires inherited attributes to be supplied, this poses a problem as supplying these attributes through the forward tree would create a cycle.  A common scenario of this is an overloaded operator, which forwards to different implementation productions depending on the type of its operand.
```
production negOp
top::Expr ::= e::Expr
{
  e.env = top.env;
  forwards to
    case e.type of
    | intType() -> negInt(^e)
    | boolType() -> negBool(^e)
    | t -> errorExpr("Invalid operand to ~: " ++ t.typepp)
    end;
}
production negInt
top::Expr ::= e::Expr
{
  e.env = top.env;
  top.type = intType();
  top.errors = e.errors ++ checkInt(e.type, "~ operand");
}
production negBool
top::Expr ::= e::Expr
{
  e.env = top.env;
  top.type = boolType();
  top.errors = e.errors ++ checkBool(e.type, "~ operand");
}
```
There are a few issues here:
1. The operand to `negOp` is decorated twice - once as a child to `negOp`, and once in the forward.  Since demanding `type` on a `negOp` tree will cause `type` to be demanded from both versions of `e`, this will lead to a re-computation blowup that is exponential in the depth of nesting.
2. The equation for `env` is specified more than once - both in the dispatching `negOp` production, and in the implementation productions.  The equation is trivial in this example, but in practice the equations might be more numerous and complicated.
3. The implementation productions need to repeat the type error check done by `negOp`.  Nothing prevents an extension production from e.g. forwarding directly to `negInt`, bypassing the check in `negOp`.  Either the check needs to be repeated in `negInt`, or an extra semantic contract with extension developers is needed, that they should only forward directly to `negOp`.

An unsatisfactory solution is to use the `@` operator instead of `new` in `negOp`:
```
production negOp
top::Expr ::= e::Expr
{
  e.env = top.env;
  forwards to
    case e.type of
    | intType() -> negInt(@e)
    | boolType() -> negBool(@e)
    | t -> errorExpr("Invalid operand to ~: " ++ t.typepp)
    end;
}
```
This addresses issue 1, but not 2 or 3.  If the `env` override equation in `negOp` doesn't match the equation in the forward tree, this can silently cause unexpected behavior.

### The let binding approach
In some situations, a solution is to bind the operand in a `let` expression, and only use a reference to the bound variable in the implementation production:
```
production negOp
top::Expr ::= e::Expr
{
  local n::Name = freshVar(top.env);
  forwards to let_(
    n, @e,
    case e.type of
    | intType() -> negInt(var(n))
    | boolType() -> negBool(var(n))
    | t -> errorExpr("Invalid operand to ~: " ++ t.typepp)
    end);
}
```
This avoids issues 1 and 2, as `e` is only decorated once, and `negOp` doesn't need to write any explicit inherited equations. However, `negInt` and `negBool` now no longer have direct access to the operand expression tree, restricting what sorts of analyses extensions can perform.  This pattern also is not more broadly applicable for dispatching outside of expressions with some notion of let-binding.

### Sharing through production signatures
Another solution to issue 2 is to supply `env` in `negOp` prior to forwarding, by annotating the operands of implementation productions with `@` to indicate that they have been previously decorated:
```
production negOp
top::Expr ::= e::Expr
{
  e.env = top.env;
  forwards to
    case e.type of
    | intType() -> negInt(e)
    | boolType() -> negBool(e)
    | t -> errorExpr("Invalid operand to ~: " ++ t.typepp)
    end;
}
production negInt
top::Expr ::= @e::Expr
{
  top.type = intType();
  top.errors = e.errors;
}
production negBool
top::Expr ::= @e::Expr
{
  top.type = boolType();
  top.errors = e.errors;
}
```
The type of `negInt` here is now `(Expr ::= Decorated Expr with {})`.  An application of an implementation production with shared children (like `negInt`) may only appear in the root position of a forward (or forward production attribute) equation.  Applications of these productions also must be exported the definition of the production - i.e. the implementation production must know about all the productions that forward to it.  This means that `negInt` can count on `e` having the correct type, as it will only be constructed through the forward of `negOp` where this check is performed.

With these restrictions, the modular well-definedness analysis can check for the presence of any needed inherited equation in an implementation production - either there must be a direct equation in the production, or all productions forwarding to the implementation production must supply an equation.  The dependencies of inherited equations supplied prior to forwarding are also projected into all implementation productions - for example in `negInt`, `e.errors` depends on `top.env` because of the equation for `e.env` in `negOp`.

As seen with direct sharing, the behavior of `new` also needs to handle productions with signature sharing, to avoid creating an un-decorated tree containing a shared subtree. Since every production with shared children must have been constructed via forwarding, undecorating the tree can simply return the undecoration of the tree that forwarded to it.

### Extensible dispatching
The above approach only works when forwarding to fixed implementation productions.  If one wishes to make use of a [dispatch attribute](/silver/ref/stmt/forwarding/#single-dispatch-via-forwarding) to permit extensions to specify overloads, then the dispatching production must be able to forward to independent implementation productions.  However simply forwarding to a function of type `(Expr ::= Decorated Expr with {})` is insufficient, as we must ensure that implementation productions are only applied as the forward of an appropriate dispatch production.  The solution is to enforce this in the type system, by defining a _dispatch signature_:
```
production negOp
top::Expr ::= e::Expr
{
  e.env = top.env;
  forwards to e.type.negProd(e);
}

dispatch UnaryOp = Expr ::= @e::Expr;

production negInt implements UnaryOp
top::Expr ::= @e::Expr
{
  top.type = intType();
  top.errors = e.errors;
}
production negBool implements UnaryOp
top::Expr ::= @e::Expr
{
  top.type = boolType();
  top.errors = e.errors;
}
production negError implements UnaryOp
top::Expr ::= @e::Expr msg::String
{
  forwards to errorExpr(msg);
}

synthesized attribute negProd::UnaryOp occurs on Type;
aspect production intType
top::Type ::=
{
  top.negProd = negInt;
}
aspect production boolType
top::Type ::=
{
  top.negProd = negBool;
}
aspect default production
top::Type ::=
{
  top.negProd = negError("Invalid operand to ~: " ++ top.typepp);
}
```

The dispatch signature `UnaryOp` defines a new nominal function type.  The `negInt` and `negBool` productions implement this signature, and have type `UnaryOp`.  The production `negError` has an extra child, so its type is effectively curried, giving `(UnaryOp ::= String)`.  Note that `UnaryOp` only has one shared child, but there are some cases where we may only want to supply attributes and dispatch on some children before forwarding, and have other children be only decorated after forwarding. For example in the Silver compiler, attribute equations are overloaded based on the left-hand side and sort of attribute:
```
dispatch AttributeDef = ProductionStmt ::= @dl::DefLHS @attr::QNameAttrOccur e::Expr;
```
Function application is overloaded for dispatch types, to permit calling them like ordinary functions. Every shared child in the dispatch signature must be supplied as the `Decorated` nonterminal type, and every non-shared child as the normal type.

As before, a value of a dispatch signature type can only be applied in the root position of a forward/forward production attribute equation.  All applications of a dispatch signature also must be exported by the declaration of the signature. This means that a production implementing a dispatch can make use of an inherited attribute on a shared child, and the well-definedness analysis can check for all applications of the dispatch, that an inherited attribute is supplied for the child in all these forwarding productions.

It is also possible to use an inherited attribute supplied in all implementation productions in the dispatch production.  For example, if an extension introduces an inherited attribute `env2` on `Expr`, and defines equations on all productions implementing `UnaryOp`, then the extension can rely on `env2` being supplied to the operand of `negOp`:
```
production thing
top::Expr ::= e::Expr
{
  top.someAnalysis = checkSomething(e.env2);
  forwards to negOp(@e);
}
```
Hidden transitive dependencies are (fortunately) not an issue if an inherited equation is supplied for a child in both a dispatch and an implementation production, since the dependencies of the override equation will be reflected in the implementation production.  However if all dispatch productions supply an equation for some attribute, then any equation for the attribute in an implementation production can never have any affect, and is reported as a duplicate equation.

It is also possible for an implementation production to itself forward to itself share children directly, or through additional levels of dispatching. Thus, resolving the presence of an inherited equation on some tree actually amounts to a recursive search process.

The dependencies of all inherited attributes supplied to shared children in dispatching productions are projected in the implementation productions, and vice versa, to ensure that (as before) `e.env` depends on `top.env` in `negInt`, and `e.env2` depends on `top.env2` in `negOp`.  This is actually done by constructing a separate flow graph for the dispatch signature, containing the projected inherited dependencies of all dispatch productions forwarding to it, as well as all implementing productions.

### Implementation production extension points
All extension implementation productions (ones implementing a dispatch signature, but that are not exported by that signature) are required to forward to host-language implementation productions.  This ensures that extension inherited attributes supplied for all host implementation productions (e.g. `env2` in the above example) are still supplied by independent extension implementation productions.  Additionally, any explicit inherited equations supplied by extension implementation productions cannot exceed the dependencies of corresponding host-language inherited equations.

The first requirement is actually a fairly strong restriction: an extension writer defining an overload for negation for their type would quite frequently wish to forward to something other than another unary operator:
```
production negFoo implements UnaryOp
top::Expr ::= @e::Expr
{
  forwards to call(name("neg_foo"), consExpr(@e, nilExpr()));
}
```
Here the `call`/`consExpr` productions could supply a different `env` than `negOp`, which is also potentially problematic.

Another extension might wish to simply reuse the syntax of negation to perform some transformation, where the operand doesn't even directly appear in the forward tree:
```
production negBar implements UnaryOp
top::Expr ::= @e::Expr
{
  e.subs = [("a", intLit(42))];
  forwards to e.inline;
}
```

To support these patterns, the host language developer can choose to introduce additional implementation productions that can be used as the target of forwarding.  For example, a production could be added to allow extensions to use the let binding approach:
```
production unaryBind implements UnaryOp
top::Expr ::= @e::Expr impl::(Expr ::= Name)
{
  local var::Name = freshName();
  forwards to let_(var, @e, impl(var));
}
```
This could be used to re-write `negFoo` as
```
production negFoo implements UnaryOp
top::Expr ::= @e::Expr
{
  forwards to unaryBind(e, \ n -> call(name("neg_foo"), consExpr(var(n), nilExpr())));
}
```
Note that any inherited equations supplied by `let_` to the bound expression must be are projected through both levels of sharing, and any host-language equations supplied in `negOp` should match those supplied by `let_`.  However, there is no need for an extension inherited attribute to be supplied in both places.

A host production could also be added to allow arbitrary transformations:
```
production unaryTransform implements UnaryOp
top::Expr ::= @e::Expr trans::Expr
{
  forwards to @trans;
}
```
This could be used to re-write `negBar`:
```
production negBar implements UnaryOp
top::Expr ::= @e::Expr
{
  e.subs = [("a", intLit(42))];
  forwards to unaryTransform(e, e.inline);
}
```

Note that including these host-language implementation productions does limit the analyses that can be performed directly on the `negOp` production, so there is a trade-off to be made by the host language designer.

### Referencing the forward parent
Occasionally it is useful in an implementation production to reference the tree that forwarded to it, termed the _forward parent_.  For example, a synthesized attribute can sometimes be defined with an override equation on a dispatch production without forwarding.  Implementation productions must still provide an equation for the synthesized attribute, but they should simply be able to reference the value computed on the dispatch production without re-defining the equation:
```
production negBaz implements UnaryOp
top::Expr ::= @e::Expr
{
  top.someAttr = forwardParent.someAttr;
}
```

One can only reference the forward parent in productions with shared children in the signature, because only those productions are guaranteed to only appear as the forward of another production.