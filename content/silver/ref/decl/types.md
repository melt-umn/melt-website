---
title: Type declarations
weight: 800
---

{{< toc >}}

Quick examples:

```
type EnvMap = TreeMap<String  Decorated Decl>;

type Set<a> = [a];
```

## Syntax

Transparent type aliases can be declared as follows:

<pre>
type <i>Name</i> &lt; <i>type variables...</i> &gt; = <i>type</i>;
</pre>

Please note these are aliases, not actual new types. For that see [nonterminal declarations](/silver/ref/decl/nonterminals/).

## FAQ

### Is there a newtype equivalent?

Haskell's `newtype` declares an _opaque_ type alias, meaning the new type name is not transparently equal to what it wraps.
Instead, the type must be explicitly wrapped and unwrapped.
Silver has no support for this yet, other than emulating it by using a nonterminal and production.

