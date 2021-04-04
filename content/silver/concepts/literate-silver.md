---
title: Literate Silver
weight: 150
---

In addition to normal `.sv` files, Silver code will also be found when written in `.sv.md` files.
These files are parsed as Markdown, and fenced code blocks with an info string of `silver` will be concatenated, with the result then being compiled.

For example, a file could contain:

~~~markdown
## Hello World Examples

We can see a comparison between the "Hello World" programs written in Silver and Forth.

```silver
function main 
IOVal<Integer> ::= args::[String] ioIn::IO
{
  return ioval(print("Hello, world!", ioIn), 0);
}
```

```forth
." Hello, world!"
```
~~~

Only the Silver code here would be compiled.

There's also no requirement that a code block lines up with Silver declarations:

~~~markdown
As we can see, the type signatures in Silver declarations are designed to look like EBNF rules.

```silver
function main 
IOVal<Integer> ::= args::[String] ioIn::IO
```

The bodies, on the other hand, look kinda sorta Javay -- this is probably fine for functions, but can be confusing in productions!

```silver
{
  return ioval(print("Hello, world!", ioIn), 0);
}
```
~~~
