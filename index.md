---
layout: sv_wiki
title: MELT
---

# Minnesota Extensible Language Tools

## Research:

Our main research interests are in the declarative specification of programming languages semantics and transformations for optimization. We are specifically interested in techniques that lead to a high degree of modularity in the composition of language specifications. This is so that specifications for language features can be easily combined to create specifications for new languages. We are thus interested in tools that automatically compose and implement such specifications to create pre-processors, compilers and optimizers for the newly specified languages.

## Motivation:

Software development is a time-consuming and error-prone process that often results in unreliable and insecure software. At least part of the reason for these undesirable results is that large semantic gap between the programmer's high-level understanding of the problem and the relatively low-level programming language in which the problem solutions are encoded. Thus, programmers cannot "say what they mean" but must encode their ideas as programming idioms at a lower level of abstraction. This wastes time and is the source of many errors.

A long range goal is to improve the software development process and
the quality of the resulting software artifacts by reducing the
semantic gap. *Extensible languages* and *extensible compilers* provide a promising way to achieve this goal. These can easily be extended with the unique combination of domain-specific language features that raises the level of abstraction to that of the task at hand. The extended language provides the programmer with language constructs, optimizations, and static program analyses to significantly simplify the software development process.

## Tools and applications:

### [ableC](ableC/index.html): an extensible specification of C

(at the C11 standard)


### Silver: an extensible attribute grammar system

[Silver](silver) is our attribute grammar system.  The specifications
for ableC and its extensions are written in the Silver AG langauge.

Uniquely, Silver supports a modular analysis so that extension writers 
can use to certify that their extension will compose with other
independently-devlopled, and similarly certified, extensions to form a
well-defined attribute grammar.  Essentially, this ensures that the
composed attribute grammar will work.

### Copper: a context-aware scanner and parser generator

[Copper](copper/index.html)

## Acknowledgements:

We are very grateful for funding from the [National Science
Foundation](http://www.nsf.gov/), the McKnight Foundation, the [University of Minnesota](http://www.umn.edu), and [IBM](http://ibm.com) for funding different aspects of our research.
