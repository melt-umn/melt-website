---
title: Pattern matching
weight: 300
---

{{< toc >}}

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

## Matching Through Forwarding

Because Silver is an extensible language and we allow matching on the productions of a nonterminal type, we want to be able to handle new productions with old pattern matches.
To do this, if we do not find a match initially, we take the forward of the term we are matching on and try again.

For example, suppose we have the following production:
```
abstract production d
top::Nonterminal ::= x::Nonterminal
{ forwards to a(x); }
```
The result of the following pattern matching will be `4` because we have an exact match in the form of the pattern `d(_)`:
```
case d(c()) of
| a(_) -> 1
| b(_, _) -> 2
| c() -> 3
| d(_) -> 4
end
```
However, if we do not have the `d(_)` pattern, we do not have an exact match.
When we do not get a match for `d(c())`, we forward to `a(c())` and try again, matching the first pattern and giving a result of `1`:
```
case d(c()) of
| a(_) -> 1
| b(_, _) -> 2
| c() -> 3
end
```

## Completeness Analysis

Pattern matching includes a completeness analysis which checks that all possible values are covered by some pattern.
If there is a value which is not covered by the patterns, the analysis will give an example pattern which is not covered, similar to how OCaml checks completeness.
Incomplete pattern matching gives warnings by default rather than errors.
To turn these warnings into errors, use the `--mwda` flag with Silver.

These are the rules for completeness of matching on different types:
* A match on a nonterminal type is complete if all the non-forwarding productions are included in the patterns (because all other productions must eventually forward to these) or if there is a variable pattern.
* A match on a closed nonterminal is complete only if there is a variable pattern.
* A match on a list is complete if nil and cons are included and the heads and tails of cons are complete or if there is a variable pattern.
* A match on Booleans is complete if both true and false are included or if there is a variable pattern.
* A match on strings, integers, or floats is complete if there is a variable pattern.

## TODO

This page needs expanding and many of the old notes are now out of date.

  * Decoration
  * Noting the types that can be matched on (int,string,list, any nonterminal type) and the syntax
  * mention GADTs?

