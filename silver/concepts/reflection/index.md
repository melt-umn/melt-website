---
layout: sv_wiki
title: Reflection & Term Rewriting
menu_weight: 600
---

# Reflection
Some operations that we would like to perform on trees in Silver are not possible to express nicely with attributes, or doing so requires a large amount of boilerplate - for example, serializing and de-serializing terms, or performing template-style substitutions.  The reflection library provides a solution to this, by providing an alternative uniform representation of terms with the `AST` nonterminal, defined as
```
nonterminal AST;
abstract production nonterminalAST
top::AST ::= prodName::String children::ASTs annotations::NamedASTs

abstract production terminalAST
top::AST ::= terminalName::String lexeme::String location::Location

abstract production listAST
top::AST ::= vals::ASTs

abstract production stringAST
top::AST ::= s::String

abstract production integerAST
top::AST ::= i::Integer

abstract production floatAST
top::AST ::= f::Float

abstract production booleanAST
top::AST ::= b::Boolean

abstract production anyAST
top::AST ::= x::a

nonterminal ASTs;
abstract production consAST
top::ASTs ::= h::AST t::ASTs

abstract production nilAST
top::ASTs ::=

nonterminal NamedASTs;
abstract production consNamedAST
top::NamedASTs ::= h::NamedAST t::NamedASTs

abstract production nilNamedAST
top::NamedASTs ::=

nonterminal NamedAST;
abstract production namedAST
top::NamedAST ::= n::String v::AST
```

Two functions allow arbitrary values to be transformed to and from the `AST` representation:
* `reflect :: (AST ::= a)` converts an arbitrary value to an `AST`; values that have no such representation (e.g. functions and `Decorated` references) are wrapped in `anyAST`.
* `reify :: (Either<String a> ::= AST)` converts an `AST` back to either an ordinary value or an error message if the `AST` is not well-sorted.

