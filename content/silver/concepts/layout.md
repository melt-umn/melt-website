---
title: Layout
weight: 400
---

{{< toc >}}

Most scanner generators (such as Flex) require one to specify a global set of ignored terminals.
Silver (and Copper) do things differently, since sometimes we want embed one language in another that has different notions of comments/whitespace.

## Production layout

The ignored whitespace (the "layout") of a production is a set of ignored terminals inserted between every element on the production's right-hand side. So:

```
Decl ::= 'typedef' Type Identifiers ';'
```

will (in effect) be expanded to

```
Decl ::= 'typedef' Layout Type Layout Identifiers Layout ';'
```

Note that before and after the first and last signature element there is no `Layout` added: that's the responsibility of the parent production, whatever that may be.

## Layout inference

The layout of a production is by default inherited from a layout set associated with its nonterminal.

The layout of a nonterminal is determined at its declaration; this can be affected in several ways.  For a nonterminal `Foo`, the set is inferred to contain
* All [ignore terminals](/silver/ref/decl/terminals#ignore-terminals) exported by the grammar declaring `Foo`.
* The layout of any nonterminal `Bar` for which there exists a production `bridge :: (Bar ::= ... Foo ...)`, where `bridge` is exported by the grammar declaring `Foo`.

For example, in
```
grammar a;

ignore terminal Newline_t /\n/;
nonterminal A;
```
the layout of `A` would be `{Newline_t}`, and in
```
grammar b;
imports a;

nonterminal B;
concrete production prod
top::A ::= B
{}
```
the layout of `B` would be the same as `A` due to the production `prod`, however in
```
grammar c;
imports a;
nonterminal C;
```
the layout of `C` would be `{}`.

The reason for this behavior is that new nonterminals introduced by an extension are typically only reachable from the host language, and one typically wishes them to use the host language layout as well.
Host languages may also be divided into multiple grammars in a similar fashion.
In these cases, we want all nonterminals to inherit the same layout, even when defined in grammars that don't directly export the host language.

However sometimes we may want to embed entire sub-languages that use different layout.
For example we may want to have different comment syntax for a SQL query extension to C, or regex literals that have an empty layout set.
In these cases we don't want host-language layout terminals to pollute (and possibly conflict with) the embedded language,
thus we take the more conservative approach of only considering productions that are exported by the grammars in which their nonterminals are declared.

Note that bridge productions can exist in both directions between two nonterminals; this means that their layout is mutually dependent.
To deal with this situation, the inference process involves building a graph of all nonterminals that can be derived from other nonterminals, and using this to construct the layout.


## Overriding the inferred layout
The inferred layout sets are usually correct, as determined by the ignore terminals, bridge productions and exports relationships between grammars. 
However there are cases when the inferred layout for a nonterminal isn't desired,
such as seen [in the ableC-prolog extension](https://github.com/melt-umn/ableC-prolog/blob/develop/grammars/edu.umn.cs.melt.exts.ableC.prolog/core/concretesyntax/ConcreteSyntax.sv#L69).
In these cases a different layout set can be [specified for a nonterminal](/silver/ref/decl/nonterminals#layout).
This overridden layout set affects the inferred layout for any nonterminals with known bridge productions from the nonterminal in question.

The layout of a specific production can also be [overridden](/silver/ref/decl/productions/concrete#layout); this does not affect the inference process.
