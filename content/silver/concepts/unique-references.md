---
title: Unique References and Incremental Decoration
weight: 300
---

{{< toc >}}

Unique references are an extension to Silver's notion of [references to decorated trees](/silver/concepts/decorated-vs-undecorated).

## Motivating Example - The Exponential Redecoration Problem and `decExpr`

Let's take as an example, compiling a simple language with integers, booleans, and overloaded operators.
This language has an overloaded `&`, so that:

```
> true & false // logical
false
> 12 & 5       // bitwise
4
```

One way to implement this operator might look something like:

```silver
production andExpr
top::Expr ::= lhs::Expr  rhs::Expr
{
  forwards to
    case lhs.type, rhs.type of
    | boolType(), boolType() -> call(global("boolAnd"), exprsCons(lhs, exprsCons(rhs, exprsNil())))
    |  intType(),  intType() -> call(global( "intAnd"), exprsCons(lhs, exprsCons(rhs, exprsNil())))
    | _, _ -> errorExpr(...)
    end;
}
```

However, this has a big performance problem hiding in it!
`lhs` and `rhs` must be undecorated terms in order to be passed to `exprsCons`, so after type inference, the code is equivalent to:

```silver
production andExpr
top::Expr ::= lhs::Expr  rhs::Expr
{
  forwards to
    case lhs.type, rhs.type of
    | boolType(), boolType() -> call(global("boolAnd"), exprsCons(new(lhs), exprsCons(new(rhs), exprsNil())))
    |  intType(),  intType() -> call(global( "intAnd"), exprsCons(new(lhs), exprsCons(new(rhs), exprsNil())))
    | _, _ -> errorExpr(...)
    end;
}
```

This code may re-type-check an expression a number of times exponential in the nestedness of the expression!
To see why, let's look at how the expression `1 & (2 & (3 & 4))` gets type-checked, and count how many times `4` gets type-checked.

- To type-check `1 & (2 & (3 & 4))`, we need to evaluate its forward and type-check that; to do that, we need to type-check `1` and `2 & (3 & 4)`.
  - Type-checking `1` is trivial.
  - To type-check `2 & (3 & 4)`, we need to evaluate its forward and type-check that; to do that, we need to type-check `2` and `3 & 4`.
    - Type-checking `2` is trivial.
    - To type-check `3 & 4`, we need to evaluate its forward and type-check that; to do that, we need to type-check `3` and `4`.
      - Type-checking `3` is trivial.
      - Type-checking `4` is trivial. **(Type-checked 1 time)**
      - `3 & 4` forwards to `intAnd(3, 4)`
      - To type-check `intAnd(3, 4)`, we need to type-check `3` and `4`.
        - Type-checking `3` is trivial.
        - Type-checking `4` is trivial. **(Type-checked 2 times)**
    - `2 & (3 & 4)` forwards to `intAnd(2, 3 & 4)`.
    - To type-check `intAnd(2, 3 & 4)`, we need to type-check `2` and `3 & 4`.
      - Type-checking `2` is trivial.
      - To type-check `3 & 4`, we need to evaluate its forward and type-check that; to do that, we need to type-check `3` and `4`.
        - Type-checking `3` is trivial.
        - Type-checking `4` is trivial. **(Type-checked 3 times)**
        - `3 & 4` forwards to `intAnd(3, 4)`
        - To type-check `intAnd(3, 4)`, we need to type-check `3` and `4`.
          - Type-checking `3` is trivial.
          - Type-checking `4` is trivial. **(Type-checked 4 times)**
  - `1 & (2 & (3 & 4))` forwards to `intAnd(1, (2 & (3 & 4)))`.
  - To type-check `intAnd(1, intAnd(2, intAnd(3, 4)))`, we need to typecheck `1` and `intAnd(2, intAnd(3, 4))`.
    - Type-checking `1` is trivial.
    - To type-check `2 & (3 & 4)`, we need to evaluate its forward and type-check that; to do that, we need to type-check `2` and `3 & 4`.
      - Type-checking `2` is trivial.
      - To type-check `3 & 4`, we need to evaluate its forward and type-check that; to do that, we need to type-check `3` and `4`.
        - Type-checking `3` is trivial.
        - Type-checking `4` is trivial. **(Type-checked 5 times)**
        - `3 & 4` forwards to `intAnd(3, 4)`
        - To type-check `intAnd(3, 4)`, we need to type-check `3` and `4`.
          - Type-checking `3` is trivial.
          - Type-checking `4` is trivial. **(Type-checked 6 times)**
      - `2 & (3 & 4)` forwards to `intAnd(2, 3 & 4)`.
      - To type-check `intAnd(2, 3 & 4)`, we need to type-check `2` and `3 & 4`.
        - Type-checking `2` is trivial.
        - To type-check `3 & 4`, we need to evaluate its forward and type-check that; to do that, we need to type-check `3` and `4`.
          - Type-checking `3` is trivial.
          - Type-checking `4` is trivial. **(Type-checked 7 times)**
          - `3 & 4` forwards to `intAnd(3, 4)`
          - To type-check `intAnd(3, 4)`, we need to type-check `3` and `4`.
            - Type-checking `3` is trivial.
            - Type-checking `4` is trivial. **(Type-checked 8 times)**

