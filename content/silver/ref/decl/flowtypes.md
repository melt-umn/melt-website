---
title: Flow type declarations
weight: 650
---

{{< toc >}}

Quick examples:

```
flowtype Expr =
  decorate {env, returnType},
  forward {env},
  isLValue {decorate};
  
flowtype pp {} on Expr, Exprs;
```

## Syntax

Nonterminal-oriented (generally preferred syntax):

<pre>
flowtype <i>Nonterminal</i> =
  <i>synthesized attribute</i> { <i>inherited attributes...</i> }, ...;
</pre>

or attribute-oriented (generally used by extensions introducing an attribute on the host language):

<pre>
flowtype <i>synthesized attribute</i> { <i>inherited attributes...</i> } on <i>Nonterminals...</i>;
</pre>

## Semantics

A flow type indicates what set of inherited attributes are ultimately usable by a synthesized attribute equation.
This information only has relevance to the [modular well-definedness analysis](/silver/concepts/modular-well-definedness/).
This both informs users what inherited attributes they must supply, and also limits attribute equations to using no more than the specified set.
Without a `flowtype` declaration, the flow types are simply inferred.


There are two special values that may be used in place of a synthesized attribute in the nonterminal-oriented syntax.
First, you can use `forward` to specify a "flow type" for the _forwarding equation_ (meaning essentially the same thing as for a synthesized attribute: what inherited attributes may be used in defining a `forwards to` clause on this nonterminal).
This is especially useful in host languages that might not have any forwarding productions to help infer the correct value that will be imposed on extensions.

```
flowtype Expr = forward {env};
```

Second, you can use `decorate` to specify a special "blessed set" of attributes as the default set of attributes that are expected to be present/necessary for references (`Decorated` nonterminals).
Strictly speaking, this isn't necessarily a "flow type" but we just use this same syntax, and it mostly has the same meaning.
```
flowtype Expr = decorate {env, returnType};
```
In this case writing the type `Decorated Expr` is equivalent syntactic shorthand for writing `Decorated Expr with {env, returnType}`.
To take a reference of this type to a decorated tree, this set must be supplied, and when accessing from a reference of this type, this set are the only inherited attributes presumed to be supplied.


Finally, there is one last special case.
In practice, it is frequently useful to be able to set the `decorate` or "flow type" and re-use that value for many synthesized attributes.
(This is a result of the "infectious" nature of using references withing a tree.
Once you have a production with a reference as a child, quite a lot of attributes start to have identical flow types to `decorate`.)
To support making these easier to write and maintain, we allow `decorate` to be used in place of the name of an inherited attribute, _if_ an explicit flow type is already given for `decorate`.
This is illustrated in the example above with `isLValue`:

```
flowtype Expr = decorate {env, returnType}, isLValue {decorate};
```

Similarly, we also permit setting the `forward` flow type and using that in an extension flow type specification.
This is useful in specifying flow types for extension attributes on host nonterminals, as these are required to always contain at least the host-language forward flow type for the nonterminal.

```
flowtype Expr = forward {env};
...
flowtype myExtSyn {forward, myExtInh} on Expr;
```

## FAQ

### In the attribute-oriented syntax, why can't I vary the inherited set?

The most common case is to use the same flowtype for an attribute on a lot of nonterminals.
If you need to vary it, just write several flowtype declarations in sequence.
In such situations, you might even want to consider writing a comment explaining why one nonterminal or another deviates from the usual.

