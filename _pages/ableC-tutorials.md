---
title: AbleC Tutorial
menu_title: AbleC Tutorials
menu_weight: 10
permalink: /ableC/tutorial/
---

## Building parallel programming language constructs in the AbleC extensible C compiler framework

We are holding an AbleC tutorial at the ACM Symposium on the
Principles and Practice of Parallel Programming (PPoPP) on Saturday, February
16, 2019.  This tutorial will teach participants how to create
expressive language extensions to the ableC extensible C compiler
framework.   Specifically, it will cover
- how to define new concrete syntax for extensions,
- how to specify abstract syntax and type checking of extension constructs,
- how to overload existing C operators for extension introduced types, and
- how to easily specify the translation from extension cosntructs to their implementation in plain C.

The 4-page tutorial abstract that appears in the PPoPP proceedings can
be found [here](https://www-users.cs.umn.edu/~evw/pubs/carlson19ppopp/).

This tutorial focuses on implementing parallel programming language
features as language extensions to ableC.  Examples of such extensions
can be found in
- our [OOPSLA 2017 paper](https://www-users.cs.umn.edu/~evw/pubs/kaminski17oopsla/).
- and a [technical report focusing on parallel programming extensions](https://www.cs.umn.edu/research/technical_reports/view/19-001).

The PPoPP tutorial materials will all be posted here.  This will be a
more structured and complete version of the current ableC tutorials
that can be found [here](https://github.com/melt-umn/ableC/tree/develop/tutorials).
