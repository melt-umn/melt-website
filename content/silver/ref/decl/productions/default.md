---
title: Default production declarations
weight: 300
---

{{< toc >}}

Quick examples:

```
aspect default production
top::Expr ::=
{
  top.defs = [];
}
```

## Syntax

Default productions are similar to normal aspects, except that there is no name, and no children on the RHS.

## Semantics

Equations can be provided for synthesized attributes, and will apply to all **non-forwarding** productions constructing this nonterminal that **do not have** an explicit equation.
All forwarding productions will still get values via forwarding, unaffected (directly) by the default equation.

## A note about Silver and extensible languages

Default equations for attributes are **NOT** a part of the usual story of how extensible languages are built using Silver.
These are generally only useful for host-language designers, or within an extension's custom syntax.

Some people sometimes believe a new attribute can be introduced with a safe "do-nothing" default value, and then only override that value on productions they care about.
This is a "closed-world" style of reasoning that's not safely extensible.
There may be other productions out there that you do not know about that you should also be supplying a non-default value for.
Attempts to do "safe" extensibility in this way generally result in errors we call "[interference](/silver/concepts/interference/)."

## Interaction with forwarding

As mentioned in the semantics section, these are applied to non-forwarding productions.
This means if you access other attributes from the LHS, they will be the values produced from (or, for inherited attributes, supplied to) that non-forwarding node.

This means that if you write the following, and no other equations for `proxy`:

```
aspect default production
top::Expr ::=
{
  top.proxy = top.pp;
}
```

Then it is not necessarily true that `e.pp == e.proxy`.
If `e`'s root node is a forwarding production, then `e.pp` can come from the original tree, while `e.proxy` would come from what it ultimately forwards to, which can be different.

## Closed nonterminals

For language extension, we use nonterminals and forwarding as the extensibility story.
However, Silver supports another kind of extensibility.

Closed nonterminals are the dual story.
Instead of permitting new productions via forwarding to a semantically equivalent tree consisting of existing host language productions, we permit new attributes via defaulting to a semantically equivalent computation on existing host language attributes.

Closed nonterminals permit new variants to be introduced via object, and default equations for attributes are rather a lot like Java 7's interface default methods.

