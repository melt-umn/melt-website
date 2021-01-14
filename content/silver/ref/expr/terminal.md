---
title: Terminal expressions
weight: 800
---

{{< toc >}}

Quick examples:

```
-- earlier:
terminal Identifier /[A-Za-z]/;

abstract production foo
e::Expr ::= f::'foo'
{
  -- each of these lines does the same thing:
  forwards to id(terminal(Identifier, "foo")); -- except here line & column are -1
  forwards to id(terminal(Identifier, "foo", f));
  forwards to id(terminal(Identifier, "foo", f.line, f.column));
}
```

## Terminals

The `terminal` special form of expression is the constructor for terminals:

<pre>
terminal ( <i>Terminal type</i>, <i>lexeme expression</i>, <i>Location expression</i> )
terminal ( <i>Terminal type</i>, <i>lexeme expression</i> )
</pre>

The first "parameter" is the type of the terminal to create.
The second parameter is the lexeme of the terminal to create.
Silver makes no restriction that the lexeme must match the regular expression the terminal was declared with.

In the second form, bogus values for a location will be invented.

## Easy terminal extension

Terminals declared using single quotes, rather than a regular expression, may be constructed quickly in the same manner.

That is, instead of `terminal(For_kwd, "for")` one can write `'for'`.

## Terminal attributes

There are two special terminal attributes:

<pre>
<i>expression</i> . lexeme
<i>expression</i> . location
</pre>

The `lexeme` is the string matched, and `location` is the `Location` the string was matched from.

