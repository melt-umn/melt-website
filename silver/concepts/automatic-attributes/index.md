---
layout: sv_wiki
title: Automatic attributes
menu_weight: 600
---

# Overview
Some repetitive idioms exist in AG specifications that we would like to avoid writting boilerplate for by hand.
These attributes fall into various common patterns (functor, monoid, etc.)
As a first step, we add an extension to Silver such that in production bodies we can write
```
propagate attr1, attr2, ...;
```
This statement is overloaded for different kinds of attributes, forwarding to the appropriate equations on the production.


# Functor attributes
Functor attributes allow for a mapping-style transformation over a tree, where we only wish to modify the tree in a few
places.
Thus the type of a functor attribute is effectively in the functor category, being a nonterminal that in some way encapsulates values that we wish to modify.
Functor transformations are distinct from forwarding, as these transformed trees are not necessarily semantically equivalent to the original tree. Also more than one functor transformation of the same tree is possible, while a production may only have one forward.

```
functor attribute host;

nonterminal Stmt;

attribute host occurs on Stmt;

abstract production nullStmt
top::Stmt ::=
{
  propagate host;
}
abstract production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  propagate host;
}
abstract production errorStmt
top::Stmt ::= msg::[Message]
{
  propagate host;
}
abstract production injectGlobalDeclsStmt
top::Stmt ::= lifted::Decls
{
  top.host = nullStmt();
  top.globalDecls = lifted.decls;
}
```

An example functor transformation is `host` in ableC, which transforms away ``injection'' productions by lifting declarations to higher points in the tree.
This translates to the following equivalent specification:

```
synthesized attribute host<a>::a;

nonterminal Stmt;

attribute host<Stmt> occurs on Stmt;

abstract production nullStmt
top::Stmt ::=
{
  top.host = nullStmt();
}
abstract production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  top.host = seqStmt(s1.host, s2.host);
}
abstract production errorStmt
top::Stmt ::= msg::[Message]
{
  top.host = errorStmt(msg);
}
abstract production injectGlobalDeclsStmt
top::Stmt ::= lifted::Decls
{
  top.host = nullStmt();
  top.globalDecls = lifted.decls;
}
```

A functor attribute is implemented as just an ordinary synthesized attribute whose type is the same as the type of the nonterminal on which it occurs.  To enable this, a functor attribute forwards to an ordinary synthesized attribute with a type parameter `a`.
Functor attributes provide an overload for attribute occurrence such that `occurs on` for a functor attribute with no type argument provided will forward to will forward to an attribute occurrence with the nonterminal provided as the type argument.

`propagate` is overloaded for functor attributes such that propagating a functor attribute will result in an equation that constructs the same production with the result of accessing the attribute on all children.
Any children on which the attribute does not occur are simply used unchanged in the new tree.

# Monoid attributes
Monoid attributes allow for collections of values to be assembled and passed up the tree.
The type of a monoid attribute must be in the monoid category, having an empty value and append operator (e.g. `[]` and `++` for lists.)

```
monoid attribute errors::[Message] with [], ++;

nonterminal Stmt;

attribute errors occurs on Stmt;

abstract production nullStmt
top::Stmt ::=
{
  propagate errors;
}
abstract production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  propagate errors;
}
abstract production errorStmt
top::Stmt ::= msg::[Message]
{
  top.errors := msg;
}
abstract production ifStmt
top::Stmt ::= c::Expr  t::Stmt  e::Stmt
{
  propagate errors;
  top.errors <-
    if c.typerep.isScalarType then []
    else [err(c.location, "If condition must be scalar type")];
}
```

An example monoid attribute is `errors` in ableC.  This translates to the following equivalent specification:

```
synthesized attribute errors::[Message] with ++;

nonterminal Stmt;

attribute errors occurs on Stmt;

abstract production nullStmt
top::Stmt ::=
{
  top.errors := [];
}
abstract production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  top.errors := s1.errors ++ s2.errors;
}
abstract production errorStmt
top::Stmt ::= msg::[Message]
{
  top.errors := msg;
}
abstract production ifStmt
top::Stmt ::= c::Expr  t::Stmt  e::Stmt
{
  top.errors := c.errors ++ t.errors ++ e.errors;
  top.errors <-
    if c.typerep.isScalarType then []
    else [err(c.location, "If condition must be scalar type")];
}
```

Monoid attributes become [collection attributes](../collections) with the same append operator.
This means that non-propagated equations must use `:=` instead of `=`, and additional values can be contributed besides the propagated equation using the `<-` operator.

When propagated on a production with no children on which the attribute occurs, the empty value is used.
Otherwise, the append operator is used to combine the value of the attribute on all children with the attribute.

# Global propagate
In some cases we wish to propagate an attribute on all productions of a nonterminal with no exceptions.  Instead of adding `propagate` statements (and potentially aspects) for all productions, we can instead write
```
propagate attr1, attr2, ... on NT1, NT2, ...;
```
This generates an [aspect production](../aspects) for all known non-forwarding productions of these nonterminals.
Each of these aspect productions will contain `propagate attr1, attr2, ...;` in its body.

