---
title: Concrete production declarations
weight: 100
---

{{< toc >}}

Quick examples:

```
concrete production plus
e::Expr ::= e1::Expr  '+'  e2::Expr
{
}
```

## Syntax

A 'concrete' production is identical to an [abstract production](/silver/ref/decl/productions/abstract), except that it will be sent to the parser generator, if a parser is declared that includes the grammar the production is defined in.

Concrete productions also have restrictions on the types of children, only terminals and nonterminals are allowed (and those nonterminals must have concrete productions).

## Declaring many productions

Syntax can be declared is a somewhat more natural way using `concrete productions` (note the plural.)

```
concrete productions  e::Expr
| e1::Expr '+' e2::Expr   { e.ast = ast:plus(e1.ast, e2.ast); }
| 'if' e1::Expr 
  'then' e2::Expr
  'else' e3::Expr
    { e.ast = ast:ifthen(e1.ast, e2.ast, e3.ast); }
(named_production) | 'whatever'   { ... }
```

This allows a dramatically more succinct description of concrete syntax. Names of these productions are auto-generated as they're typically unnecessary, but if they are needed, the third case above shows how they can be provided.

## Easy terminal extension

The easy terminal extension allows [terminals declared using single quotes](/silver/ref/decl/terminals/) to be referred to by those same single quotes, instead of by name.

This is already shown in the example above with e.g. `'+'` and `'if'`.

## Concrete syntax modifiers

There are a few additional pieces of information that may be attached to concrete productions:

### Production precedence

Reduce/reduce conflicts _may_ be resolved by specifying the relative precedence of productions (emphasis on may, as this might not be the best way to resolve reduce/reduce conflicts, some refactoring of the grammar may be preferable.)

```
concrete production something
s::Stmt ::= 'some' 'syntax'
precedence = 10
{
}
```

_TODO: get a better example. Might be hard to find a good example because this is usually a poor choice, but a real world one is preferable!_

### Production operator

Terminal operator precedence works by inferring the operator to use for a production: the last operator terminal in the signature. This is then compared to the input terminal to decide between shift and reduce.

Although this is nearly always correct (or reasonable), sometimes it is not. It can be amended by declaring the terminal which should be used as it's operator for ambiguity resolution purposes, even if that terminal is not one that appears in the signature.

```
concrete production arrow
e::Expr ::= e1::Expr '-' '>' e2::Expr
operator = Arrow_t
{
}
```

### Copper action blocks

Productions can be associated with an action to perform when that production is reduced (which occurs after all children have been reduced.)

```
concrete production typedef
d::Decl ::= 'typedef' t::Type ids::Identifiers ';'
{
}
action {
  typenames = (decorate ids with {}).names ++ typenames;
}
```

It is possible to examine the children of the production, but only the undecorated forms are available for use.  Autodecoration behavior is not present in action blocks. (Thus, the explicit decorate in the above code.)

### Layout

To control the [layout](/concepts/layout) on a specific production, an explicit set of terminals can be supplied:

```
concrete production parameterizedString
e::Expr ::= 's' '"' s::StringBody '"'
layout {}
{
  ...
}
```

In this example, we've suppressed all layout for _this production only_, and so we'd presumably also want to [set the layout of the `StringBody` nonterminal](/silver/ref/decl/nonterminals#layout), too.


### Multiple production modifiers

Are separate with a comma, for example:

```
concrete production foo
e::Expr ::= Foo
operator = Bar, layout { Newline, Space }, precedence = 2
{
}
```
