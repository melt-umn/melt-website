---
layout: sv_wiki
title: Getting started with ableC
menu_title: Getting started
menu_weight: 60.0
---


# Installation

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
[downloads page](/downloads).

# Sample projects

Once ableC is installed, take a look at the sample projects (included in the
bundle, also available [here](https://github.com/melt-umn/ableC_sample_projects)). The
parallel tree search example requires the Cilk runtime libraries, so
it is best to start with the "down on the farm" project. The example
`accounting.xc` makes use of the sqlite, conditional tables, algebraic data
types, and regular expression extensions. Compile and run this example as
follows:

```
$ cd ableC_sample_projects/down_on_the_farm
$ make
$ ./create_database.sh
$ ./populate_table
$ ./accounting
```

If you want to use the Cilk extension, first install the Cilk
libraries.  The best way to install this is by running [this
script](http://melt.cs.umn.edu/downloads/install-cilk-libs.sh)
which will put them in ``/usr/local``.  



# Writing extensions

To get started writing extensions, please see the [ableC tutorials](https://github.com/melt-umn/ableC/tree/develop/tutorials).
