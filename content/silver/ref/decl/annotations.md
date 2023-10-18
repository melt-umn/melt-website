---
title: Annotation declarations
weight: 1000
---

{{< toc >}}

Quick examples:

```
annotation origin :: Origin;
annotation tag<a> :: a;
```

## What are annotations?

Recall the distinction between [decorated and undecorated types](../../../concepts/decorated-vs-undecorated).
Attributes are computed on decorated nodes.
To obtain a decorated node, an undecorated node is supplied with inherited attributes.
This makes the synthesized attributes on that node (which might need to use those incoming inherited attributes) computable. 

Annotations are very different from attributes.
They are values that are supplied to create undecorated nodes --- similar to a production's children.
Unlike children, however, they are not something you would supply inherited attributes to, and an annotation appears uniformly on **all** productions for a nonterminal.

Annotations are often useful in representing data structures, such as [`Pair`](/silver/ref/lib/pair).

## Declaration syntax

Annotation declaration looks very similar to [attribute declarations](/silver/ref/decl/attributes/):

```
annotation foo<a> :: a;
annotation origin :: Origin;
annotation location :: Location;
```

## Annotation occurs syntax

Again, the syntax looks very much like for [attribute occurrence declarations](/silver/ref/decl/occurs/):

```
annotation location occurs on Expr;
```

And annotations can also be listed along side attributes in nonterminal `with` syntax:

```
nonterminal Expr with location, foo<String>;
```

## Annotation access syntax

The syntax looks just like [attribute access](/silver/ref/stmt/equations/).

```
top.location
```

There's an important semantic difference, however: annotations are accessed from the undecorated node, whereas to evaluate an attribute you require a decorated node.

## Supplying annotations

Annotations are supplied via named arguments when a node is created.
The syntax looks as follows:

```
and(l.ast, r.ast, location=lhs.location)
```

The named arguments **must** come after the ordered arguments.

## Production types with annotations

The type of a production for a nonterminal with annotations is a function type with named parameters, for example one could write:

```
global myAnd::(Expr ::= Expr Expr; location::Location) = and;
```

Currently, productions with annotations are the only way of creating a function with named parameters.
In the future we may generalize this to support arbitrary functions with named parameters.

## Implicit location

In the standard library there is a `location` annotation that the parser has special understanding of.
Normally, the parser would not know how to supply an annotation value for the concrete syntax it is parsing, but `location` is special and will be automatically filled in during parsing.

This should make obtaining location much easier.

## Feature wishlist

Annotations are a feature that's not fully matured, and so sometimes there are missing features we'd like.
[A wishlist is tracked on GitHub](https://github.com/melt-umn/silver/issues/32).

## Acknowledgments

The idea for annotations was shamelessly stolen from [Rascal](https://www.rascal-mpl.org/). Yoink!

