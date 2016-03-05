# melt-website

The MELT website ([http://melt.cs.umn.edu]) is to be generated from
hand-written Markdown files and documentation annontations in the
Silver files that implement Silver and ableC.

This relies on Jekyll and an extension to Silver for processing the
annotations in Silver files.  

Below are the descriptions for running our scripts for generating and
installing the melt website, followed by the documentation for setting
up Jekyll.

# Generating and installing [http://melt.cs.umn.edu]

(Currently, we are installing this in [http://melt.cs.umn.edu/alpha]
and will eventually use this to generate the real melt site.)

A local user, named ``gitbot`` on coldpress.cs.umn.edu has created for
running the scripts.  (Evenually, Jenkins will do this automatically
when the documentation sources change.)

Since installing the Ruby gems takes some time, the process is broken
up into 5 steps.  The intention is that one can start the process at
any point in the sequence to avoid time-consuming early steps when
they are not required.

The 5 steps are:

1. From ``gitbot`` home directory, run ``step1-clone-and-rebuild.sh``.

   This script is not under version control.  It simply clones the
   ``melt-website`` repository and starts the second step from inside
   that ``melt-website`` directory.

   The ``--install`` command-line flag will cause step 5 to run and
   install the site.  This flag is passed through the scripts for the
   various steps until it is needed.

2. From the ``melt-website`` directory, run ``step2-install-gems-silver.sh``. 

   This installs the Ruby gems and the documentation generating branch
   of Silver.  It then runs step 3.

3. From the ``melt-website`` directory, run ``step3-generate-docs.sh``. 

   Runs Silver to generate the Markdown documentation from annontation
   in various Silver files.  This step will organize the Markdown
   files so that everything is ready for Jekyll.  Which this scripts
   starts by running the step 4 script.

4. From the ``melt-website`` directory, run ``step4-run-jekyll.sh``. 

   Create the site and put it in ``~gitbot/build``.  If the
   ``--install`` is set, it runs step 5.

5. From the ``melt-website`` directory, run ``step5-install-site.sh``. 

   This installs the generated website in
   [http://melt.cs.umn.edu/alpha].  

  

# Local setup guide for Jekyll

You need Ruby 2.x and Node.js installed. :webdev:

(My Ubuntu machine is old, and I didn't have Ruby 2 available, the easiest method I found was to compile and install it from source. The ancient Node.js version was fine though.)

You also need bundler installed:

    gem install bundler

Machine-wide installs of these are probably best. Next, you should install the dependencies this package uses:

    bundle install --path vendor/bundle

This will install all these dependencies under `vendor/bundle` so things don't get conflicty. This means you needs to prefix all commands with `bundle exec` though.

So you should be able to run with:

    bundle exec jekyll serve

Hooray!

# How this works

You'll find a bunch of markdown files in below this root directory. Easy to see:

    $ find * -name "index.md"

This are the wiki data. Each of them uses `layout: sv_wiki` which means they are converted to html, then run through the layout templating system. That layout is defined by `_layouts/sv_wiki.html`. This makes use of `_includes/nav.html` amoung other things from `_includes`.

This nav template generates a hierarchy by investigating information stored in `site.data.sv_wiki`, which is found in `_data/sv_wiki.yml`. YAML format. At present, this is a list of items, which consist of `text`, `url`, an optional `subitems` list, and an optional `nolink: true` which suppresses emitting a link.

The reason for the existance of `nolink` is that, in order to expand the navigation down to the present page, we need to know exactly which path to take all the way down. The templating language is extremely primitive, so it's hard to know otherwise which one to use. Note that this means *the directory structure must exactly mirror the nagivation structure*.

The navigation has three major components:

* `js/nav.js` which enables the click to expand/unexpand
* `_sass/_nav.scss` which styles the navigation bar. (Also includes styling of markdown ToC!)
* `_includes/nav.html` which is the (recursive) template that generates a navigation list.

To use the navigation template, the include looks as follows:

    include nav.html nav=site.data.sv_wiki navbase=site.sv_wiki_base

The `nav` variable indicates the data to use, and `navbase` indicates the root all links will go from. Note that `sv_wiki_base` is just a variables defined in `_config.yml`.

# TODO

Investigate this:

https://www.reddit.com/r/Jekyll/comments/3cwn36/i_made_a_dynamically_generated_hierarchical_menu/

might be a way to eliminate the need for the sv_wiki data file, mirroring the directory hierarchy directly instead. Data like `nolink` could be yaml frontmatter in the index.md instead, I think.

**Potential downside, though: how do we control ordering?**

Still, maybe we could use some technique here to eliminate the need to duplicate things like page titles? If it were just a list of urls, in the order we want them?


In other news, I haven't touched the layouts/css enough. They're messy.

Also, I've left the "blog post" and feed.xml unchanged.

Another TODO item: We should rename `/ref/stmt/` to `/ref/equations/`. Better name for "things in production blocks". Possibly also the nonterminal in Silver's source, too. :)


# Major TODO: Formatting

Many pages aren't well-formatted anymore due to minor conversion issues with the markup. They should all be fixed.