Sometimes one may wish to propagate on *almost* all productions of a nonterminal, but don't want to write `propagate` on all but a few production bodies.
This can be avoided by instead writing 
```
propagate attr1, attr2, ... on NT1, NT2, ... except prod1, prod2, ...;
```
This will generate propagating aspect productions for all but the listed productions.

We generally do not wish to propagate on forwarding productions as doing so would often be interfering, and the host language does not know about all forwarding productions anyway.  However if one does in fact wish to propagate on forwarding productions as well, they can simply add explicit propagate statements for each of these productions.

In some cases some non-forwarding propagate statements may not be exported by the definition of the nonterminal, such as with closed nonterminals or optioned grammars.  In these cases explicit propagate statements are required as well, however these will be caught by the flow analysis.

Note that global propagate is only permitted when the attribute should be propagated for all productions; attempting to also write an explicit equation will result in a duplicate equation flow error.  This is not a particularly severe restriction, as requiring that a global propagate means that the attribute is indeed propagated for all productions will result in more maintainable specifications.


# Strategy attributes
Functor attributes allow for a limited notion of rewriting on a tree.  However, this only permits single-pass operations where changes are made throughout the tree without decorating intermediate results.  This makes it difficult to express iterative transformations (such as expression evaluation) with only functor attributes.

Strategy attributes are a sort of generalization of functor attributes.  Instead of a single simultaneous pass, they work incrementally, with the traversal order specified by a "strategy expression" DSL based on term rewriting systems such as Stratego.
Application of a strategy attribute can succeed or fail; the type of a strategy attribute on a nonterminal of type `a` is `Maybe<a>`, rather than `a` with functor attributes.
Generally a strategy attribute should be globally propagated for all productions and not defined directly.  If desired the attribute can be manually propagated to preserve forwarding productions.

The following is an example strategy attribute for performing the optimization `x + 0 -> x`:

```
strategy attribute elimPlusZero =
  topDown(
    try(
      rule on Expr of
      | addExpr(x, intConst(0)) -> x
      end));
attribute elimPlusZero occurs on Stmt, Expr;
propagate elimPlusZero on Stmt, Expr;

function simplifyStmt
Stmt ::= s::Stmt
{
  return
    case s.elimPlusZero of
    | just(s1) -> s1
    | nothing() -> error("Should always succeed")
    end;
}
```

This forwards to the following:

```
strategy attribute elimPlusZero =
  rec s ->
    (rule on Expr of
     | addExpr(x, constExpr(0)) -> x
     end <+ id) <*
   all(s);
     
-- Optimization: s == elimPlusZero
strategy attribute elimPlusZero =
  (rule on Expr of
    | addExpr(x, constExpr(0)) -> x
    end <+ id) <*
  all(elimPlusZero);

attribute elimPlusZero occurs on Stmt, Expr;
   
aspect production addExpr
top::Expr ::= e1::Expr e2::Expr
{
  propagate elimPlusZero;
}
aspect production constExpr
top::Expr ::= i::Integer
{
  propagate elimPlusZero;
}

aspect production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  propagate elimPlusZero;
}
aspect production assignStmt
top::Stmt ::= n::Name e::Expr
{
  propagate elimPlusZero;
}
```

Basic strategy expressions are rules, `rec` for recursive strategies, `fail`, `id`, `<*` (sequence), `<+` (choice), `all`, `some`, and `one`.
Synthesized attributes can be used as literals in a strategy expression.  These are usually the names of other strategy attributes, but in principle any attribute of type `Maybe` can occur here.
Strategy constructors such as `topDown` and `try` are "extensions" that forward to basic strategy combinators.

Since the `rec` occurs at the top level of the definition, as an optimization we can simply replace `s` with `elimPlusZero` and eliminate the `rec`.  Otherwise the `rec` body would need to be lifted out as a separate strategy attribute.

The global `propagate` on  generates an aspect production for all known `Stmt` and `Expr` productions.  For this example we only examine 4 representative productions.

The definition, occurrence and propagation of the strategy forward to the following:

```
synthesized attribute elimPlusZero<a>::Maybe<a>;
strategy attribute elimPlusZero_cont = all(elimPlusZero);

attribute elimPlusZero<Stmt> occurs on Stmt
attribute elimPlusZero<Expr> occurs on Expr;
attribute elimPlusZero_cont occurs on Stmt, Expr;
   
aspect production addExpr
top::Expr ::= e1::Expr e2::Expr
{
  top.elimPlusZero =
    bindMaybe( -- <*
      orElse( -- <+
        case e1, e2 of -- rule
        | x, constExpr(0) -> just(x)
        | _, _ -> nothing()
        end,
        just(top)), -- id
      \ res::Expr -> decorate res with {env = top.env}.all_elimPlusZero);
  propagate elimPlusZero_cont;
}
aspect production constExpr
top::Expr ::= i::Integer
{
  -- Optimization: left operand to <* is effectively id for this production
  top.elimPlusZero = top.all_elimPlusZero;
  propagate elimPlusZero_cont;
}

aspect production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  -- Optimization: left operand to <* is effectively id for this production
  top.elimPlusZero = top.all_elimPlusZero;
  propagate elimPlusZero_cont;
}
aspect production assignStmt
top::Stmt ::= n::Name e::Expr
{
  -- Optimization: left operand to <* is effectively id for this production
  top.elimPlusZero = top.all_elimPlusZero;
  propagate elimPlusZero_cont;
}
```

