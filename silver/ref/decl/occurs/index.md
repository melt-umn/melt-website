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

An occurs-on declaration indicates that a (separately declared) attribute occurs on the (separately declared) nonterminal specified.
Most commonly, a nonterminal `with` clause will be used instead of this form of declaration directly.

For parameterized attributes, an occurs declaration also plays the crucial role of indicating how the attribute's type parameters should be determined, given a nonterminal and its type parameters.
If the attribute is not parameterized, the angle brackets are omitted.

<pre>
attribute <i>name</i> &lt; <i>types...</i> &gt; occurs on <i>nonterminal type</i>;
</pre>

Note that attributes can only occurs on _nonterminal_ types.
Also note that inside the angle brackets is a _type_ list as opposed to a _type variable_ list.
Thus, the following is a valid occurs on declaration:

```
synthesized attribute ast<a> :: a;
attribute ast<AbstractExpr> occurs on ConcreteExpr;
```

Only those type variables that appear in the nonterminal type on the right may appear in the type list for the attribute on the left.

## Convenience syntax

The most strongly preferred, whenever possible, means of declaring attribute occurrences is described on the [nonterminal declaration page](/silver/ref/decl/nonterminals/).
There is also a means of merging occurs on declarations with the [attribute declarations](/silver/ref/decl/attributes/) themselves.
Occurs declarations by themselves are rare in Silver code.


Additionally it is possible to declare more than one attribute, more than one nonterminal, or both in one occurs on declaration:

```
attribute env, pp, errors occurs on Expr, Stmt;
```

However, this syntax also falls prey to the same limitation described on the [attributes](/silver/ref/decl/attributes/) page.

