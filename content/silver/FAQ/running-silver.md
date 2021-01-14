---
title: Running Silver
weight: -30
---

{{< toc >}}

## Why is the Silver compiler so painfully slow?

Although Silver isn't going to win the language shootout benchmarks anytime soon, it should be reasonably fast!

However, it does generate a large number of small intermediate files in the generated directory.  There are two known cases where things might slow to a crawl:

  * Windows Vista seems to just be flat-out terrible. Now you have an excuse to go get 7. Or something else.
  * The `generated` directory is stored on a network filesystem.  There shouldn't ever be anything that needs saving/backing up inside the `generated` directory.  We suggest symlinking it or setting the SILVER\_GEN environment variable to store that directory locally. (MELT internal people on CS machines: symlink it to scratch space.)

## Does Silver run on Windows?

Yes, but you have to use the `--onejar` flag.  By default Silver embeds full paths to the runtime jars in the manifest, since that produces smaller jars and is quicker for development.  For some reason (probably because it's terrible Java practice) this just doesn't work properly on windows machines.  `--onejar` just mixes the runtime straight into the generated jar, so this problem is avoided. For the moment, this is fine; the runtime isn't too big.

Better solutions are quite possible, but just haven't been developed yet.