Here in the definition of the `elimPlusZero` strategy, the right side of the sequence operator is lifted out as a "continuation" strategy attribute `elimPlusZero_cont`, to be computed on any successful result of applying the left side.

The `occurs on` declaration forwards to the following 3 lines.  `elimPlusZero` is provided with the nonterminal type as the type parameter for each nonterminal, and the `elimPlusZero_cont` continuation attribute automatically occurs on the same nonterminals.

The translation of the strategy's body can be seen in the translation of propagating `elimPlusZero` on `addExpr`: the sequence operator becomes a monadic operation using `bindMaybe`, the choice operator becomes a call to `orElse`, `id` becomes `just(top)`.

The rule is translated by statically analyzing the outermost pattern.  Since this matches on `addExpr`, the rule becomes a pattern match of each of the child patterns on each of the children, failing if all clauses fail.  If all patterns in a rule clause match, the right side rule expression is evaluated and wrapped in `just`.

When the left side of the sequence succeeds, we decorate the result with all known inherited attributes on the nonterminal and access the continuation.  In reality only the attribute's flow type is required, but this is done to avoid requiring the results of the flow analysis for translation.  The MWDA guarantees that all inherited attributes that are dependencies of an attribute will be visible at the attribute's definition site.

On the other productions, we can statically determine that the rule does not match.  This means that the choice becomes equivalent to `id`, and thus the sequence becomes equivalent to its right side.  As an optimization, we can avoid the monadic bind and just compute the continuation attribute on the current tree.
Propagating a strategy attribute on a production will also automatically propagate any of its lifted continuation strategy attributes.

Expanding the forwarding of `elimPlusZero_cont`, we get
````
synthesized attribute elimPlusZero<a>::Maybe<a>;
synthesized attribute elimPlusZero_cont<a>::Maybe<a>;

attribute elimPlusZero<Stmt> occurs on Stmt
attribute elimPlusZero<Expr> occurs on Expr;
attribute elimPlusZero_cont<Stmt> occurs on Stmt
attribute elimPlusZero_cont<Expr> occurs on Expr;
   
aspect production addExpr
top::Expr ::= e1::Expr e2::Expr
{
  top.elimPlusZero =
    bindMaybe( -- <*
      orElse( -- <+
        case e1, e2 of -- rule
        | x, constExpr(0) -> just(x)
        | _, _ -> nothing()
        end,
        just(top)), -- id()
      \ res::Expr -> decorate res with {env = top.env}.all_elimPlusZero);
  top.elimPlusZero_cont =
    case e1.elimPlusZero, e2.elimPlusZero of -- all(elimPlusZero)
    | just(res1), just(res2) -> addExpr(res1, res2)
    | _ -> nothing()
    end;
}
aspect production constExpr
top::Expr ::= i::Integer
{
  top.elimPlusZero = top.all_elimPlusZero;
  top.elimPlusZero_cont = just(i); -- all(elimPlusZero)
}

aspect production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  top.elimPlusZero = top.all_elimPlusZero;
  top.elimPlusZero_cont =
    case s1.elimPlusZero, s2.elimPlusZero of -- all(elimPlusZero)
    | just(res1), just(res2) -> seqStmt(res1, res2)
    | _ -> nothing()
    end;
}
aspect production assignStmt
top::Stmt ::= n::Name e::Expr
{
  top.elimPlusZero = top.all_elimPlusZero;
  top.elimPlusZero_cont =
    case e.elimPlusZero of -- all(elimPlusZero)
    | just(eRes) -> seqStmt(n, eRes)
    | _ -> nothing()
    end;
}
```

`all` is basically a monadic version of propagating an ordinary functor attribute.  For all children on which the attribute occurs it is accessed, and if all succeed the results are used in reconstructing the same production.
Note that the argument of the `all` combinator must be the name of a strategy attribute, otherwise the argument will be lifted as a separate strategy attribute.

## Applications of strategy attributes
*Remove this in the final version of this page*

* Strategy attributes would be a more elegant solution to the rewriting done by the Halide extension, as it would properly handle forwarding extension productions.
* The template extension is probably still better off with the reflection-based version of rewriting. This could be done with attributes like before but would require explicit `propagate` on all extension productions.
* We should compare performance between both versions for lambda calculus example.
* Language extensions for compile-time expression evaluation or optimizations?
* Anything we currently do with forwarding that might have a cleaner solution with strategy attributes?
* Any other classic term rewriting problems?

