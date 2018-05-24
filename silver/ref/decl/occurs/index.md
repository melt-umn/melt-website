---
layout: sv_wiki
title: Occurs declarations
menu_weight: 400
---

* Contents
{:toc}

```
attribute pp occurs on Expr;

attribute fst<a> occurs on Pair<a b>;
```

## Syntax

Occurs-on declarations indicate that separately declared attributes occur on the separately declared nonterminal specified.  For parameterized attributes, they also play the crucial role of indicating how the attribute's type parameters should be determined, given a nonterminal and its type parameters.

`attribute` _identifier_ `occurs` `on` _nonterminal type_ `;`

`attribute` _identifier_ `<` _type list_ `>` `occurs` `on` _nonterminal type_ `;`

Note that attributes can only occurs on _nonterminal_ types.  Also note that inside the angle brackets is a _type_ list as opposed to a _type variable_ list.  Thus, the following is a valid occurs on declaration:

```
synthesized attribute ast<a> :: a;
attribute ast<AbstractExpr> occurs on ConcreteExpr;
```

Only those type variables that appear in the nonterminal type on the right may appear in the type list for the attribute on the left.

## Convenience syntax

The most strongly prefered, whenever possible, means of declaring attribute occurrences is described on the [nonterminal declaration page](/silver/ref/decl/nonterminals/).  There is also a convenient mention of merging occurs on declarations and [attribute declarations](/silver/ref/decl/attributes/).

Additionally it is possible to declare more than one attribute, more than one nonterminal, or both in one occurs on declaration:

```
attribute env, pp, errors occurs on Expr, Stmt;
```

However, this syntax also falls prey to the same limitation described on the [attribute](/silver/ref/decl/attributes/) page.
