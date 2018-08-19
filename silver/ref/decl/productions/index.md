---
layout: sv_wiki
title: Abstract production declarations
menu_weight: 200
---

* Contents
{:toc}

Quick examples:

```
abstract production plus
e::Expr ::= e1::Expr  e2::Expr
{
}
```

This page covers abstract productions. See also [concrete productions](/silver/ref/decl/productions/concrete/) (which are about syntax), [aspect productions](/silver/ref/decl/productions/aspect/) (which are about introducing new attribute equations), [default productions](/silver/ref/decl/productions/default/) (which all default attributes equations to be written for a nonterminal).

## Syntax

Abstract production declarations introduce a new constructor for a nonterminal type.
Following the name of the production is the _production signature_ and then within braces, a set of _production statements_.

Any type variables not bound by the nonterminal type are universally quantified.
(And since productions are value constructors, this makes them existential types within the body, or when pattern matching.)

The number of children in the RHS can be zero.
Additionally, names can be omitted from any child that may be irrelevant (such as some terminals in concrete productions.)
In this case, just the type is written instead.

## Analogy to data types

Productions are similar to constructors in an algebraic data type.
You can also think of them as implementations of an abstract base class (which corresponds to the nonterminal, with its attributes as its interface) in an object-oriented language.