The typical solution to this, colloquially called "`decExpr` productions," is to have a production like:

```silver
production decExpr
top::Expr ::= child::Decorated Expr
{
  top.type = child.type;
  -- equations for any other host-language synthesized attributes too
  -- since child is a reference, it already has all its inherited attributes
}
```

Then, instead of writing `new` (or having it implicitly inserted for you), you write:

```
production andExpr
top::Expr ::= lhs::Expr  rhs::Expr
{
  forwards to
    case lhs.type, rhs.type of
    | boolType(), boolType() -> call(global("boolAnd"), exprsCons(decExpr(lhs), exprsCons(decExpr(rhs), exprsNil())))
    |  intType(),  intType() -> call(global( "intAnd"), exprsCons(decExpr(lhs), exprsCons(decExpr(rhs), exprsNil())))
    | _, _ -> errorExpr(...)
    end;
}
```

Now, when you type-check `1 & (2 & (3 & 4))`, `4` gets type-checked only once (using `{| child |}` as concrete syntax for `decExpr`):

- To type-check `1 & (2 & (3 & 4))`, we need to evaluate its forward and type-check that; to do that, we need to type-check `1` and `2 & (3 & 4)`.
  - Type-checking `1` is trivial.
  - To type-check `2 & (3 & 4)`, we need to evaluate its forward and type-check that; to do that, we need to type-check `2` and `3 & 4`.
    - Type-checking `2` is trivial.
    - To type-check `3 & 4`, we need to evaluate its forward and type-check that; to do that, we need to type-check `3` and `4`.
      - Type-checking `3` is trivial.
      - Type-checking `4` is trivial. **(Type-checked 1 time)**
      - `3 & 4` forwards to `intAnd({| 3 |}, {| 4 |})`
      - To type-check `intAnd({| 3 |}, {| 4 |})`, we need to type-check `{| 3 |}` and `{| 4 |}`.
        - Type-checking `{| 3 |}` can use the already-computed type, so it doesn't need to do the actual work!
        - Type-checking `{| 4 |}` can use the already-computed type, so it doesn't need to do the actual work!
    - `2 & (3 & 4)` forwards to `intAnd({| 2 |}, {| intAnd({| 3 |}, {| 4 |}) |})`
    - To type-check `intAnd({| 2 |}, {| intAnd({| 3 |}, {| 4 |}) |})`, we need to type-check `{| 2 |}` and `{| intAnd({| 3 |}, {| 4 |}) |}`
      - Type-checking `{| 2 |}` can use the already-computed type, so it doesn't need to do the actual work!
      - Type-checking `{| intAnd({| 3 |}, {| 4 |}) |}` can use the already-computed type, so it doesn't need to do the actual work!
  - `1 & (2 & (3 & 4))` forwards to `intAnd({| 1 |}, {| intAnd({| 2 |}, {| intAnd({| 3 |}, {| 4 |}) |}) |})`
  - To type-check `intAnd({| 2 |}, {| intAnd({| 3 |}, {| 4 |}) |})`, we need to type-check `{| 2 |}` and `{| intAnd({| 3 |}, {| 4 |}) |}`
    - Type-checking `{| 1 |}` can use the already-computed type, so it doesn't need to do the actual work!
    - Type-checking `{| intAnd({| 2 |}, {| intAnd({| 3 |}, {| 4 |}) |}) |}` can use the already-computed type, so it doesn't need to do the actual work!

