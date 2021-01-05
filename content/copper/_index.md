---
title: Copper
weight: -80
---

Copper is a parser and scanner generator that generates integrated LR
parsers and context-aware scanners from language specifications based
on context-free grammars and regular expressions. The unique feature
in Copper is that the generated parser provides contextual information
to the scanner in the form of the current LR parse state when the
scanner is called to return the next token. The scanner uses this
information to ensure that it only returns tokens that are valid for
the current state, that is, those for terminals whose entry in the
parse table for the current state is shift, reduce, or accept (but not
error). Context-aware scanners are more discriminating than those that
lack context and allow the specification of simpler grammars that are
more likely to be in the desired LALR(1) grammar class. 

One language for which this approach is useful is AspectJ, an
extension bringing aspect constructs to Java. Previously AspectJ has
only been parsed by hand-coding a scanner (sacrificing
declarativeness) or using a GLR-based parsing tool (sacrificing
determinism). We have adapted a declarative AspectJ grammar that can
be parsed deterministically in Copper; the source code of this grammar
is linked from the downloads page. 

Our GPCE 2007 paper <a
href="http://www-users.cs.umn.edu/~evw/pubs/vanwyk07gpce/">
<em>Context-Aware Scanning for Parsing Extensible Languages</em></a>
provides a detailed discussion of parser-based context-aware scanning.

Copper can also subject a language extension to a test guaranteeing
that all extensions that pass the test can be
composed <em>together</em> without any parse-table conflicts. This
test is documented in our PLDI 2009 paper
<a href="http://www-users.cs.umn.edu/~evw/pubs/schwerdfeger09pldi/"><em>Verifiable Composition of Deterministic Grammars</em></a>.

Copper is written in Java and generates parsers and scanner written
in Java.   It is used by our attribute grammar system
<a href="/silver/">Silver</a> and
distributed with it.  It is also available as a stand-alone
package.

## Downloads and documentation:

Current versions of Copper are maintained <a href="http://github.com/melt-umn/copper">on GitHub</a>:

* <a href="https://github.com/melt-umn/copper/releases">Binary distributions</a>
* <a href="https://github.com/melt-umn/copper/blob/master/doc/manual/CopperUserManual.md">Online manual</a>
* <a href="http://melt.cs.umn.edu/copper/current/javadoc">Javadoc</a>

A download for a legacy version, 0.5, used with older versions of
Silver, is available <a href="/downloads/previous-releases.html">here</a>.

## Acknowledgments:

This material is based upon work supported by the National Science
Foundation under grants 
<a href="http://www.nsf.gov/awardsearch/showAward.do?AwardNumber=1047961">#1047961</a>,
<a href="http://www.nsf.gov/awardsearch/showAward.do?AwardNumber=0905581">#0905581</a>,
<a href="http://www.nsf.gov/awardsearch/showAward.do?AwardNumber=0429640">#0429640</a>,
and
<a href="http://www.nsf.gov/awardsearch/showAward.do?AwardNumber=0347860">#0347860</a>,
IBM, and the McKnight Foundation.

Development of Copper versions 0.6 and 0.7 was supported by funding
from <a href="http://www.adventiumlabs.com">Adventium Labs</a>. 

Any opinions, findings, and conclusions or recommendations
expressed in this material are those of the author(s) and do not
necessarily reflect the views of the National Science Foundation.
