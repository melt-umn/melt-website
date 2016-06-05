---
layout: sv_wiki
title: ableC
menu_title: ableC
menu_weight: 60.0
---

# ableC: Attribute grammar-Based Language Extensions for C

We have nearly completed an implementation of C, at the C11 standard,
in Silver.  This is used as a *host language* in our work on
extensible langauges.  To date we've developed a number of language
extensions.  These include extensions for

+ algebraic data types, with pattern matching
+ regular expressions, with matching
+ an extensions that combines these two to allow reguar expressions to
  be used as as patterns when mathcing on strings as part of an
  algebraic data type.
+ matrix features from MATLAB and a `matlab` function construct that
  generates the boilerplate FFI types and code for calling such
  functions from MATLAB.
+ term rewriting, inspired by the TOM system and Kiama
+ closures / lambda-expressions
+ parts of HALIDE, a DSL for high performance image processing

These all pass the modular determinism analysis in Copper and the
modular well-definedness analysis in Silver.

The ableC specification can be found  on
[GitHub](https://github.com/melt-umn/ableC). 
 

