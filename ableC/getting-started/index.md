---
layout: sv_wiki
title: Getting started
menu_title: Getting started
menu_weight: 60.0
---

# ableC: Attribute grammar-Based Language Extensions for C

ableC is an implementation of C, at the C11 standard,
using Silver.  This is used as a *host language* in our work on
extensible languages.  

See our OOPSLA 2017 paper: [Reliable and Automatic Composition of Language Extensions to C: The ableC Extensible Language Framework](http://www-users.cs.umn.edu/~evw/pubs/kaminski17oopsla/index.html).

To date we've developed a number of language extensions.  These
include extensions for

+ algebraic data types, with pattern matching
+ SQLite, with type-checked queries
+ Cilk, for task-based parallel programming
+ regular expressions, with matching
+ an extension that combines these two to allow regular expressions to
  be used as patterns when matching on strings as part of an
  algebraic data type
+ matrix features from MATLAB and a `matlab` function construct that
  generates the boilerplate FFI types and code for calling such
  functions from MATLAB
+ term rewriting, inspired by the TOM system and Kiama
+ closures / lambda-expressions
+ parts of HALIDE, a DSL for high performance matrix processing

These all pass the modular determinism analysis in Copper and the
modular well-definedness analysis in Silver.

The ableC specification can be downloaded
[here](/downloads). 
 

