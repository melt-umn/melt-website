---
title: Tree sharing
weight: 300
---

{{< toc >}}

Tree sharing permits the same [decorated tree](/silver/concepts/decorated-vs-undecorated) to be used in multiple places.  This permits inherited attributes to be supplied in one production and be used in another, without causing re-computation of attributes, or needing to specify the same equation more than once.

## Direct sharing
Consider a for loop extension in a simple imperative language:
```
production forLoop
top::Stmt ::= iVar::String lower::Expr upper::Expr body::Stmt
{
  top.errors = 
    checkInt(lower.type, "loop lower bound") ++
    checkInt(upper.type, "loop upper bound") ++
    lower.errors ++ upper.errors ++ body.errors;
  lower.env = top.env;
  upper.env = top.env;
  body.env  = addEnv(iVar, intType(), top.env);
  local upperVar::String = freshName(top.env);
  forwards to block(seq(
    decl(iVar, intType(), new(lower)),
    seq(decl(upperVar, intType(), new(upper)),
      while(intLt(var(iVar), var(upperVar)),
        seq(new(body), assign(iVar,
          intAdd(var(iVar), intConst(1))))))));
}
```
This for loop forwards to an equivalent while loop, but also wants to provide more precise error messages when the children have the wrong type.  To compute `type` and `errors`, we need to supply `env` to the children, prior to forwarding.  The children are un-decorated, and supplied with `env` again in the forward tree.  

![The tree produced by a nested for loop, without sharing](/silver/concepts/forLoop_not_shared.png)

This potentially causes attributes to be computed twice on the `lower`, `upper` and `body` trees. In some situations, this sort of issue can yield a blowup in runtime that is exponential in the level of nesting.  We also would like to avoid writing these `env` equations, as they mirror the attribute values that will be supplied in the forward tree.

The solution is to share a single decorated tree between each child of the `forLoop` production, and the forward tree. 

![The tree produced by a nested for loop, with sharing](/silver/concepts/forLoop_shared.png)

This can be achieved by replacing calls to `new` with the _tree sharing operator_ `@`:
```
production forLoop
top::Stmt ::= iVar::String lower::Expr upper::Expr body::Stmt
{
  top.errors = 
    checkInt(lower.type, "loop lower bound") ++
    checkInt(upper.type, "loop upper bound") ++
    lower.errors ++ upper.errors ++ body.errors;
  local upperVar::String = freshName(top.env);
  forwards to block(seq(
    decl(iVar, intType(), @lower),
    seq(decl(upperVar, intType(), @upper),
      while(intLt(var(iVar), var(upperVar)),
        seq(@body, assign(iVar,
          intAdd(var(iVar), intConst(1))))))));
}
```

This operator wraps a tree of type `Decorated nt with {}` to give an undecorated value of type `nt`.  When this result is subsequently decorated in some other position, the original tree is returned.  Any attributes explicitly supplied to the original tree take precedence over the places where the attribute was originally supplied.

### Modular well-definedness

#### Inherited completeness
Since the children of the `forLoop` production appear in fixed places in the forward tree, the [modular well-definedness analysis](/silver/concepts/modular-well-definedness) can determine that their `env` equations will be supplied by the forward tree, and thus these equations can be omitted.  The dependencies introduced by the remote productions enclosing the shared children in the forward are _projected_ by the analysis, to determine what dependencies ultimately exist on inherited attributes supplied to the forward tree.

#### Uniqueness
An important concern for the analysis is to ensure that no decoration site is shared more than once - this may result in multiple equations being supplied for the same inherited attribute; which equation is supplied first may depend on the order of evaluation, and may result in confusing non-deterministic behavior.  To enforce this, the analysis imposes several restrictions on how sharing can be used.  First, only child and local/production attribute trees can be shared, not references of an unknown origin.  Other sorts of trees, like the left side of the production or a pattern variable, may have equations supplied by other productions.  Sharing anonymously decorated trees (`decorate e with {env = ...;}`) is not currently supported.

Any use of sharing must also correspond to a known decoration site - that is, a forward or local equation, or an argument to a production application that is itself in a known decoration site.  Pattern match rules and then/else clauses of conditional expressions in known decoration sites are also acceptable.  However, a shared tree cannot be e.g. passed to an arbitrary function or placed in the environment, as we cannot track how it might subsequently be decorated and used.

