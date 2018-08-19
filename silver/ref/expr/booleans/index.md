---
layout: sv_wiki
title: Boolean expressions
menu_title: Boolean
menu_weight: 20
---

* Contents
{:toc}

Quick examples:

```
if first.isJust then first else second

c && (!a || !b) == c && !(a && b)
```

## Booleans and `if`

`true` and `false` (all lower case) are the values of type `Boolean`.
`if` expressions have the following form:

<pre>
if <i>expression</i> then <i>expression</i> else <i>expression</i>
</pre>

The condition must be of type `Boolean`.
There is no implicit conversion to `Boolean` from, for example, `Integer`.
The types of the `then` and `else` branches must be the same.

Every `if` must have an `else` branch, there is no `if-then`.
The `else` branch will extend as far as possible.

> _**Example:**_ To clarify by what "as far as possible" means, the following code:
```
 if condition
 then foo
 else bar ++ if condition2
             then foo2
             else bar2 ++ more
```
> will parse as
```
 if (condition)
 then (foo)
 else (bar ++ if (condition2)
              then (foo2)
              else (bar2 ++ more))
```

## Logical operators

The standard C-style boolean operators are present:

<pre>
<i>expression</i> && <i>expression</i>
<i>expression</i> || <i>expression</i>
!<i>expression</i>
</pre>

These operators DO short-circuit evaluation.

Again, the operands must be of type `Boolean`, there are no implicit conversions.
The not operator binds more tightly than the and operator, which binds more tightly than the or operator, as you would expect.

## Comparison operators

All comparison operators bind more tightly than logical operators and produce `Boolean` values.

The following comparison operators work on types `Integer`, `Float`, and `String`:

<pre>
<i>expression</i> < <i>expression</i>
<i>expression</i> <= <i>expression</i>
<i>expression</i> > <i>expression</i>
<i>expression</i> >= <i>expression</i>
<i>expression</i> == <i>expression</i>
<i>expression</i> != <i>expression</i>
</pre>

String comparison is lexicographical, and does pay attention to case.
Equality and inequality will also work with `Boolean`s, but the other comparison operators will not.

