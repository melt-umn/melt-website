---
title: Unique references
weight: 300
---

{{< toc >}}

Unique references are an extension to Silver's notion of [references to decorated trees](/silver/concepts/decorated-vs-undecorated).

**NOTE**: This feature is under active development. This documentation is somewhat incomplete and will be revised soon.

## The Exponential Redecoration Problem and `decExpr`

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
`lhs` and `rhs` must be undecorated terms in order to be passed to `exprsCons`, so after decoration inference, the code is equivalent to:

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

## Unique references as a Solution

Unique references make it sound to write `child.transDeclsIn`, under some conditions.
It introduces a new variety of type, `Decorated! ... with ...`,
where `Decorated!` is pronounced "unique decorated".

`Decorated! Expr` is a unique reference to some tree, that may be safely supplied with additional inherited attributes without potentially creating duplicate equations.
If you were to instead write:

```silver
aspect production decExpr
top::Expr ::= child::Decorated! Expr
{
  child.transDeclsIn = top.transDeclsIn;
  top.transDecls = child.transDecls;
}
```

This will reuse any thunks that are already present on `child`, like the original `decExpr` did.
However, `transDecls` now works!

## Overriding equations

Decorating a tree with additional attributes works by *mutating* the original tree to add the additional attribute equations.

When a direct equation is supplied to a tree, and the tree is later supplied with additional inherited attributes through a reference, the original equation takes precedence:
```silver
production barExpr
top::Expr ::= child::Expr
{
  child.barInh = true;
  top.errors <- if child.barSyn then [] else [err(child.location, "Not bar")];

  forwards to barFwd(child);
}

production barFwd
top::Expr ::= child::Decorated! Expr with {env}
{
  child.barInh = false;
  ...
}
```
Here `child` in the forward of `barExpr` will have `barInh = false`, despite the equation in `barFwrd`.

## Restrictions
The uniqueness analysis enforces that there is never more than one unique reference taken to a tree.
Thus it illegal to take multiple unique references to the same decoration site:
```silver
production bazExpr
top::Expr ::= child::Expr
{
  production child1::Decorated! Expr = child;
  child1.barInh = true;

  production child2::Decorated! Expr = child;
  child2.barInh = true;

  top.barSyn = child1.barSyn || child2.barSyn;
}
```

Unique references may also only be taken in *unique contexts*, that is expressions that are known to only be decorated once.  These are forward and local equations, and arguments to production calls that are themselves in unique contexts.