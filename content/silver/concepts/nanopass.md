---
title: Nanopass
weight: 150
---

{{< toc >}}

Silver supports a concept known as _nanopass attribute grammars_.
The idea is outlined in [this paper](https://www-users.cse.umn.edu/~evw/pubs/ringo23sle/index.html).
Essentially, a compiler can be specified as a series of transformations between incrementally different languages, where some nonterminals, productions and attributes may be be added or removed between passes. A language can thus be specified by adding or removing components from another language. 
Trees in different languages are distinguished by the type system as separate nonterminal types. 
Transformations can be automatically derived for productions that are not otherwise affected by a particular translation pass.

For a more complete example of a Silver specification utilizing nanopass features, see [Foil](https://github.com/melt-umn/foil).

## Specifying languages
Different nanopass languages correspond to grammars in Silver. Silver supports an `include` module statement, to permit defining a language as a modification of a previous language.
```
grammar edu:umn:cs:melt:foil:host:langs:ext;

imports edu:umn:cs:melt:foil:host:common;
imports edu:umn:cs:melt:foil:host:langs:core as core;

include edu:umn:cs:melt:foil:host:langs:core {
  close nonterminals GlobalDecl, Stmt, Expr, TypeExpr, Param, Type, ValueItem, TypeItem;
}
```
Here the `ext` language is defined as a modification of the `core` language, where some nonterminals are marked as closed,
meaning that new extension productions of these nonterminals do not need to forward, but new synthesized attributes must supply a default implementation. This is a useful pattern, as it permits extension constructs to specify their type and error checking behavior without needing to forward to a host-language tree, and introduce new sorts of types and definitions in doing so, while still eventually translating down to a core-language tree.


```
grammar edu:umn:cs:melt:foil:host:langs:l2;

imports edu:umn:cs:melt:foil:host:common;
imports edu:umn:cs:melt:foil:host:langs:l1;

include edu:umn:cs:melt:foil:host:langs:l1 {
  annotate attributes env, type, types, fields, expectedFields, nestLevel;
  exclude nonterminals Defs, Env, ValueItem, TypeItem, Type;
  exclude attributes defs, declaredEnv, isNumeric, typeExpr;

  -- Variable declarations are given an explicit type
  exclude productions autoVarDecl;
}
```
Here the language `l2` is defined based on `l1`, where some attributes are converted to annotations, holding the values that were computed in the previous pass.  This means that the value of the `l2:type` annotation will be an `l1:Type`, not `l2:Type`.  Some unused nonterminals, attributes and productions are also excluded. Excluding a nonterminal automatically excludes all productions and nonterminals of that type.

## Specifying passes
Translation passes between languages are defined as [translation attributes](/silver/concepts/tree-sharing#translation-attributes).
Special syntax is provided to define a translation attribute that occurs on all the nonterminals that are shared between two languages/grammars,
and generate equations for all productions that are not otherwise excluded:
```
translation pass toCore
  from edu:umn:cs:melt:foil:host:langs:ext
    to edu:umn:cs:melt:foil:host:langs:core
  excluding
    varGlobalDecl, fnGlobalDecl, structGlobalDecl, unionGlobalDecl;

aspect toCore on GlobalDecl of
| varGlobalDecl(d) -> core:appendGlobalDecl(@d.liftedDecls, core:varGlobalDecl(@d.toCore))
...
end;
```
