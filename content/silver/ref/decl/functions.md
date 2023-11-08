---
title: Function declarations
weight: 600
---

{{< toc >}}

Quick examples:

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

Passing undecorated types to a function, accessing an attribute, and getting errors about missing inherited attribute equations is a common mistake for new Silver programmers.
Sometimes the function should have taken a reference (`Decorated Expr`) type instead of the undecorated (`Expr`) type.

All parameters are passed lazily.
There is currently no strictness annotation.

## Aspecting functions

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

## Concise function declarations
A more concise function declaration can often be used in cases where a function simply returns an expression. Examples:
```
fun foldr b ::= f::(b ::= a b)  i::b  l::[a] =
  if null(l) then i else f(head(l), foldr(f, i, tail(l)));

fun lookup Eq a => Maybe<b> ::= lst::[(a, b)] key::a = 
  case lst of
    [] -> nothing()
  | h::t -> if fst(h) == key then just(snd(h)) else lookup (t, key)
  end;

fun getName
  attribute name i occurs on a => 
  Integer ::= inst::Decorated a with i = inst.name;
```
These functions do not require a decoration context, which makes the concise function representation more efficient than ordinary functions. Functions of this style are simply treated as global named lambda expressions. 