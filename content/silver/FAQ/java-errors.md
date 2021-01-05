---
title: Java Errors
weight: 30
---

{{< toc >}}

## Why do I get a NoClassDefFoundError when trying to run a tutorial?

Possibilities:

  * Be sure you're using a reasonable JVM. `java -version` should be at least Java 1.6. We know silver does NOT work with `gcj`. Use OpenJDK or the Oracle distributions.
  * You have moved Silver since building that jar.  In the default build mode, Silver hard codes an absolute path to the runtime jars into generated jars. Try simply rebuilding the tutorial:
```
./silver-compile --clean
```
  * You are on Windows.  That hardcoded path doesn't work, so you may have to use a different build mode, to produce a jar with no dependencies:
```
./silver-compile --clean --onejar
```
  * There are spaces in the path to Silver.  Solution is the same as on windows (use --onejar.)  (Why is this a problem? Well, apparently Java manifest files don't like spaces in paths. It's only our fault in that this probably shouldn't be our default build method.)


## What do I do if javac raises errors on Silver-generated code?

There are very few known wrong-code bugs in Silver. There are, however, several known bugs in the build system.

Try re-running silver with the `--clean` flag. This should force Silver to regenerate the out-of-date java files, solving the javac error.

If not, please file a bug report.

## How do I resolve stack overflows or out of memory errors?

Unfortunately, the JVM isn't required to support tail call elimination, and Silver, being a purely functional language, can sometimes exhaust stack space.

The solution is to use the `-Xss` option the JVM provides to give it more stack space.  The default script (`support/bin/silver`) uses `-Xmx2000M -Xss4M`, which is nearly always enough.

(In the past, the `-Xmx` option was usually necessary to increase heap space, too. These days, it just doesn't really hurt to leave it.)
