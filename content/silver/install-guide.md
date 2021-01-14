---
title: Installation Guide
weight: 10.0
---

{{< toc >}}

## Prerequisites

[Java JDK, version 1.7](http://www.oracle.com/technetwork/java/javase/downloads/index.html), [Apache ANT](http://ant.apache.org/bindownload.cgi), Git and wget. For Ubuntu users:

```
apt-get install default-jdk ant git wget
```

For OSX, using Homebrew (install a JDK separately):

```
brew install coreutils ant wget
```

## Getting Silver

To clone from GitHub,
wherever you wish to checkout the repository, run:

```
$ git clone https://github.com/melt-umn/silver.git
$ cd silver
silver$ ./update
```

This will pull the latest changes, and update your working copy. It
will also download the latest jars (which may be necessary! Silver is
written in Silver, so there can be bootstrapping issues) and clear out
any generated files, which may now be stale with the new version.

Alternatively, the latest stable release can be found on the [Downloads](/downloads/) page.

## Testing things out by building the tutorials

Here is an example session, running the hello world tutorial grammar:

```
silver$ cd tutorials/hello
silver/tutorials/hello$ ./silver-compile
 -- SNIPPED --
silver/tutorials/hello$ java -jar hello.jar
Hello, World!
```

If you have any issues, first try the [frequently asked question page](/silver/faq/) to see if there are any questions like yours.

## Installing the 'silver' script

```
silver$ ./support/bin/install-silver-bin
```

Note that this assumes you have a ~/bin. In most distributions, if you
don't have a ~/bin, all you have to do is `mkdir ~/bin`, and the
default shell scripts will notice it and add it to your `PATH` next
time your shell is started. 

At this point, Silver should be all set. You can test it with: (continuing from above)

```
silver$ cd tutorials
silver/tutorials$ silver hello
 -- SNIPPED --
silver/tutorials$ java -jar hello.jar
Hello World!
```

Note that this differs from the previous example session by using the '`silver`' script
in `~/bin` instead of the local `silver-compile` script, and it is run
from the `tutorials` directory instead of `tutorials/hello`.


## Building Silver

See [here](/silver/dev/building/).

