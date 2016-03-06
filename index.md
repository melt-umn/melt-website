---
layout: sv_wiki
title: MELT
---

# Minnesota Extensible Language Tools

Our main research interests are in the declarative specification of
programming languages semantics and transformations for
optimization. We are specifically interested in techniques that lead
to a high degree of modularity in the composition of language
specifications. This is so that specifications for language features
can be easily combined to create specifications for new languages. 

We
are thus interested in tools that automatically compose and implement
such specifications to create pre-processors, compilers and optimizers
for the newly specified languages.

## Extensible languages and compiler frameworks:

Specifically we are interested in tools and techinques that allow a
programmer, who is not an expert in language or compiler construction,
to extend their language with new domain-specific syntax, semantic
analyses, and optimizations.  This extendend language raises the level
of abstraction to that of the task at hand and, we conjecture, makes
software development less time consuming and less error-prone.

There are many research efforts in extensible langauges to support the
highly modular design of programming languages.  We are interested in
a specific view of extensible languages and compilers in which the
*composition* of language features is directed by a programmer that
need not be an expert in language and compiler constructions.

This view leads to a few criteria that we believe must be satisifed
for extensible langauges or extensible compilers to have a long-term
impact: 

1. language extensions can be designed by independent parties
2. langauge extensions can add new syntactic constucts 
3. language extensions can add new semantic analyses of these
   constucts and on construct in the host langauge that is being
   extended. 
4. the composition of the extensions choosen by the non-expert
   programmer must succeed and form a working compiler or translator. 

These criteria have some implications:

* Criteria 2 and 3 require that the extensible language/compiler must
  solve the "Expression Problem": that is, both new syntax and new
  semantics can be added without the modification of the host langauge
  specification of other language extensions.

* By adding criterion 1, we need to solve a specific version of
  the expression problem, that one extension need not be aware of
  another. 

* Adding criterion 4 requires that the composition must be automatic
  and that now "glue code" be written to combine the language
  extensions. 

To solve this problem, language and extension specifications must be
easy to compose and some modular analyses, performed by the language
extension writers, need to provide the assurance that the extension
has the characteristics needed to compose with other extensions.

## Software:
Much of our research is evaluated by writing software the realizes
these ideas.  Collectively, the tools and specfications described
below satisfy the above criteria.


### ablec: an extensible specification of C

[ableC](ablec/index.html) is our primary vehicle for investigating
extensible langauges.  This specification implements (or soon will)
the C11 standard of the C programming langauge.


### Silver: an extensible attribute grammar system

[Silver](silver) is our attribute grammar system.  The specifications
for ableC and its extensions are written in the Silver AG langauge. 

Uniquely, Silver supports a modular analysis so that extension writers
can use to certify that their extension will compose with other
independently-devlopled, and similarly certified, extensions to form a
well-defined attribute grammar.  Essentially, this ensures that the
composed attribute grammar will work. 


### Copper: a context-aware scanner and parser generator

[Copper](copper/index.html) is a parser and scanner generator that
generates integrated LR parsers and context-aware scanners from
language specifications based on context-free grammars and regular
expressions. The generated scanners use context (in the form of the
current LR parse state) to be more discriminating in recognizing
tokens.  This is useful in extensible language settings and has the
nice benefit of making LR parse table conflicts less likely. 

Copper also has a modular analysis that can be used to ensure that
certified language extension grammars will compose into a
deterministic grammar. 

## Acknowledgements:

We are very grateful for funding from the [National Science
Foundation](http://www.nsf.gov/), the McKnight Foundation, the
[University of Minnesota](http://www.umn.edu), and
[IBM](http://ibm.com) for funding different aspects of our research. 
