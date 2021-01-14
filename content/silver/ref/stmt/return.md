---
title: Return
weight: 40.0
---

Be sure to see [function](/silver/ref/decl/functions/) declarations.

```
function stringEq
Boolean ::= s1::String  s2::String
{
  return s1 == s2;
}
```

## Semantics

Each function should have exactly one `return` statement within its body, with the usual meaning.