Finally, there can only be at most one (non-mutually exclusive) sharing site for any shared decoration site.  For example, this would be an error:
```
production ifThen
top::Stmt ::= c::Expr body::Stmt
{
  local trans::Stmt = ifThenElse(@c, @body, nullStmt());
  forwards to
    case c of
    | trueLit() -> @body
    | _ -> @trans
    end;
}
```
However, this would be acceptable, since different pattern rules are mutually exclusive:
```
production ifThen
top::Stmt ::= c::Expr body::Stmt
{
  forwards to
    case c of
    | trueLit() -> @body
    | _ -> ifThenElse(@c, @body, nullStmt())
    end;
}
```

To avoid duplicate sharing in independent extensions, any sharing site must also be [exported by](/silver/concepts/modular-well-definedness) the decoration site.

#### Hidden transitive dependencies
There is also a a more subtle issue possible when an inherited equation is defined for a tree that is also shared.  For example, consider the host language while loop production:
```
flowtype errors {env} on Stmt, Expr;

production while
top::Stmt ::= c::Expr body::Stmt
{
  c.env = top.env;
  body.env = top.env;
  top.errors = c.errors ++ body.errors ++ checkBool(c.type, "loop condition");
}
```
Here the equation for `body.env` only depends on `top.env`.  But now consider if an extension production `foo` forwards to this loop with tree sharing, but overrides the `env` equation with one that depends on some other attribute `extraEnv`:
```
production foo
top::Stmt ::= s::Stmt
{
  s.env = top.extraEnv ++ top.env;
  forwards to while(..., @s);
}
```
When demanding `errors` on a `foo` tree, it will be computed via forwarding to `errors` in the `while` production, which in turn depends on `body.env`.  However the `env` equation in `foo` takes precedence over the one in `while`, resulting in a dependency on `extraEnv` - which exceeds the flow type for `errors`!

To prevent this sort of hidden transitive dependency from causing problems, the analysis requires that any inherited override equation on a shared tree cannot exceed the projected dependencies of the attribute on the tree in the remote production.

### Forward production attributes

