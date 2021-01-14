---
title: Nonterminal declarations
weight: 100
---

{{< toc >}}

Quick examples:

```
nonterminal Expression;
nonterminal List<a>;
nonterminal Pair<a b>;
```

## Syntax

Nonterminals are declared using the keyword `nonterminal` followed by a name, and an optional type parameter list.

<pre>
nonterminal <i>Name</i>;
nonterminal <i>Name</i> &lt; <i>type variables...</i> &gt;;
</pre>

The name, like all type names in Silver, must start with a capital letter.
Type variables must be lower case.

## Quickly declaring occurrences

Silver also allows a nonterminal declaration to include a comma-separated list of [attribute occurrences](/silver/ref/decl/occurs/) using the `with` keyword.
For example:

```
nonterminal Expression with pp, env, errors;

nonterminal Pair<a b> with fst<a>, snd<b>;
```

The use of this extension is highly encouraged.

## Analogy to data types

Nonterminals in Silver are somewhat similar to data types in other functional languages, like Haskell.
The major initially noticeable difference is that Silver does not require a fixed list of constructors (and we use different names, calling constructors [productions](/silver/ref/decl/productions/).)

Similarly, nonterminals are somewhat like abstract class declarations in other object-oriented languages, like Java.
The major initially noticeable difference is the lack of a fixed list of (virtual) methods (and in Silver they're called [attributes](/silver/ref/decl/attributes/) and must be declared to [occur](/silver/ref/decl/occurs/) on the nonterminal.)

## Concrete Syntax

Nonterminal declarations are used for all data representation in Silver, including concrete syntax.
Nothing specific to the nonterminal designates whether it is a "concrete syntax nonterminal" or not.
The only distinction is whether or not any `concrete` productions are declared for a nonterminal.
If not, then it's not considered part of the concrete syntax.

## Closed nonterminals

These should be used sparingly for representing languages, except for pure concrete syntax.

There is a duality in the approach we can take to making an extensible data type.
For (non-closed) nonterminals, we leave open the ability to declare new attribute occurrences, but we expect there (in the [modular well-definedness analysis](/silver/concepts/modular-well-definedness/)) to be a fixed set of non-forwarding productions (in the "host language").

This is the generally correct design for nearly all AST-like nodes.
To do otherwise impairs practical extensibility.

However, for some kinds of data structures (or for pure concrete syntax) the dual approach is desired.
We want to close off the ability to introduce new (non-[defaulted](/silver/ref/decl/productions/default/)) attribute occurrences, but now permit introduction of arbitrary new non-forwarding productions.
This impairs the ability to analyze these trees in novel ways, but allows new productions which have no equivalent tree they could have forwarded to.

In practice, closed nonterminals are used to describe purely concrete syntax.

```
closed nonterminal Expr_c with ast<Expr>;
```

This kind of type needs no new attributes, everything should just construct an appropriate abstract representation, and the interesting work can happen there.


