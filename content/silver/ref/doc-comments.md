---
title: Doc-Comments
weight: 10.0
---

{{< toc >}}

## Using/Placing Doc-Comments

Documentation use the bracketed (`{- this is a comment -}`) style comment syntax, with a leading `@`. They can precede any toplevel declaration in a file, may stand alone at the toplevel of a file unassociated with a declaration (use two `@`s for this), or can precede a declaration inside a `class` or `instance` declaration.

```
@{- This doc-comment is attached to the function add. -}
function add
Integer ::= a::Integer b::Integer
{
  return a + b;
}

@@{- This doc comment is not attached to any item, and stands alone at the grammar scope. -}

@{- This doc comment is attached to the typeclass defn below. -}
class SomeTypeclass f {
  @{- This doc comment is attached to the member foo below.  -}
  foo :: (f ::= f); 
}

```

Doc comments may not appear within definitions (regular comments may still.)

By default, all of the documentation for a grammar will be emitted to a single markdown file. This instead be configured to split some or all of the files in the grammar into their own documentation page. Doc comment behavior may configured by using [directives inside comments](#config-directives).

Grammars with no docs will not be emitted at all, and at this time this prevents their children from being shown. A good workaround is to add `@@{- @config excludeGrammar false -}` to some file in the grammar if nothing else.

## Running the documentation generation step and viewing doc statistics

Passing the following commands to the silver compiler controls doc comment behaviour:

 - `--doc` enables generating markdown from doc-comments and grammars
 - `--count-undoc` prints statistics on documentation coverage for compiled grammars
 - `--print-undoc` does as `--count-undoc`, but also prints a complete list of undocumented items in compiled grammars
 - `--doc-out` selects the location for markdown emission with `--doc`
 - `--clean` is useful to make sure that all included grammars are compiled (grammars not considered to need recompilation will not have docs generated)

Unless one of `--doc`, `--count-undoc`, or `--print-undoc` is passed, doc comments will not be parsed at all. NOTE that if they aren't parsed, no warnings will be emitted about incorrect doc syntax. You should probably clear out the `doc` folder before running the compiler to make sure no stale docs are kept.

## Doc-Comment mini-language

Doc comment mini language is designed to look somewhat alike to javadoc, while not requiring strict formatting adherence and working like markdown. Newlines are ignored, unless the line is completely blank, in which case it is a paragraph break (like Markdown.) Leading `/ *\-* */` is stripped from lines (so e.g. bullets are possible, but must start with ` - - Bullet item` for a single level bullet.) Markdown formatting (e.g. `*bold*`) is ignored and passed through.

Block directives (e.g. `@param foo Some docs about parameter foo`) go at the beginning of the line, and start their own paragraphs as well, even without a padding line. Some directives take parameters before the start of the docs for that block, and some (`@return`) don't. Blocks without a leading directive are 'normal.' Blocks are sorted into a total order, and param blocks are reordered to match the order of arguments (warnings are issued for non-matching params.)

Other directives (e.g. `@link[name]`) go inline and are used to create intra-docs links. `@@` will emit a verbatim `@`.

A thorough example, demonstrating most features:

```
@{-
  -
  - See also @link[sub], which is implemented in terms of this function.
  - 
  - @param a the first number to add
  - @param b the second number to add
  - @return the value of a + b (possibly plus bias)
  - @prodattr bias a list of integers, the sum of which is added to every addition
  - @warning NOTE: see the bias prod attr. An extension may have changed the behavior
  -          of addition.
  - 
  - Here is some discussion of why it is a good idea to allow extensible addition:
  - - It was a good idea at the time
  - - And now the java translation depends on it
  -}
function add
Integer ::= a::Integer b::Integer
{
  production attribute bias::[Integer] with ++;
  bias := [];

  return a + b + foldl((\x::Integer y::Integer -> x + y), 0, bias);
}
```

This translates to approximately (styling for param/etc blocks removed) the following markdown:

```
## `function add` (`Integer ::= a::Integer b::Integer `)

**WARNING!**: NOTE: see the bias prod attr. An extension may have changed the behavior of addition.

**Parameter `a`**: the first number to add

**Parameter `b`**: the second number to add

**Production Attribute `bias`**: a list of integers, the sum of which is added to every addition

**Return**: the value of a + b (possibly plus bias)

See also sub at doctest:split/Second.sv#8, which is implemented in terms of this function.

Here is some discussion of why it is a good idea to allow extensible addition:
- It was a good idea at the time
- And now the java translation depends on it
```

### Blocks

 - `@param name text...` and `@child name text...` are identical, taking the name of the parameter/child they document, and a line of text about it. For productions and functions, having more than zero of these blocks will cause the compiler to check that you have one for each argument, and that their names and orders match that of the documented item.
 - `@return text...` takes no argument, documenting the return behavior of the function.
 - `@prodattr name text...` takes the name of a production attribute, and documents it's effect/behavior.
 - `@warning text...` takes no argument, and documents a known gotcha.
 - `@forward text...` takes no argument, and documents the forwarding behaviour.
 - `@config name [value]` takes at least a name, and then optionally a value (`@config name` is the same as `@config name true`). A comment consisting only of config directives is not shown. See below for a complete listing of config directives.
 - `@hide` is equivalent to `@config hide true` which causes the comment and it's attached item not to be shown. This essentially marks it as not needing documentation, since it will no longer count as undocumented, but will not appear in the docs.

### Config directives

Some config directives configure the behavior of the grammar, and some configure the behaviour of the file (overriding the grammar behavior.) The behavior of conflicting directives is not defined (different settings at the grammar/file scope is NOT conflicting: file wins.)

Config options take booleans (`true`/`false`/`on`/`off`/`yes`/`no`), integers (`1`, `12`, ...) or strings (`"something"`, ...). Passing no argument is equivalent to passing `true` (and so is an error for those not taking booleans.)

 - `@config split <boolean>` configures if the grammar-level default is to lump all files docs together, or to split them apart. Default false.
 - `@config fileSplit <boolean>` can override the above behavior on a per-file basis, allowing a few files to have their own docs page, or for most to have their own and a few to have their docs on the main grammar page. Default false.
 - `@config noToc <boolean>` is a per-file setting that when true disables the default table of contents header for the file. A ToC is always emitted for the grammar-level file. Useful if you want to have a standalone prose-documentation file. Default false.
 - `@config weight <integer>` sets the menu ordering weight for the file (i.e. where it appears in a list of sibling split files in this grammar.) Only relevant if the file is split out.Higher value means lower in the table(?). Default 0.
 - `@config grammarWeight <integer>` sets the menu ordering weight for the grammar's entry (i.e. where it appears in a list of sibling grammars) . Higher value means lower in the table(?). Default 0.
 - `@config title <string>` sets the title of the file. Only relevant when it is split out. Default: filename without `.sv`.
 - `@config grammarTitle <string>` sets the title of the entire grammar. Default: `[grammar:name]`.
 - `@config excludeFile <boolean>` if true, do not emit any docs from this file. Default false.
 - `@config excludeGrammar <boolean>` if true, do not emit any docs (or a docs folder) for this grammar. Default false.
 - `@config hide <boolean>` if true, do not emit this doc comment or the item it's attached to. Default false. Shorthand: `@hide`.