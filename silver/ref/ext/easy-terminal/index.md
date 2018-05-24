---
layout: sv_wiki
title: Easy terminals
menu_weight: 100
---

* Contents
{:toc}

```
terminal Keyword 'keyword';

terminal Operator '*\`!@]#~[%$&^{*(';

concrete production foo
f::Nonterm ::= 'keyword' {}

foo('keyword')
```

## Syntax

"Easy terminals" make writing terminals that are not regular expressions (i.e. are just strings that use no special regex features) slightly easier, by allowing them to be written with single quotes instead of slashes.

The single quotes **do not** permit any escaping. That is, backslash has no special meaning. It is just a backslash. This also means _there is no way to write a single quote_ within an easy terminal. (Single quotes can always, of course, be written as a normal regular expression: `/'/`.)

## See also

  * [easy terminal in terminal declarations](/silver/ref/decl/terminals/)
  * [easy terminal in production declarations](/silver/ref/decl/productions/)
  * [easy terminal in expressions](/silver/ref/expr/terminal/) (as terminal literals)
