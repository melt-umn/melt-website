---
title: Function and production invocation
weight: 200
---

{{< toc >}}

Quick examples:

```
append([1,2], [3,4])
fromMaybe(1, just(2))
cons(1, cons(2, nil()))
```

## Syntax

Functions and productions are invoked with identical syntax, which is similar to C/Java's (i.e. uncurried):

<pre>
<i>expression</i> ( <i>expressions...</i> )
</pre>

> _**Example:**_ invoking the _`substring`_ function, with three arguments.
```
substring(1, 5, "/path/file")
```
> _**Example:**_ passing _`foo`_ as a parameter to either _`a`_ or _`b`_, depending on the value of _`cond`_.
```
(if cond then a else b)(foo)
```
> _**Example:**_ constructing trees (given suitable productions _`add`_ and _`mul`_):
```
mul(add(1,2), 3)
```

Note that _production_ application necessarily produces the undecorated type of the nonterminal it constructs.
(See [Decorated vs Undecorated](/silver/concepts/decorated-vs-undecorated/) for more on the distinction between decorated and undecorated.)

## Partial Application

Missing arguments replaced by underscores will result in a partially-applied function.

```
map(add(3,_), [1,2])  =  [add(3,1), add(3,2)]
fun(_,_)  =  fun
```

Arguments supplied in a partial application are only evaluated once, so any expensive computation will be reused by the other applications of the same resulting function value.

## Annotations

Annotations are supplied to a production as named parameters after the ordered parameters.

```
add(l.ast, r.ast, location=this.location)
```

Named annotation parameters can also be converted to ordered parameters in a partial application:
```
add(_, _, location=_)
```
