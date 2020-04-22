---
layout: sv_wiki
title: Attribute declarations
menu_weight: 300
---

* Contents
{:toc}

Quick examples:

```
synthesized attribute pp :: Document;

inherited attribute env<a> :: Map<String a>;
```

## Syntax

Attribute declarations begin by indicating whether the attribute is `synthesized` or `inherited`, give a name for the attribute, and the type of the attribute.
Attributes may also be parameterized in their types.
If they are not parameterized, the angle brackets are omitted:

<pre>
synthesized attribute <i>name</i> &lt; <i>type variables...</i> &gt; :: <i>type</i>;
inherited attribute <i>name</i> &lt; <i>type variables...</i> &gt; :: <i>type</i>;
</pre>

All type variables that appear in the type must be declared in the type parameter list.

For an explanation of the role of attributes, see [the section on attribute grammars](/silver/tutorial/4_attribute_grammars/).
A deeply related concept is the [occurs-on declaration](/silver/ref/decl/occurs/).

## Autocopy attributes

For language processing, nearly all `inherited` attributes are better described as `autocopy` attributes:

<pre>
autocopy attribute <i>name</i> :: <i>type</i>;
</pre>

Autocopy attributes differ from inherited attributes in that some equations are automatically generated.
Unless an attribute equation in a production body gives a different rule, the attribute is simply copied from the parent to all children the attribute also occurs on.

Note that currently, autocopy attributes are not permitted to be parameterized.
This restriction may or may not be lifted in the future.

## Collection attributes

Attributes that may have their value influenced by aspects are called collection attributes, and are declared by giving the attribute an associated _composition operator_ using `with`:

```
synthesized attribute errors :: [Message] with ++;
```

This operator must be either `++` (for lists or strings), `||`, `&&`, or any user-defined function of type `Function(a ::= a a)`.
In practice, this is almost always list append.
See [collection attributes](/silver/concepts/collections/).

## Automatically propagated attributes

Some repetitive idioms exist in synthesized attribute specifications that we would like to avoid writting boilerplate for by hand.
These attributes fall into various common patterns ("functor", "monoid", etc.)

A set of extensions to Silver allows for such attributes to be specially declared, and a new statement `propagate attr1, attr2, ...;` to
be used to specify on a production or nonterminal that equations for the attributes should be automatically generated.

See [automatic attributes](/silver/concepts/automatic-attributes/).

## Convenience extensions

Attributes declarations and occurs-on declarations can be merged:

```
synthesized attribute pp :: String occurs on Expr, Stmt;
```

However, this should not be used in any circumstance where the nonterminal and the occurs-on declarations can be merged instead.
(See the [nonterminal](/silver/ref/decl/nonterminals/) documentation for that syntax.)
For more reasons that just the stylistic: this syntax is more inflexible for parameterized attributes.

> _**Example**_: To demonstrate the inflexibility, the following code will raise an error:
```
 synthesized attribute ast<a> :: a occurs on ConcreteExpr;
```
> Because there is no place where we are able to describe what the type parameter of the `ast` attribute should be on `ConcreteExpr`.
