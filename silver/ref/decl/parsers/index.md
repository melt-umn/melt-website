---
layout: sv_wiki
title: Parser function declarations
menu_weight: 900
---

* Contents
{:toc}

Quick examples:

```
parser parse :: Root {
  grammar:one;
  grammar:two;
  some:other:grammar;
}
```

## Syntax

Parser declarations have three parts: a name for the newly created parse function, the starting nonterminal, and a list of grammar to include in what's sent to the parser generator.

<pre>
parser <i>name</i> :: <i>start nonterminal</i>
{
  <i>grammars...</i>;
}
</pre>

## Semantics

The resulting parse function has type `(ParseResult<StartNT> ::= String String)`.
For example, the example parser at the top of this page has type `(ParseResult<Root> ::= String String)`.

The two parameters are (1) the string to actually parse and (2) the name of the "file" being parsed.
(e.g. This will appear in the `filename` attribute of terminal locations.)

`ParseResult` is a standary library data structure indicating either `parseSuccess` or `parseFailure` along with the errors or syntax tree result.

All concrete syntax in the listed grammars in included in what's sent to the parser generator, including those grammars they export.
Silver will use [Copper](/copper/) to construct an [LALR(1) parser](/silver/concepts/lr-parsing/).

## FAQ

### Can't I parse a file directly?

Not yet.

### How do I control the layout accepted before/after the root nonterminal?

Silver currently just makes all "ignore terminals" be the global layout that's expected before/after the starting nonterminal.
Eventually there will be syntax to control this for a parser, just like there is on productions.
But for now, that's the only option.

