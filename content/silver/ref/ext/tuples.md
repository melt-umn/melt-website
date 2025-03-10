---
title: Tuples
weight: 300
---

{{< toc >}}

```
local attribute symbolDef :: (String, Integer);
symbolDef = ("a", 3);
```

Tuples in Silver are characterized by parentheses, with individual elements delimited by a comma "`,`". They can contain an arbitrary number of elements, and while the elements of a tuple can be of any type (and need not all be of the same type), the number of elements in any given tuple is fixed. For example, a tuple of type `(Boolean, String, Integer)` **cannot** become a tuple of type `(Boolean, String)` or `(String, Boolean, String, Integer)`.

The tuple type is written `(a, b, ..., n)`, where `a`, `b`, and `n` are all types, for any finite number of types. Similarly, tuples are constructed with `(c, d, ..., m)`, where `c`, `d`, and `m` are tuple elements, for any finite number of elements.

> _**Example:**_
```
local attribute priorityError :: (Integer, String, String);
priorityError = (3, "Too high!", "Too low!");
```

## Selector Syntax

Individual tuple elements may be accessed using the tuple selector syntax, which utilizes a dot "`.`" operator following the tuple expression and the position of the element we would like to access expressed as an integer constant. Tuple access indices begin at 1.

> _**Example:**_
```
if priorityError.1 > 2
  then print("Error: " ++ priorityError.2, ioin)
else 
  if priorityError.1 < 1
    then print("Error: " ++ priorityError.3, ioin)
  else print("No serious errors.", ioin);
```

Here, `priorityError.1 = 3`, `priorityError.2 = "Too high!"`, and `priorityError.3 = "Too low!"`.

## Pattern Matching

Silver supports pattern matching on tuples. Wildcards "`_`" may be used in place of the tuple itself, or in place of individual tuple elements, as follows:

> _**Example:**_
```
case tuple of
  | ("zero", "zero", "one") -> "one"
  | (_, "one", "zero") -> "I arbitrarily don't like this input"
  | ("zero", "one", "one") -> "three"
  | _ -> "I don't like this either." 
  end;
```

## Inductive Implementation

Tuples are implemented inductively using the construction of ordered pairs, e.g. we forward a tuple `(a, b, c, d)` to `Pair<a Pair<b Pair<c d>>>`. This means that the following examples are equivalent:

```
("I", ("am", "a", (5, "tuple"))) = ("I", "am", "a", 5, "tuple")
```

And these both represent the following construction of nested pairs

```
pair(fst="I", snd=pair(fst="am", snd=pair(fst="a", snd=pair(fst=5, snd="tuple"))))
```

In contrast, the 3-tuple

```
(("I'm", "not"), ("a", 5), "tuple")
```

represents

```
pair(fst=pair(fst="I'm", snd="not"), snd=pair(fst=pair(fst="a", snd=5), snd="tuple"))
```

### Consequences for element access

Because tuples forward to nested pairs, elements may also be accessed using the `fst` and `snd` annotations that occur on `Pair`, although this syntax may be less immediately intuitive. For example, the `priorityError` tuple defined above would have the following element accesses via `fst` and `snd` annotations:

```
priorityError.fst = 3
priorityError.snd = ("Too high!", "Too low!")
priorityError.snd.fst = "Too high!"
priorityError.snd.snd = "Too low!"
```

The tuple selector syntax described above is thus recommended for tuples with more than 2 elements. 

## See also

* [Pair](/silver/lib/pair/)

Up to date information about this data structure can be found in _`extension/tuple`_.