A common pattern is to use [error productions](/silver/concepts/interference/#rule-2-use-error-productions) to avoid writing interfering synthesized override equations on forwarding productions.  For example with the for loop extension, we might want to write
```
production forLoop
top::Stmt ::= iVar::String lower::Expr upper::Expr body::Stmt
{
  local errs::[Message] = 
    checkInt(lower.type, "loop lower bound") ++
    checkInt(upper.type, "loop upper bound") ++
    lower.errors ++ upper.errors ++ body.errors;
  local upperVar::String = freshName(top.env);
  forwards to
    if !null(errs) then errorStmt(errs)
    else block(seq(
      decl(iVar, intType(), @lower),
      seq(decl(upperVar, intType(), @upper),
        while(intLt(var(iVar), var(upperVar)),
          seq(@body, assign(iVar,
            intAdd(var(iVar), intConst(1))))))));
}
```
However, there is now a problem as the children `lower`, `upper` and `body` are only conditionally being supplied with `env` through forwarding, meaning these equations are now reported as missing.  What we want is to unconditionally decorate the forward tree with inherited attributes, but then only conditionally actually forward to it.  This can be done using a _forward production attribute_ to decorate the tree with implicit copy equations for all inherited attributes:
```
production forLoop
top::Stmt ::= iVar::String lower::Expr upper::Expr body::Stmt
{
  local errs::[Message] = 
    checkInt(lower.type, "loop lower bound") ++
    checkInt(upper.type, "loop upper bound") ++
    lower.errors ++ upper.errors ++ body.errors;
  local upperVar::String = freshName(top.env);
  forward fwrd =
    block(seq(
      decl(iVar, intType(), @lower),
      seq(decl(upperVar, intType(), @upper),
        while(intLt(var(iVar), var(upperVar)),
          seq(@body, assign(iVar,
            intAdd(var(iVar), intConst(1))))))));
  forwards to
    if !null(errs) then errorStmt(errs)
    else @fwrd;
}
```

The hidden transitive dependencies issue can also happen when sharing a forward production attribute, as this essentially equates to defining override equations for all attributes:
```
production bar
top::Expr ::= e::Expr
{
  forward f = @e;
  forwards to baz(@e);
}
production baz
top::Expr ::= e::Expr
{
  e.env = [];
  ...
}
```
Here the implicit copy equation for `e.env` in `bar` exceeds the dependencies of the equation in `baz`, by depending on `top.env`.  Note that we don't even know about all inherited equations on `e` introduced by independent extensions, so it isn't even possible to check that forwarding to `baz(@e)` is safe.  Thus, the analysis forbids sharing a forward production attribute anywhere other than directly in a forward/forward production attribute equation.

### Translation attributes

Sometimes extensions introduce their own nonterminals in defining an embedded domain-specific language that is translated into host-language syntax.  When extension productions contain host-language trees, we would like to share these trees in the translation that is built across multiple productions; however sharing is not permitted in ordinary [higher-order attribute](/silver/concepts/decorated-vs-undecorated/#higher-order-undecorated) equations.  This is instead possible using _translation attributes_.

Consider a simple "condition tables" extension that provides more convenient notation for Boolean expressions;
this is a simplified version of the [ableC-condition-tables extension](https://github.com/melt-umn/ableC-condition-tables).
```
var res : bool = table { b1 && b3 : T F
                         ~ b2     : T *
                         b2 || b3 : F T };
```
A condition table expression is true if the true/false/don't care flags in any column match the truth values of the row expressions.  Thus a condition table expression translates into a series of let bindings for these expressions, with a translation of the table rows as the body:
```
var res : bool =
  let _v0 : bool = b1 && b3 in
  let _v1 : bool = ~b2 in
  let _v2 : bool = b2 || b3 in
    (_v0 && _v1 && ~_v2) || (~_v0 && _v2);
```

Table rows are represented by the `TRows` nonterminal, which contains the row expressions.  The conditions are passed down the tree by the `conds` attribute, which are then wrapped in the needed let bindings for the row expressions by the translation attribute `trans`.
```
production condTable
top::Expr ::= rows::TRows
{
  top.errors = rows.errors;
  rows.conds = [];
  forwards to @rows.trans;
}

nonterminal TRows with errors, conds, trans;
inherited attribute conds::[Expr];
translation attribute trans::Expr;

production consRow
top::TRows ::= e::Expr tf::TruthFlags rest::TRows
{
  top.errors = e.errors ++ tf.errors ++ rest.errors
    ++ checkBoolean(e.type, "row expression");

  local eVar::String = freshName(top.trans.env);
  tf.rowExpr = var(eVar);
  rest.conds =
    if null(top.conds) then tf.rowConds
    else zipWith(andOp, top.conds, tf.rowConds);
  top.trans = let_(eVar, @e, @rest.trans);
}
production nilRow
top::TRows ::=
{
  top.errors = [];
  top.trans = foldr1(orOp, top.conds);
}

nonterminal TruthFlags with errors, rowConds;
inherited attribute rowExpr::Expr;
synthesized attribute rowConds::[Expr];

...
```

Translation attributes are implicitly decorated as decoration sites, like a child or local/production attribute.  An instance of a translation attribute on a child or local (e.g. `rest.trans`) can be shared, and sharing can be used in a translation attribute equation.

![The tree produced by a condition table](/silver/concepts/cond_table.png)

If someone supplies a row expression of the wrong type, we would like to report these error messages directly, rather than getting the errors from the forward about a let binding having the wrong type.  To achieve this, the expressions are decorated with `env`, which flows down through the forward tree.  `errors` and `trans` are computed on the extension `TRows` tree, while any other host or extension attributes (such as `asm` computing an assembly translation) happen on the forward translation tree.

#### Modular well-definedness

Inherited attributes on translation attributes are treated more or less like regular inherited attributes in the flow analysis, and can appear in flow types.  For example, the flow type of `errors` on `TRows` is `{trans.env}`.  Only a single level of translation attributes is supported by the flow analysis, so `trans.foo.env` is not legal in a flow type. One can also write an override equation like `rows.trans.env = top.env;`, however this is not frequently useful in practice.  

To ensure uniqueness of sharing sites, an instance of a translation attribute on a child or local can only be shared in a grammar exported by the child/local, or the occurs-on declaration of the translation attribute.  Additionally for the translation attribute instance to be shared, the child/local cannot be shared directly.

The hidden transitive dependencies check for override equations on shared translation attribute instances is twofold: If there is an explicit inherited equation for `foo.trans.env`, then
* If `foo` is shared, the equation's dependencies cannot exceed the dependencies of `trans.env` on its sharing site.
* If `foo.trans` is shared, the equation's dependencies cannot exceed the dependencies of `env` on its sharing site.

## Dispatch sharing

