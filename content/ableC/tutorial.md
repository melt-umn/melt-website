---
title: Tutorial
---

## Building parallel programming language constructs in the AbleC extensible C compiler framework

We are holding an [AbleC tutorial at the ACM Symposium on the
Principles and Practice of Parallel Programming](https://ppopp19.sigplan.org/track/PPoPP-2019-Workshops-and-Tutorials#event-overview) (PPoPP) on Saturday, February
16, 2019.  
This tutorial will teach participants how to create
expressive language extensions to the ableC extensible C compiler
framework. Specifically, it will cover
- how to define new concrete syntax for extensions,
- how to specify abstract syntax and type checking of extension constructs,
- how to overload existing C operators for extension introduced types, and
- how to easily specify the translation from extension constructs to their implementation in plain C.

We have re-implemented several parallel programming language features
from the literature as extensions to ableC.  This includes extensions
based on the following:
- Cilk-5; [this ableC
  extension](https://github.com/melt-umn/ableC-cilk) adds the Cilk
  features of ``spawn`` and ``sync``.  It translates ``cilk``
  functions into the same slow and fast clones of the the Cilk-to-C
  translator and uses the [MIT
  Cilk](https://doi.org/10.1145/277650.277727) runtime as the target
  of this translation. 
- Halide; [this ableC
  extension](https://github.com/melt-umn/ableC-halide) adds the
  explicit loop scheduling transformations as seen in
  [Halide](http://halide-lang.org/). 
- TACO; [this ableC
  extension](https://github.com/melt-umn/ableC-tensor-algebra)
  implements the efficient sparse tensor representations and
  operations as described in the Kjolstad's [OOPLSA 2017 "TACO"
  paper](https://doi.org/10.1145/3133901). 


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
