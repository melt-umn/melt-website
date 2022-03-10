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

Because Silver is used to write extensible languages where new productions can be added and we allow matching on the productions of a nonterminal type, we want to be able to handle new productions with existing pattern matches.
For example, if we have a `case` expression matching on the known productions `p1()` and `p2()` and an extension adds a production `p3()`, we still want the `case` expression to give a result when given a tree built by `p3()` rather than an error for not finding a match.
To do this, we try matching each clause in order.
For each pattern, we try to match the tree against the pattern as it is.
If this does not succeed and the tree forwards, we try to match the pattern against the forward.
We only move to the next clause when the match fails and the tree being matched does not forward.
We maintain behavior similar to pattern matching in functional languages even as we add this new behavior.
For example, the `case` expression
```
case x of
| p1 -> e1
| p2 -> e2
| p3 -> e3
end
```
is equivalent to
```
case x of
| p1 -> e1
| _ -> case x of
       | p2 -> e2
       | _ -> case x of
              | p3 -> e3
              end
       end
end
```
and adding a match rule to the end of a `case` expression does not affect earlier matches found.

Let us look at how matching through forwarding works.
Suppose we have the following production:
```
abstract production d
top::Nonterminal ::= x::Nonterminal
{ forwards to a(x); }
```
The result of the following pattern matching will be `0` because we have an exact match in the first clause in the form of the pattern `d(_)`:
```
case d(c()) of
| d(_) -> 0
| a(_) -> 1
| b(_, _) -> 2
| c() -> 3
end
```
Suppose we remove the `d(_)` pattern.
We try to match `d(c())` against the `a(_)` pattern, but it does not match.
We then forward to `a(c())` and try matching this pattern again, which succeeds, giving a result of `1`:
```
case d(c()) of
| a(_) -> 1
| b(_, _) -> 2
| c() -> 3
end
```

If we rearrange the rules in this last `case` expression, we get the same result:
```
case d(c()) of
| b(_, _) -> 2
| a(_) -> 1
| c() -> 3
end
```
Matching `d(c())` against `b(_, _)` fails, so we forward and try again.
Matching `a(c())` against `b(_, _)` also fails, and `a` does not forward so matching the pattern fails.
We then move on to the next pattern and try matching `d(c())` against it.
When matching `d(c())` against `a(_)` fails, we forward to `a(c())` and find a match.

Suppose we rearrange the order of patterns from the case expression above with the `d(_)` pattern, placing it at the end of the match instead of the beginning:
```
case d(c()) of
| a(_) -> 1
| b(_, _) -> 2
| c() -> 3
| d(_) -> 0
end
```
We will *not* get the same result in this case, since we take the first pattern which matches.
We try to match `d(c())` against `a(_)`, which succeeds after forwarding, and the result is `1` rather than `0` as before.

The relative order of patterns for forwarding and non-forwarding productions is relevant for which pattern matches.
In this example, the `d(_)` pattern will never be reached because any trees built by the `d` production will match the `a(_)` pattern.
This has the same effect as placing a more general pattern before a more specific pattern in non-forwarding pattern matching.
To match a forwarding production, place it at the beginning of the clauses.
It does not cause a compile-time error to place it later, but it is unlikely the resulting semantics are the intended ones.

Matching through forwarding occurs on a production basis, not a pattern basis, meaning we only forward to try to match a production pattern constructor if we could not match that constructor already, not if that constructor was matched but its children did not match the subpatterns.
To see what we mean by this, suppose we have the following production:
```
abstract production foo
top::Nt ::= c::Integer
{
  forwards to if c == 1 then foo(0) else bar(c);
}
```
We try to match against the `foo` production with this `case` expression:
```
case foo(1) of
| foo(0) -> -1
| foo(a) -> a
| _ -> 0
end
```
We try to match the `foo` pattern constructor of the first rule, which succeeds, then try to match the `0` pattern, which fails.
We do not try forwarding `foo(1)` at this point to see if it will become `foo(0)`, instead moving on to the next match rule which succeeds.

There is no clearly correct decision between forwarding per production and forwarding per pattern.
The current implementation strategy for `case` expressions leaves no choice, but alternative implementation strategies are possible and could be used in the future.
One should not rely on this behavior since it may change; however, the only cases where it becomes relevant are the cases where a production which may forward to itself is used as a pattern with structured subpatterns, and most users will not encounter this situation.

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

