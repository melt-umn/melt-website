---
title: Strategy attributes
weight: 600
---

[Functor attributes](../strategy-attributes) and [forwarding](../../ref/stmt/forwarding) both allow for limited notions of rewriting on a tree.  However, neither approach is well suited to expressing complex (and potentially iterative) transformations, as such as performing optimizations.

[Reflection-based term rewriting](../reflection) in Silver allows for Stratego-style strategic term rewriting on undecorated terms.  While this is desirable in some cases, term rewriting does not allow the use of inherited attributes in rules, or respect forwarding.

*Tree rewriting* using *strategy attributes* provides an alternative.  In this approach rewrite rules and strategies are compiled into higher order attributes and equations, thus performing rewriting on decorated trees rather than undecorated terms.  This allows for natural integration with other attribute grammar features, such as accessing attributes on the tree being rewritten in rewrite rule expressions.

As an example, consider the task of performing optimizations on a [simple expression language](https://github.com/melt-umn/rewriting-optimization-demo) containing basic mathematical expressions for addition, subtraction, negation, variables, and let expressions containing sequences of declarations.

```haskell
partial strategy attribute optimizeStep =
    rule on Expr of
    | add(e, const(0)) -> e
    | add(const(0), e) -> e
    | add(const(a), const(b)) -> const(a + b)
    | sub(e1, e2) -> add(e1, neg(e2))
    | neg(neg(e)) -> e
    | neg(const(a)) -> const(-a)
    end
  occurs on Expr;

strategy attribute optimize = -- innermost(optimizeStep)
    all(optimize) <* ((optimizeStep <* optimize) <+ id)
  occurs on Expr, Decls;

propagate optimizeStep on Expr;
propagate optimize on Expr, Decls;
```

Strategy attributes are defined with a strategy expression that defines a transformation; basic strategy expressions are rules, references to other attributes, `fail`, `id`, `<*` (sequence), `<+` (choice), and `all`, `some`, `one` and congruence traversals.  Strategy attributes may be partial (meaning that they can fail, e.g. `optimizeStep`) or total (meaning that they cannot, e.g. `optimize`); note that we make no guarantees about termination for total strategies.

A number of utility strategy constructors such as `topDown`, `try` and `innermost` are extensions that forward to basic strategy combinators; for example `innermost(optimizeStep)` would forward to the strategy expression shown for `optimize`.

The global `propagate` generates an aspect production for all known `Stmt` and `Expr` productions with equations for the listed attributes, as with other [automatic attributes](../automatic-attributes).

## Using context
The main advantage of strategy attributes over undecorated term rewriting is that rewrite rules may access synthesized and inherited attributes on the matched trees in the rule, as the `<*` sequence operator implicitly decorates new terms created during rewriting with the same inherited attributes as the original trees.  For example, performing an optimization to inline let-binding declarations into the corresponding expression bodies, and eliminate unused declarations:
```haskell
partial strategy attribute inlineStep =
    rule on top::Expr of
    | var(n) when lookup(n, top.env) matches just(just(e)) -> e
    | letE(empty(), e) -> e
    end
    <+
    rule on top::Decls of
    | decl(id, e) when !contains(id, top.usedVars) -> empty()
    | seq(d, empty()) -> d
    | seq(empty(), d) -> d
    end
  occurs on Expr, Decls;
```
Here `env` on `Expr` is an inherited attribute with type `[Pair<String Maybe<Expr>>]`, containing an entry `pair(n, just(e))` for every let-variable `n` that should be replaced with an expression `e` (we may not wish to inline all bindings, e.g. ones containing computations that are used in multiple places.)  `usedVars` is an inherited attribute on `Decls` with type `[String]` containing a list of all free variables in the corresponding let expression body, which accordingly should not be deleted from the binding declarations.  These inherited attributes depend on additional synthesized attributes `defs` and `freeVars`, with the expected types.

Attribute dependencies between children of a production introduce complications in defining strategies, as the traversal order of the tree now also controls the order in which attributes are recomputed.  One might consider defining a strategy `optimizeInline` to perform the simplifying and inlining optimizations over a tree as
```haskell
strategy attribute optimizeInline = innermost(optimizeStep <+ inlineStep));
```
however this definition contains a subtle bug: as seen in the definition of `optimize`, `innermost` uses the `all` traversal combinator, which rewrites all children of the current decorated tree without recomputing attribute values using the new children before moving to the next child.  This means that the children of the `letE` let expression and `seq` declaration sequence productions may be rewritten with outdated inherited attribute values for `env` and `usedVars`, potentially causing some optimizations to be skipped (or now-unused declarations to not be eliminated.)

One alternative is to repeatedly re-decorate the entire tree between every successful optimization step:
```haskell
strategy attribute optimizeInline =
  repeat(onceBottomUp(optimizeStep <+ inlineStep));
```
While this approach will ensure that attribute values are up to date, it suffers from rather poor performance as re-decorating the entire tree (including unchanged portions) between every step will repeat many unnecessary computations and result in quadratic time complexity in the size of the program.

A better approach is to use congruence strategies to more precisely control the traversal and decoration of the tree:
```haskell
strategy attribute optimizeInline =
  ((seq(optimizeInline, id) <*
    seq(id, optimizeInline) <*
    seq(optimizeInline, id)) <+
   (letE(optimizeInline, id) <*
    letE(id, optimizeInline) <*
    letE(optimizeInline, id)) <+ all(optimizeInline)) <*
  (((optimizeStep <+ inlineStep) <* optimizeInline) <+ id);
```
This version of `optimizeInline` mirrors `innermost` except that we have special cases for the `seq` and `letE` productions.  When we see one of these productions, the strategy
1. Optimizes the left child (which can simplify some bindings and enable them to be inlined);
2. Optimizes the right child using the new `defs` from the left child (which can remove some variable references);
3. Optimizes the left child again using the new `usedVars` computed from the right child (and potentially eliminate some now-unused bindings.)

Generally one must exercise more care in defining tree rewriting strategies than with regular term rewriting, as this sort of attribute dependencies between children can introduce subtle bugs and performance problems.

## Applications of strategy attributes
A number of interesting uses of strategy attributes exist, including
* [The above-mentioned optimization example](https://github.com/melt-umn/rewriting-optimization-demo)
* [An implementation of the lambda calculus](https://github.com/melt-umn/lambda-calculus/blob/develop/grammars/edu.umn.cs.melt.lambdacalc/strategy_attributes/Eval.sv) based on examples from Stratego and Kiama
* [An implementation of regex matching via Brzozowski derivatives](https://github.com/melt-umn/rewriting-regex-matching)
* [Normalizing `for`-loops in the ableC-Halide extension](https://github.com/melt-umn/ableC-halide/blob/develop/grammars/edu.umn.cs.melt.exts.ableC.halide/abstractsyntax/IterStmt.sv)
* [In the implementation of strategy attributes](https://github.com/melt-umn/silver/blob/develop/grammars/silver/extension/strategyattr/StrategyExpr.sv) to perform pre-translation optimizations on strategy expressions

## Further reading
More information on strategy attributes and their applications can be found in our SLE paper [Strategic Tree Rewriting in Attribute Grammars](https://www-users.cs.umn.edu/~evw/pubs/kramer20sle).
