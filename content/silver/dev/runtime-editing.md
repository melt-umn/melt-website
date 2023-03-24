---
title: Silver runtime
weight: 400
---

{{< toc >}}

## A tour of the runtime

| silver | A main function for invoking the Silver compiler. (To set up the class path to find the runtime jars, etc.) |
|:-------|:------------------------------------------------------------------------------------------------------------|
| common.rawlib | Adapters for some Java data structures, so they can be called easier from Silver.                            |
| common.javainterop | Some utilities for working with Silver stuffs from Java code. (currently iterator for lists and comparator from silver functions.) |
| common.exceptions | Contains the Silver-specific exceptions. See the JavaDocs for the class for details.                        |
| common | See below                                                                                                   |

## The common package

The basic mechanics:

  * **Lazy** - Essentially just a function pointer. Given a context to evaluate.
  * **Thunk** - Thunk. No context necessary.
  * There's also **PatternLazy** - just a detail about pattern matching translation
  * Also **CollectionAttribute** - A **Lazy**, that allows contributions to be mutated in.

The basic data structures:

  * **StringCatter** - A special string representation to make appends efficient.
  * **ConsCell** - List cons cells. (They're special-cased because lists are so common that it's important to be space efficient. And also to have efficient appends...) (**NilConsCell** is a nested class inside ConsCell, and not referenceable.)
  * **AppendCell** - Actually implements the special optimization for list appends.

Attribute-grammary data structures:

  * **Terminal** - Representation for terminals.
  * **Node** - represents _undecorated_ nodes. (i.e. given children, but nothing more.)
  * **DecoratedNode** - Given inherited attribute values. Can be examined for attributes, etc.

Related attribute-grammary stuffs:

  * **FunctionNode** - Closes off parts of Node that don't apply for functions.
  * **NodeFactory** - Represents the type of Silver functions.
  * **AttributeSection** - A kind **NodeFactory** for accessing an attribute (the (.pp) syntax)
  * **PartialNodeFactory** - Implements partial application.
  * **TopNode** - A decorated node that errors if it's ever used. Maybe slightly nicer than using 'null' whenever a 'context' is required, but nonexistent.

**Util** is just a random collection of static methods, often used by the 'core' library.

Ignore this crap:

  * **IOToken** - not yet used, but will eventually just be the '`IO`' value.
  * **Statistics** - ignore it. Nasty.

## Generated class info

  * Every **nonterminal** is class that inherits from **Node**
  * Every **production** is a class that inherits from the **nonterminal** class
  * Every **production** and **function** has a static 'invoke' method, and a 'factory' field that is the **NodeFactory** value for that function.
  * The Init.java for every grammar has a count of number of syn/inh on every nonterminal and locals on every production.
    * This is used during initialization to give indexes into arrays for all syn/inh/locals. (Typically given names like occurs.grammar.name.Init.attribute\_grammar\_attrONnonterminal\_grammar\_nt)

## General rule

Grep for things to see how they're used.