## Problems of `decExpr` With Extensions

Let's say the compiler was structured so type-checking and most other semantic analyses are in the "core," but actual translations are implemented as extensions.
(Or if that feels a bit far-fetched, pretend this is an extension that adds a new translation.)

To collect all the target language declarations, we have a threaded pair of attributes.
(This might be done instead of using a [monoid attribute](/silver/concepts/automatic-attributes/#monoid-attributes) to allow for pure generation of fresh names.)

```silver
inherited attribute transDeclsIn::[Decl];
synthesized attributes transDecls::[Decl];
```

What would the aspect for `decExpr` look like?
It can't simply add additional attributes to the reference, so there's not really a better solution than:

```silver
aspect production decExpr
top::Expr ::= child::Decorated Expr
{
  production transDeclsChild::Expr = child;
  transDeclsChild.typeEnv = top.typeEnv;
  -- equations for any other host-language inherited attributes in transDecls' flowtype
  transDeclsChild.transDeclsIn = top.transDeclsIn;
  top.transDecls = transDeclsChild.transDecls;
}
```

However, this has the exponential redecoration problem again, for the `transDecls` attribute!
What we _want_ is some way to write:

```silver
aspect production decExpr
top::Expr ::= child::Decorated Expr
{
  child.transDeclsIn = top.transDeclsIn;
  top.transDecls = child.transDecls;
}
```

However, this isn't possible, since we don't know that `child` doesn't already have an equation for `transDeclsIn`.
For example, another extension could add:

```silver
production fooExpr
top::Expr ::=
{
  local expr::Expr = litIntExpr(5);
  expr.transDeclsIn = [];
  forwards to
    if expr.someSynThatDependsOnTransDeclsIn
    then decExpr(expr)
    else errorExpr(...);
}
```

In this case, the `child.transDeclsIn` equation in `decExpr` can't work, since the process of computing `someSynThatDependsOnTransDeclsIn` might have put the `[]` somewhere that it might need to be removed.[^rmattrs]

[^rmattrs]: One might have the idea that we could just make a copy of the tree, and remove any attribute values that somehow depend on the attributes being supplied. However actually storing the needed dependency information at run time would add quite a bit of overhead and complexity, and we would still like to share the portions of the tree that don't depend on the removed attributes - this is more difficult to achieve than it may appear.

## Unique References as a Solution

Unique references make it sound to write `child.transDeclsIn`, under some conditions.
It introduces a new variety of type, `UniqueDecorated ... with ...`.

`UniqueDecorated Expr` is a *unique* reference to a decorated `Expr` -
a unique reference to this tree does not exist anywhere else
(although there may be more ordinary references, of type `Decorated Expr`.)
Furthermore this tree must have been originally decorated with *only* the
[reference set](/silver/concepts/decorated-vs-undecorated/#more-specific-reference-types) of attributes,
rather than *at least* the reference set of attributes (as is the case for `Decorated Expr`.)
These two constraints make it safe to supply inherited attribute equations to a unique reference,
without fear of introducing duplicate equations.

For example, one can now write
```silver
aspect production decExpr
top::Expr ::= child::UniqueDecorated Expr
{
  child.transDeclsIn = top.transDeclsIn;
  top.transDecls = child.transDecls;
}
```
Here `child` refers to the same original tree that was decorated in `fooExpr` (or elsewhere).
However we can now supply `transDeclsIn` to this tree, allowing one to access `transDecls`,
while reusing any other attributes that were originally computed on `child`.

## Restrictions on Unique References

Decorating a tree with additional attributes works by *mutating* the original tree to add the additional attribute equations.
This means that we must be sure that any time we take a unique reference to a tree, we must be sure never to decorate the original tree with more attributes!

These requirements are enforced with several restrictions in the flow analysis, and a new _uniqueness analysis_.
First, if we take a unique reference to some child or local (termed a _decoration site_), it is a flow error to supply any inherited equations that are not in the reference set:

```silver
production barExpr
top::Expr ::= child::Expr
{
  child.barInh = true;
  top.errors <- if child.barSyn then [] else [err(child.location, "Not bar")];

  forwards to barFwd(child);
}

production barFwd
top::Expr ::= child::UniqueDecorated Expr with {env}  -- Doesn't contain barInh!
{ ... }
```
In the above, a flow error is raised on the equation for `barInh` in the `barExpr` production; this is potentially a duplicate equation, as we are taking a unique reference to `child` with only `env` in the forward for `barExpr`. The `barFwd` production could have an equation `child.barInh = false;`, which would conflict with this one.

Similarly, it is also illegal to take multiple unique references to the same decoration site:
```silver
production bazExpr
top::Expr ::= child::Expr
{
  production child1::UniqueDecorated Expr = child;
  child1.barInh = true;

  production child2::UniqueDecorated Expr = child;  -- Duplicate unique reference!
  child2.barInh = false;

  top.barSyn = child1.barSyn || child2.barSyn;
}
```

The uniqueness analysis restricts the places where it is legal to take a unique reference.
For example, it is illegal to take a unique reference in an attribute equation,
as value of the attribute may be accessed and decorated in multiple places.
The analysis is essentially a special case of linear types, with some special consideration of Silver's semantics for undecoration.
Essentially, the analysis states that a unique reference may only be taken in a unique context,
where a unique context means an expression whose result is known to only be decorated once.
An expression is in a unique context if it is:
1. The forwards-to expressions of a production
2. The right side of an equation for a local or production attribute
3. The `then` or `else` branch of an `if` in a unique context
4. A clause of a `case` in a unique context
5. An argument in a call to a known function or production, where the child/parameter is not a type variable
6. An argument in an arbitrary function application, where the parameter is not a type variable or undecorated nonterminal type
7. The return expression of a function, if the function has a `UniqueDecorated` parameter
8. The body of a lambda, if the unique reference is to a `UniqueDecorated` lambda parameter

Cases 1 and 2 above are unique contexts, because although the values of these expressions are decorated every time the production is decorated (or the function is called, in the case of locals in a function), these values are newly created every time the enclosing production is decorated - thus, they are only decorated once.

Cases 3 and 4 are self-evident - these values of these sub-expressions are decorated when the enclosing expression is decorated.

Case 6 constitutes a unique context because no production/function that passes the uniqueness analysis can decorate a unique reference argument more than once,
and no other type besides a nonterminal can be decorated at all.
The parameter/child must however be monomorphic (cannot contain type variables), as there is no restriction preventing polymorphic values from being duplicated -
solving this would require introducing some notion of linear types.
For now this 

For example:
```silver
production quxExpr
top::Expr ::= child::Expr
{
  forwards to doubleExpr(decExpr(e));
}

production doubleExpr
top::Expr ::= e::Expr
{
  forwards to addExpr(e, e);
}
```
Here  `doubleExpr` decorates its child twice by forwarding to `addExpr`.  If `doubleExpr` is passed a `decExpr`, any inherited equations written on `decExpr` will cause the `UniqueDecorated Expr` to be decorated twice.

