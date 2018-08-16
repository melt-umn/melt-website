---
layout: sv_wiki
title: Annotation declarations
menu_weight: 1000
---

* Contents
{:toc}

```
annotation origin :: Origin;
```

## What are annotations?

Recall the distinction between [decorated and undecorated types](../../../concepts/decorated-vs-undecorated).
Attributes are computed on decorated nodes: to obtain a decorated node, an undecorated node is supplied with inherited attributes.
This makes the synthesized attributes on that node (which might use those incoming inherited attributes) computable. 

Annotations are very different from attributes.
They are values that are supplied to create undecorated nodes --- just as the children of a production are supplied to create an undecorated node.
Unlike children, however, they are not something you would supply inherited attributes to, and the annotation appears uniformly on **all** productions for a nonterminal.

## Declaration syntax

Annotation declaration looks very similar to attribute declarations:

```
annotation foo<a> :: a;
annotation origin :: Origin;
annotation location :: Location;
```

## Occurs syntax

Again, the syntax looks very much like for attribute occurrence declarations:

```
annotation origin occurs on Expr;
```

And annotations can be listed along side attributes in nonterminal `with` syntax:

```
nonterminal Expr with location, foo<String>;
```

## Access syntax

The syntax looks just like attribute access.

```
top.location
```

There's an important semantic difference, however: annotations are accessed from the undecorated node, whereas to evaluate an attribute you require a decorated node.

## Application syntax

Annotations are supplied via named arguments when a node is created.
The syntax looks as follows:

```
and(l.ast, r.ast, location=lhs.location)
```

The named arguments **must** come after the ordered arguments.

## Implicit location

In the standard library there is an `location` annotation that the parser has special understanding of, and it will automatically populate concrete syntax nodes with this location during parsing.

This should make obtaining location much easier.

## Feature wishlist

Annotations are a feature that's not fully matured, and so sometimes there are missing features we'd like.
[A wishlist is tracked on github](https://github.com/melt-umn/silver/issues/32).

## Acknowledgements

The idea for annotations was shamelessly stolen from [Rascal](https://www.rascal-mpl.org/). Yoink!