Users may define new attributes on the `AST` type, rather than on all concerned nonterminals.  For example a generalized pretty-printing operation is defined (see [`silver:langutil:reflect`](https://github.com/melt-umn/silver/blob/develop/grammars/silver/langutil/reflect/AST.sv)) as
```
attribute pp occurs on AST;
aspect production nonterminalAST
top::AST ::= prodName::String children::ASTs annotations::NamedASTs
{ top.pp = cat(text(prodName),
    parens(ppImplode(pp", ", children.pps ++ annotations.pps)));
}
aspect production listAST
top::AST ::= vals::ASTs
{ top.pp = brackets(ppImplode(pp", ", vals.pps)); }

aspect production stringAST
top::AST ::= s::String
{ top.pp = pp"\"${text(escapeString(s))}\""; }

aspect production integerAST
top::AST ::= i::Integer
{ top.pp = text(toString(i)); }

aspect production floatAST
top::AST ::= f::Float
{ top.pp = text(toString(f)); }

attribute pps occurs on ASTs;
aspect production consAST
top::ASTs ::= h::AST t::ASTs
{ top.pps = h.pp :: t.pps; }

aspect production nilAST
top::ASTs ::=
{ top.pps = []; }

...
```

Other applications of rewriting are
* [In Silver's serialization library](https://github.com/melt-umn/silver/tree/develop/grammars/silver/reflect), used internally by the Silver compiler for handling interface files;
* [In Silver's meta-translation library](https://github.com/melt-umn/silver/blob/develop/grammars/silver/metatranslation/Translation.sv), used to support extensions to Silver that provide object-language concrete syntax for tree construction;
* [A demo staged language interpreter](https://github.com/melt-umn/meta-ocaml-lite)

# Term rewriting
Another significant use of reflection is in implementing a Stratego-style strategic term rewriting library/language extension that works on undecorated terms.  Note that Silver also supports a mechanism for rewriting on decorated trees ([strategy attributes](../strategy-attributes)) that is generally preferred, as it is more efficient and better integrated with other features such as attributes and forwarding; however there are still some situations in which term rewriting is preferred, such as [in implementing template instantiation](https://github.com/melt-umn/ableC-templating).

## Core library
Strategies are represented by the `Strategy` type, and are built by a number of combinators.  The main ones are as follows:
* `id :: (Strategy ::= )`
* `fail :: (Strategy ::= )`
* `sequence :: (Strategy ::= Strategy Strategy)`
* `choice :: (Strategy ::= Strategy Strategy)`
* `all :: (Strategy ::= Strategy)`
* `some :: (Strategy ::= Strategy)`
* `one :: (Strategy ::= Strategy)`
* `traveral :: (Strategy ::= prodName::String childStrategies::[Strategy] annoStrategies::[Pair<String Strategy>])` (congruence traversal)
* `rewriteRule :: (Strategy ::= pattern::ASTPattern result::ASTExpr)`

Rewrite rule strategies are constructed by the `rewriteRule` constructor, parameterized by an `ASTPattern` and an `ASTExpr` - run-time representations of patterns and expressions.  For example, an strategy defining an innermost optimization of `x + 0 -> x` could be defined as
```haskell
global elimPlusZero::Strategy =
  sequence(
    all(elimPlusZero),
    choice(
      -- addExpr(a, intExpr(0)) -> a
      rewriteRule(
        prodCallASTPattern(
          "myLang:addExpr",
          consASTPattern(
            varASTPattern("a"),
            consASTPattern(
              prodCallASTPattern(
                "myLang:intExpr",
                consASTPattern(
                  intASTPattern(0),
                  nilASTPattern())),
              nilASTPattern()))),
         varASTExpr("a")),
      id()));
```

## Extension features
The above system is implemented purely as a Silver library using the reflection mechanism; however defining strategies in this way is highly inconvenient.  For this reason a corresponding collection of language extensions to Silver provide new syntax that makes using the library less painful.

One such extension provides new infix operators `<*` and `<+` for sequence and left-choice, respectively.  These are used in implementing a number of generally-useful utility strategies in the library; some of the more commonly used ones include
```
abstract production try
top::Strategy ::= s::Strategy
{ forwards to s <+ id(); }

abstract production repeat
top::Strategy ::= s::Strategy
{ forwards to try(s <* repeat(s)); }

abstract production bottomUp
top::Strategy ::= s::Strategy
{ forwards to all(bottomUp(s)) <* s; }

abstract production allTopDown
top::Strategy ::= s::Strategy
{ forwards to s <+ all(allTopDown(s)); }

abstract production innermost
top::Strategy ::= s::Strategy
{ forwards to bottomUp(try(s <* innermost(s))); }
```
* `try` applies its operand strategy, and always succeeds.
* `repeat` applies its operand repeatedly until failure, and succeeds with the last successful result.
* `bottomUp` applies its operand to each subterm starting from the leaf terms, and fails if any applications fail.
* `allTopDown` applies its operand to each subterm starting from the root term, stopping in a subterm when its argument succeeds.  This is roughly analagous to a [functor transformation](../automatic-attributes).
* `innermost` repeatedly applies its operand to the innermost, leftmost expression in a term, only moving up the tree once all sub-terms are fully reduced.

A new expression `rewriteWith(strategy, term)` provided by the extension applies a strategy to a term.

New syntax is provided for defining rewrite rules, based on the existing syntax for [pattern matching](../../ref/expr/pattern-matching).  Using this the `x + 0 -> x` strategy could be specified as
```
global elimPlusZero::Strategy = bottomUp(try(
  rule on Expr of
  | addExpr(a, intExpr(0)) -> a
  end));
```
Note that rewrite rules defined using this syntax are statically to be type-preserving, meaning that no run-time errors will result from performing an invalid rewrite.

More convenient syntax for congruence traversals is also provided: `traverse addExpr(id(), simplify)` succeeds only when applied to the `addExpr` production, and applies the identity strategy to the left operand, and the `simplify` strategy to the right operand.  The `traverse` syntax also checks that the production is applied to the proper number of arguments.

An example implementation of the lambda calculus using term rewriting can be found [here](https://github.com/melt-umn/lambda-calculus/blob/develop/grammars/edu.umn.cs.melt.lambdacalc/term_rewriting/Eval.sv).

# Further reading
More information on reflection, term rewriting, and its applications in Silver can be found in our COLA paper [Reflection of Terms in Attribute Grammars: Design and Applications]().
