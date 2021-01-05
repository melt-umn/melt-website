---
title: Interference
weight: 700
---

{{< toc >}}


Interference is a subtle problem for extensible languages.
Unlike the [modular well-definedness analysis](/silver/concepts/modular-well-definedness/) for attribute grammars and the [modular determinism analysis](/silver/concepts/determinism/) for concrete syntax, interference doesn't have a simple description.


The other problems are more obvious: for the MWDA, we can see how an equation for a new attribute could be missing for someone else's new production.
For the MDA, we might have enough painful experience with LR parser generation errors to understand that our new extensions syntax could conflict with someone else's extension's syntax.


But interference is more subtle.
We get a successfully composed compiler with multiple language extensions.
It runs successfully and produces output.
We didn't get any reported errors.


_But it didn't do what it was supposed to do._


## Semantics


To achieve non-interference, we want to reason about the behavior of our code (the host language, and each extension) in isolation.
And we need that reasoning to be sound, even when we start to compose the language together with unknown other extensions.


In a sense, don't just want to be able to compose our code, we want to know we could compose proofs about our code (if we had them).
And that sounds hard.


But without that ability, we can't reason about our extension's behavior in the presence of other extensions.
And if we're unable to do that kind of reasoning, then two extensions may be able to interfere and misbehave.


Fortunately, there are remarkably simple rules that can prevent interference.


## The Silver approach to non-interference


First, some caveats: this approach is not always followed in Silver code.
Other approaches to non-interference may be possible.
But this is the worked out approach we have right now.


### Rule 1: suspicious equations


For any tree `t` and any attribute `s`, we must ensure that:

```
t.s = t.forward.s
```


We'll poke small exceptions to this rule in a bit.
But to start with, this means you should never (assume you are allowed to) put explicit equations in a forwarding production.


Anyplace we see a forwarding production _with an attribute equation_ we should be suspicious:


```
abstract production implies
top::Expr ::= l::Expr  r::Expr
{
  top.eval = !l.eval || r.eval; -- Give this line of code the stare it deserves
  
  forwards to or(not(l), r);
}
```


### Rule 2: use error productions


Host language designers should introduce "error productions."


If the previous rule means attributes must be equal, we're screwed with error messages right?
We can never write an error about our extension?
Well, no.
Not if the host language can have arbitrary errors.

```
abstract production complicated
top::Expr ::= l::MyExtension
{
  forwards to
    if null(l.errors)
    then l.translation
    else errorExpr(l.errors); -- Look, any old errors, no problem! :)
}
```


### Rule 3: safely varying attributes


Certain attributes, like `typerep` or `defs`, (higher-order attributes, aka tree-valued attributes) can be "equalish" instead of exactly strictly equal.


Here's one way of thinking about this: we want to consider a forwarding production to be "equal to" the tree it forwards to.
So if you override an equation on a forwarding production, but they ultimately come out to the "same thing" once forwarding is rewritten away... then no problem.


Instead of strict equality, we might insist on this:

```
t.s.host = t.host.s
```


This obviously only works when we're comparing tree types, so it doesn't help us with strings or error messages or other basic data structures.
But this means our extension _expression_ can have an equation for `typerep` reporting an extension _type_... that ultimately forwards to the same type we'd get from the expression the extension forwards to.


### Rule 4: "the pretty print exception"


There's a more general rule, but this one is 99.99% just: `pp` is special.
Feel free to make your pretty-print accurate in an extension.


To see why, read the published paper.
But long story short: because we don't deeply care about `pp` except in exactly one way, which is `t.pp.parse.host = t.host`.
For every other attribute about a production, the properties we might infer from that attribute's value are unpredictable.


### Patterns aren't exceptions


Pattern matching is semantically the same as attribute access, they can be transformed back and forth.
As a result, the same rules apply to patterns.
A simple rule of thumb is to just never match on forwarding productions.
In cases where you wanted to, use an attribute instead, which should follow the above rules.


### Restricted flow types


A relatively common case is for some attribute to have a more restricted flow type than the forwarding equation.
For instance,

```
flowtype Expr =
  labels {},
  forward {env};
```

This means many forwarding productions (those that actually use `env` in their forwarding equation) would be _required_ to give an equation for this `labels` attribute.
So obviously, these equations must be present.
However, often they have to compute exactly the same value as you would via forwarding.
Sometimes this is an obvious value (e.g. `[]`) but sometimes this could be an irritating, but necessary, bit of seeming duplication.


One possible source of confusion here is that you can evaluate `labels` on an undecorated `t`, so how can we check `t.labels == t.forward.labels` since we can't evaluate the forward equation without `env`?
But just because `labels` has a restricted flowtype doesn't mean `t` must _not_ have an `env`.
So this should hold under any environment, just like for any other attribute.


### Summary


There are no real restrictions on the host language (which is to say: on non-forwarding productions).
And an extension production will typically look something like this:

```
abstract production bridge
top::Expr ::= e::ExtensionAST
{
  -- The pretty print special case
  top.pp = s"whatever";
  
  -- Attributes with restricted flow types might have to appear here
  top.labels = [];
  
  -- An extension type that's consistent with our forward
  top.typerep = extensionType();
  
  -- Forward, using error productions
  forwards to
    if null(e.errors)
    then e.translation
    else errorExpr(e.errors);
}
```


That's it!
If you'd like to see how this could possibly be enough to suddenly do modular and composable proofs of properties, [you want to read the paper](https://www-users.cs.umn.edu/~evw/pubs/kaminski17sle/index.html) or the [Ph.D. thesis](https://www-users.cs.umn.edu/~kami0054/papers/kaminski-phd.pdf).


