---
title: Local equations
weight: 30.0
---

{{< toc >}}

```
abstract production id
lhs::Expr ::= n::String
{
  local refs :: [Decorated Dcl] =
    lookupName(n, lhs.env);
}
```

## Syntax

The preferred form of local declarations is shown above, as one production statement.

Production attributes (local visible to all aspects, not just the current production body) can be declared in the same way, except using `production` instead of `local`.

## Legacy syntax

The old form of local declaration is two-part. First, the local is declared:
```
local attribute <name> :: <type>;
```
The name of the attribute and its type (following the has-type symbol
**::**) is similar to the name/type specifications in production
signatures. This attribute can be referenced inside the production body. The
separate definition of its value has the form
```
<name> = <expression>;
```

## Higher-order attributes

If the local attribute is a higher order attribute (its type is a
nonterminal), then inherited attributes can be set on it just like
they are set for the nonterminal children on the right-hand side of
the production.

```
{
  local chain :: IOChain = print("hello, world");
  chain.inputIOToken = ioin;
}
```

## Non-decorated local definitions

Sometimes, one wishes to define a local or production attribute with a nonterminal type, that should not be a higher-order attribute. For instance, a local may portion of a larger tree being constructed, that is not directly supplied with inherited attributes.  These locals can be marked as `nondecorated`:

```
{
  nondecorated local foo :: Expr = addOp(intLit(42), varExpr("x"));
  nondecorated production bar :: Expr = mulOp(foo, varExpr("x"));
}
```

The syntax `nondecorated foo :: Expr = ...;` is also available as shorthand for `nondecorated local foo :: Expr = ...;`.

Uses of a `nondecorated` local will have the [undecorated](/silver/concepts/decorated-vs-undecorated) nonterminal type, rather than the `Decorated` type for locals and children.  Inherited equations and [tree sharing](/silver/concepts/tree-sharing) are forbidden for `nondecorated` locals.

## Collection attributes

Currently, production attributes can be [collections](/silver/concepts/collections/), but the legacy syntax must be used.

```
{
  production attribute contribs :: [Stmt] with ++;
  contribs := [];
}
```