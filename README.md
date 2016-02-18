# melt-website
Experiment to generate the melt.cs.umn.edu web site from Markdown using Jekyll


# Local setup guide

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

