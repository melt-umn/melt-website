---
layout: sv_wiki
title: Pattern matching
menu_weight: 300
---

* Contents
{:toc}

Quick examples:

```
case lhs, rhs of
| just(l), just(r) -> l ++ r
| just(l), nothing() -> l
| nothing(), just(r) -> r
| nothing(), nothing() -> []
end
```

## Pattern Matching

Silver supports pattern matching on decorated nonterminal types.
(It will also pattern match on undecorated nonterminal types, but implicitly "decorates" them with no inherited attributes.)

The expression has the following syntax:

<pre>
case <i>expressions...</i> of
| <i>patterns...</i> -> <i>expression</i>
...
end
</pre>

Patterns must be constructors of the appropriate types, the wildcard `_`, or a new name (a pattern variable) that will be bound to the value that appears in that position in the value being matched against.

> _**Example:**_
```
local attribute val :: Maybe<Pair<String String>>;
-- ...
case val of
| just(pair(a, _)) -> "Key is " ++ a
| nothing() -> "Key not present"
end
```
> produces a string value based on the value of _`val`_.

## Guards

Pattern guards allow one to write more specific patterns that involve expressions.  Guards can either be Boolean conditions or patterns.  For example,

```
case val of
| just(x) when x > 0 -> x
| _ -> 42
end
```
is an example of a Boolean guard, where the first pattern will only match when the expression `x > 0` evaluates to `true`.

An example of a pattern guard is
```
case name of
| just(n) when lookupBy(stringEq, n, top.env) matches just(ty) -> ty
| _ -> errorType()
end
```
Here the first pattern only matches when the value of the expression `lookupBy(...)` matches the pattern `just(ty)`.

## TODO

This page needs expanding and many of the old notes are now out of date.

  * Looks-through-forwards
  * Decoration
  * Noting the types that can be matched on (int,string,list, any nonterminal type) and the syntax
  * mention GADTs?

