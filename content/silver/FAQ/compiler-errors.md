---
title: Compiler Errors
---

{{< toc >}}

## `error: duplicate equation for attribute _a_`

There are two (or more) definitions for the value of the attribute _a_ on the same production.
Both definitions should emit this error message, so you should be able to the other one (especially if it's in an aspect in another grammar).

If the attribute is a collection, perhaps the intention is for one equation to change from `:=` to `<-` (see more about [collections](/silver/concept/collections)).

