---
title: AbleC
weight: -70
---

AbleC is an implementation of C, at the C11 standard, using Silver.
This is used as a *host language* in our work on extensible languages.

See our OOPSLA 2017 paper: [Reliable and Automatic Composition of Language Extensions to C: The ableC Extensible Language Framework](http://www-users.cs.umn.edu/~evw/pubs/kaminski17oopsla/index.html).

To date we've developed a number of language extensions.
These include extensions for:

* Algebraic data types, with pattern matching
* SQLite, with type-checked queries
* Cilk, for task-based parallel programming
* Regular expressions, with matching
* An extension that combines these two to allow regular expressions to be used as patterns when matching on strings as part of an algebraic data type
* Matrix features from MATLAB and a `matlab` function construct that generates the boilerplate FFI types and code for calling such functions from MATLAB
* Term rewriting, inspired by the TOM system and Kiama
* Closures / lambda-expressions
* A partial demo of HALIDE-like extensions, a DSL for high performance matrix processing

These all pass the modular determinism analysis in Copper and the modular well-definedness analysis in Silver.

To get started with ableC, look [here](/ableC/getting-started/).

