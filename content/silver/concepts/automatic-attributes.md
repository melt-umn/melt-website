---
title: Automatic attributes
weight: 600
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
propagate attr1, attr2, ... on NT1, NT2, ... excluding prod1, prod2, ...;
```
This will generate propagating aspect productions for all but the listed productions.

We generally do not wish to propagate on forwarding productions as doing so would often be interfering, and the host language does not know about all forwarding productions anyway.  However if one does in fact wish to propagate on forwarding productions as well, they can simply add explicit propagate statements for each of these productions.

In some cases some non-forwarding propagate statements may not be exported by the definition of the nonterminal, such as with closed nonterminals or optioned grammars.  In these cases explicit propagate statements are required as well, however these will be caught by the flow analysis.

Note that global propagate is only permitted when the attribute should be propagated for all productions; attempting to also write an explicit equation will result in a duplicate equation flow error.  This is not a particularly severe restriction, as requiring that a global propagate means that the attribute is indeed propagated for all productions will result in more maintainable specifications.
