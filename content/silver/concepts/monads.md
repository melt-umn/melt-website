---
title: Monads
weight: 1100
---

Silver (finally) supports a limited form of monads, most notably for IO.  
A monad is just a monoid in the category of endofunctors (what's the problem?), but since that definition is *really* helpful, I'll break it down here briefly.

A monad is, fundamentally, just an *action* of some sort, which also somehow wraps a *value*.  Monads can be constructed and combined through the use of combinators.  The two most important ones that make something a monad are *bind* and *pure*.  pure simply wraps a provided value to create a monad object that does nothing.  bind takes a monad object and a function from a value to a monad object, and somehow evaluates or 'runs' the first monad object, extracts the value, then calls the function with that value to construct a second monad object.  This second object is then evaluated, and the value and is then returned.  The purpose of this is to allow two monad actions to be sequenced (somehow), and the value results of each monad action to be able to be used in the next action.  Note that I said 'somehow'.  The specifics of this can be quite complex and depends on each monad.  

## Maybe
The simplest example of a monad that Silver supports is for Maybe.  pure simply wraps the value in a just, and bind simply allows a computation to be performed with the value of another maybe action, contingent on that action's success.  

## Lists
Lists are somewhat similar, where pure simply wraps the value in a single-element list.  bind maps the provided function over all elements in the first list, so it acts as sort of a 'nested for each' construct, compared to a 'nested if' provided by Maybe

## State
State is a bit different, in that it has its own type, compared with the maybe and list monads, which work on existing types.  State is essentially a pair of a value and some form of 'state' value that gets passed around that tracks things in the computations.  bind sequences two state actions, passing the value of the first as the parameter to the second, and threading the state value from one to the next.  In addition, there are provided functions 'getState', which extracts the current state value and returns it as the monadic value, and setState, which takes a new state value with which to replace the current state value.  

State is actually represented as a nonterminal, with pureState, pureState, getState, and setState as the constructors. The evaluation happens by threading the state value through the tree in a synthesized and inherited attribute, and the monadic value is returned as another synthesized attribute.  In order to actually run the computation involving state, functions runState or evalState can be called which provide the input attributes and then return the results. 

## IO
IO can be thought of as essentially similar to the State monad, except that instead of threading a value which can be accessed by the user, an 'IO token' is threaded.  This is further described in the reference on the [old IO system](/silver/concepts/io/).  The basic constructors for IO actions are productions that run the basic IO functions as represented in the library.  

One issue with this is that the result of an IO action occurring isn't the only side effect possible.  Running a computation takes time, so it would be important to be able to force a specific ordering of evaluation to occur.  Sometimes demanding the IO token from an action could cause other computation values to be demanded before demanding the input IO token.  To avoid this issue, when the IO token or value out is demanded from a bindIO node, the IO token is demanded from the left child via unsafeTrace to force the IO actions to be performed before any intensive computations that would occur before the IO token out from the right child could be performed.  

## Do notation
Expressing complex monadic computations in terms of `bind`, `pure` and lambda expressions can become tedious and hard to read.
Silver supports syntactic sugar for this in the form of [do-notation](/silver/ref/expr/do).

## TODO
I'm not including the documentation for specific functions here, yet.  This seems like it should be generated?  
