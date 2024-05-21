---
title: Pair
weight: 300
---

> _**Note:**_
> Pair types and values can be expressed using tuple syntax as _`(Integer, String)`_ and _`(3, "OH NO!")`_; this is preferred over direct use of pairs in most cases.
> See the [tuples](/silver/ref/ext/tuples/) page for more information.

```
local attribute symbolDef :: Pair<String Integer>;
symbolDef = pair(fst="a", snd=3);
```

Pairs are also provided as a standard data structure in core.  Pairs are the
first data structure that is completely unspecial--that is, it's an ordinary nonterminal with no special language support.

The pair type is written _`Pair<a b>`_ where _`a`_ and _`b`_ are
types.

Pairs are constructed using the _`pair`_ constructor:

```
annotation fst<a>::a;
annotation snd<a>::a;
nonterminal Pair<a b> with fst<a>, snd<b>;
abstract production pair
top::Pair<a b> ::=
```

Here `fst` and `snd` are [_annotations_](/silver/ref/decl/annotations), meaning they must be supplied as named arguments to the constructor.

> _**Example:**_
```
local attribute priorityError :: Pair<Integer String>;
priorityError = pair(fst=3, snd="OH NO!");
```


The elements are accessed using the _`fst`_ and _`snd`_ annotations.

> _**Example:**_
```
if priorityError.fst > 2
then print("Error: " ++ priorityError.snd, ioin)
else print("No serious errors.", ioin)
```

Up to date information about this data structure can be found in _`core/Pair.sv`_.