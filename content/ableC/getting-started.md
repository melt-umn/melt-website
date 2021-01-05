---
title: Getting Started
---

## Installation

The easiest way to get started is with the ableC bundle.  It includes
Silver, ableC, a collection of extensions, and some sample projects
that use them.

The best way to install this is by running [this
script](http://melt.cs.umn.edu/downloads/install-ableC-bundle.sh).
It will use Git to clone the current version of the software and
download the Silver JAR files that are needed.

Requirements:

* ``wget``
* [Java Development Kit](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
* ``ant``

**Mac OS X** has a few odd bits in the standard ``.h`` files that
ableC currently does not accept.  For now, give it a try on a Linux
box.  You can download a working VM with it all installed on the
[downloads page](/downloads/).

## Sample projects

Once ableC is installed, take a look at the sample projects (included in the
bundle, also available [here](https://github.com/melt-umn/ableC-sample-projects/)).
Each of the sample projects briefly described below contains a README file with
more information.

* The "down on the farm" project makes use of the sqlite, conditional tables,
algebraic data types, and regular expression extensions to analyze a database of
farm animals to compute income and expenses.

* The "parallel tree search" uses the algebraic data types, Cilk, and regular
expression extensions to count in parallel the nodes in a binary tree whose
values match a given regular expression. This project requires the Cilk runtime
libraries, so it is best to start with the "down on the farm" project.  If you
want to use the Cilk extension, first install the Cilk libraries.  The best way
to install this is by running [this
script](http://melt.cs.umn.edu/downloads/install-cilk-libs.sh) which will put
them in ``/usr/local``.

* The "using transparent prefixes" project demonstrates how to use transparent
prefixes to fix any lexical ambiguities that arise when composing
independently-developed language extensions that have passed the modular
determinism analysis. Any lexical ambiguities that arise when these grammars
are composed will involve a marking token from at least one of the extensions.

## Writing extensions

To get started writing extensions, please see these [ableC tutorials](https://github.com/melt-umn/ableC/tree/develop/tutorials/).
