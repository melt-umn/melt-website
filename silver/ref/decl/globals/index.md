---
layout: sv_wiki
title: Global constant declarations
menu_weight: 700
---

* Contents
{:toc}

Quick examples:

```
global defaultSuffix :: String = "_sfx";

global ones :: [Integer] = 1 :: ones;
```

## Syntax

Global values can be declared as follows:

<pre>
global <i>name</i> :: <i>Type</i> = <i>expression</i>;
</pre>

Types are required.

## FAQ

### What's the point?

Globals are just for declaring constant values of some use.
Since Silver is a pure language, globals don't have the same use as in some other languages (where they might be mutable, for isntance.)

Most commonly global values declarations used as part of testing code, declaring values that will get operated on in tests several different ways.

