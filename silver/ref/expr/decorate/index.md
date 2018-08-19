---
layout: sv_wiki
title: Decorate and new
menu_weight: 600
---

* Contents
{:toc}

Quick examples:

```
decorate expr with { env = emptyEnv(); }
decorate expr with {}
decorate expr with { inh = value; env = top.env; }
just(new(expr))
```

See [Decorated vs Undecorated](/silver/concepts/decorated-vs-undecorated/) for an explanation of what `Decorated` means.

## `decorate`

The following syntax will decorate an undecorated tree:

<pre>
decorate <i>expression</i> with { <i>inherited attribute</i> = <i>expression</i>; ... }
</pre>

The initial expression is expected to be undecorated.
Each inherited attribute should occur on the type of the initial expression.

> _**Example:**_
```
decorate expr with { env = [pair("x", 1), pair("y", 2)]; }
```
> will decorate an undecorated expression with an environment binding two variables.
```
decorate folder with { input = ["Hello", "world"]; }.output
```
> will decorate a value called _`folder`_ with the inherited attribute _`input`_, then demand the synthesized attribute _`output`_ from the resulting decorated node.


## `new`

`new` is the inverse operation of `decorate`.
It will take an explictly decorated valued (e.g. of type `Decorated Expr`) and produce the undecorate valued (e.g. of type `Expr`).

The following syntax will undecorate a decorated tree:

<pre>
new(<i>expression</i>)
</pre>

## Implicit coercion?

Any nonterminal-typed child of a production has both a decorated and undecorate value, and type inference will automatically select the appropriate one.
It's generally unnecessary to use these expressions on such a child, unless a different decoration of a child is required than the usual one happening in that production.
(In such cases, it's still likely you should use a `local` instead of `decorate`.)

Use of `decorate` and `new` generally only happens when doing slightly interesting things with `let` and pattern matching or tree-rewriting.
You will often be guided by type errors in such cases.
