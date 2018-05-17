---
layout: sv_wiki
menu_title: Home
menu_weight: 0.0
permalink: /
---

Our main research interests are in declarative specifications for
programming language syntax, semantics, and optimizing
transformations.  We are specifically interested in techniques that
lead to a *high degree of modularity* in the composition of language
specifications.  We have designed a few unique tools that
automatically compose and implement such specifications to create
pre-processors, compilers and optimizers for the newly specified
languages.

## Extensible languages and compiler frameworks:

Specifically we are interested in tools and techinques that allow a
programmer, who is not an expert in language or compiler construction,
to easily import independently-developed (domain-specific) language
features into their programming language.  These features may add new
syntax, semantic analyses, and optimizations to the language.  This
extended language raises the level of abstraction to that of the task
at hand and, we conjecture, makes software development less time
consuming and less error-prone.

There are many research efforts in extensible languages to support the
highly modular design of programming languages.  We are interested in
a specific view of extensible languages and compilers in which the
*composition* of language features is directed by a programmer that
need not be an expert in language and compiler constructions.

This view leads to a few criteria that we believe must be satisifed
for extensible languages or extensible compilers to have a long-term
impact: 

1. Language extensions can be designed by independent parties.
2. Language extensions can add new syntactic constructs.
3. Language extensions can add new semantic analyses of these
   constructs and on constructs in the host language that is being
   extended.
4. The composition of the extensions chosen by the non-expert
   programmer must succeed and form a working compiler or translator.

These criteria have some implications:

* Criteria 2 and 3 require that the extensible language/compiler must
  solve the "Expression Problem": that is, both new syntax and new
  semantics can be added without the modification of the host language
  specification of other language extensions.

* By adding criterion 1, we need to solve a specific version of
  the expression problem, that one extension need not be aware of
  another. 

* Adding criterion 4 requires that the composition must be automatic
  and that *no* "glue code" be written to combine the language
  extensions. 

To solve this problem, language and extension specifications must be
easy to compose and some modular analyses, performed by the language
extension writers, need to provide the assurance that the extension
has the characteristics needed to compose with other extensions.

## Software:
Much of our research is evaluated by writing software that realizes
these ideas.  Collectively, the tools and specfications described
below satisfy the above criteria.


### ableC: an extensible specification of C

[ableC](ableC/index.html) is our primary vehicle for investigating
extensible languages.  This specification implements the C11 standard
of the C programming language.


### Silver: an extensible attribute grammar system

[Silver](silver) is our attribute grammar system.  The specifications
for ableC and its extensions are written in the Silver AG language. 

Uniquely, Silver supports a modular analysis that extension writers
can use to certify that their extension will compose with other
independently-developed, and similarly certified, extensions to form a
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
