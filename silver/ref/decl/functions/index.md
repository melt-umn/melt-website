---
layout: sv_wiki
title: Function declarations
menu_weight: 600
---

* Contents
{:toc}

```
function orElse
Maybe<a> ::= l::Maybe<a> r::Maybe<a>
{
  return if l.isJust then l else r;
}

function performSubstitution
TypeExp ::= te::TypeExp s::Substitution
{
  te.substitution = s;
  return te.substituted;
}
```

## Syntax

Functions declarations give a name for the function, and a signature in the same format as [productions](/silver/ref/decl/productions/), except that the left-hand side is not named.
Functions must also contain a [return statement](/silver/ref/stmt/return/).

## Semantics

Like the children of productions, function parameters may be supplied inherited attributes in the function body, and are considered implicitly decorated.
Unlike productions, there is no parent for autocopy attributes to come from.

Passing undecorated types to a function, accessing an attribute, and getting errors about missing inherited attribute equations is a common mistake for new Silver programmers.
Sometimes the function should have taken a reference (`Decorated Expr`) type instead of the undecorated (`Expr`) type.

All parameters are passed lazily.
There is currently no strictness annotation.

## Aspects

```
aspect function driver
_ ::= _ _ _
{
  tasks <- [emitDocumentation(ast)];
}
```

Aspect functions are also possible, by prefixing the declaration with `aspect`.
Aspect functions are forbidden from using `return`, their purpose is only to influence the value of "collection production attributes" (which is not only a mouthful, but misnomer inside a function, too!)

Aspecting functions is discouraged.
Future changes may deprecate this feature.

## FAQ

### Why is the syntax so verbose?

Silver functions were initially discouraged from use, as we tried to see how much we could do in an "attribute grammar-oriented" way, instead of resorting to traditional functional programming.
Over time, we developed a better understanding of where and why attribute grammars were interesting, but the syntax remained.

Eventually, there will likely be a more direct function declaration syntax in Silver, for various reasons.
(This syntax, for example, doesn't easily support adding type class constraints, if Silver ever gains type classes.)
But this syntax will remain, not just for compatibility reasons, but because it will be the only function declaration syntax that mimics the ability to decorate children (as productions do).
(Consider, for example, that Silver lambda expressions treat undecorated children as actually undecorated.)

