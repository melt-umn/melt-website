---
layout: sv_wiki
title: Interference
menu_weight: 700
---

* Contents
{:toc}

Interference is a subtle problem for extensible languages.
Unlike the [modular well-definedness analysis](/silver/concepts/modular-well-definedness/) for attribute grammars and the [modular determinism analysis](/silver/concepts/determinism/) for concrete syntax, interference doesn't have a simple description.

The other problems are more obvious: for the MWDA, we can see how an equation for a new attribute could be missing for someone else's new production.
For the MDA, we've got enough painful experience with LR parser construction errors to believe that just any new syntax will get along with each other.

But interference is more subtle.
We get a successfully composed compiler with multiple language extensions.
It runs successfully and produces output.
We didn't get any errors.

But it didn't do what it was supposed to do.

## Semantics

To achieve non-interference, we have a simple enough goal: we want to reason about the behavior of our code (the host language, each extension) in isolation.
And we want to be not-wrong about that reasoning, even when we compose together unknown other extensions.

In a sense, don't just want to be able to compose our code, we want to know we could compose our proofs of that code's correctness (if we had them).
And that sounds hard.

Fortunately, there's actually remarkably simple rules that can prevent interference.

## The Silver approach to non-interference

Note this approach is not always followed in Silver code.
Other approaches to non-interference may be possible.
But this is the worked out approach we have right now.

### Rule 1

For any tree `t` and any attribute `s`, we must ensure that:

```
t.s = t.forward.s
```

We'll poke small exceptions to this rule in a bit.
But to start with, this means you should never (assume you are allowed to) override an attribute in a forwarding production.

Anyplace we see a forwarding production _with an attribute equation_ we should be suspicious:

```
abstract production implies
top::Expr ::= l::Expr  r::Expr
{
  top.eval = !l.eval || r.eval; -- Give this line of code the stare it deserves
  
  forwards to or(not(l), r);
}
```

### Rule 2

Host language designers should introduce "error productions."
If attributes have to be equal, we're screwed with error messages right?
We can never write an error about our extension?
Well, no.
Not if the host language can have arbitrary errors.

```
abstract production complicated
top::Expr ::= l::MyExtension
{
  forwards to
    if null(l.error)
    then l.translation
    else errorExpr(l.errors); -- Look, any old errors, no problem! :)
}
```

### Rule 3

Certain attributes, like `typerep` or `defs`, (higher-order attributes, aka tree-valued attributes) can be "equalish" instead of exactly strictly equal.
Basically, we're trying to consider a forwarding production to be equal to the tree it forwards to.
So maybe instead of strict equality, we can have:

```
t.s.host = t.host.s
```

This obviously only works when we're comparing trees, so it doesn't help us with strings or error messages or other basic data structures.
But this means our extension _expression_ can have an equation for `typerep` reporting an extension _type_... that ultimately forwards to the same type we'd get from the expression the extension forwards to.

### Rule 4

There's a more general rule, but this one is 99.99% just: `pp` is special.
Feel free to make your pretty-print accurate in an extension.

To see why, read the published paper.
But long story short: because we don't deeply care about `pp` except in exactly one way, which is `t.pp.parse.host = t.host`.
For every other attribute about a production, the properties we might infer from that attribute's value are unpredictable.

### Rule 5

Pattern matching is the same as attribute access, so a simple rule of thumb is just never match on forwarding productions, use an attribute instead, which should follow the above rules.

### Summary

That's it!
If you'd like to see how this could possibly be enough to suddenly do modular and composable proofs of properties, [you want to read the paper](https://www-users.cs.umn.edu/~evw/pubs/kaminski17sle/index.html) or the [Ph.D. thesis](https://www-users.cs.umn.edu/~kami0054/papers/kaminski-phd.pdf).

