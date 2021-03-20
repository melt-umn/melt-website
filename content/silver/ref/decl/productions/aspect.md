---
title: Aspect production declarations
weight: 200
---

{{< toc >}}

Quick examples:

```
aspect production plus
top::Expr ::= l::Expr  r::Expr
{
  top.newattr = foo(l.newattr, r.newattr);
}
```

See also [documentation on aspects in general](/silver/concepts/aspects/).

## Syntax

Aspects are permitted to skip children in their signature using an underscore (`_`), but must otherwise repeat the type of each child, as a basic sanity check (and local documentation).
The names of the RHS children and LHS can differ from the original production declaration.

```
aspect production plus
top::Expr ::= _ _
{
  top.isLiteral = false;
}
```

## Semantics

Aspects permit attribute equations to be written separately from wherever the production was originally defined.
They do this by mimicking the declaration of the original production, able to choose its own names for children and LHS, reducing coupling to the original declaration.

Redefinition of attributes is not permitted.
Aspects are only meant to give equations for newly declared attribute occurrences.

