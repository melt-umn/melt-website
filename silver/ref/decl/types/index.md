---
layout: sv_wiki
title: Type declarations
menu_weight: 800
---

* Contents
{:toc}

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

Not yet, but someday.
