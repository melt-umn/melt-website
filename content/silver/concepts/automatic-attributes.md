---
title: Automatic attributes
weight: 600
---

Some repetitive idioms exist in AG specifications that we would like to avoid writing boilerplate for by hand.
These attributes fall into various common patterns (functor, monoid, etc.)
As a first step, we add an extension to Silver such that in production bodies we can write
```
propagate attr1, attr2, ...;
```
This statement is overloaded for different kinds of attributes, forwarding to the appropriate equations on the production.

# Inherited attributes
If `env` is declared as an inherited attribute, then just writing `propagate env;` in a production body will generate copy equations for `env` on all children with the attribute.

```
inherited attribute env::Env;

nonterminal Stmt with env;

abstract production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  propagate env;
}
```

This translates to the following equivalent specification:

```
inherited attribute env::Env;

nonterminal Stmt with env;

abstract production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  s1.env = top.env;
  s2.env = top.env;
}
```

This is a recommended alternative to using [autocopy attributes](/silver/ref/decl/attributes/#autocopy-attributes), which may be deprecated at some point in the future.

# Monoid attributes
Monoid attributes allow for collections of values to be assembled and passed up the tree.
The type of a monoid attribute must be in the monoid category, having an empty value and append operator (e.g. `[]` and `++` for lists.)

A common use of monoid attributes is collecting a list of error messages up a syntax tree.  For example in ableC,
```
monoid attribute errors::[Message] with [], ++;

nonterminal Stmt;

attribute errors occurs on Stmt;

abstract production nullStmt
top::Stmt ::=
{
  propagate errors;
}
abstract production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  propagate errors;
}
abstract production errorStmt
top::Stmt ::= msg::[Message]
{
  top.errors := msg;
}
abstract production ifStmt
top::Stmt ::= c::Expr  t::Stmt  e::Stmt
{
  propagate errors;
  top.errors <-
    if c.typerep.isScalarType then []
    else [err(c.location, "If condition must be scalar type")];
}
```

This translates to the following equivalent specification:

```
synthesized attribute errors::[Message] with ++;

nonterminal Stmt;

attribute errors occurs on Stmt;

abstract production nullStmt
top::Stmt ::=
{
  top.errors := [];
}
abstract production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  top.errors := s1.errors ++ s2.errors;
}
abstract production errorStmt
top::Stmt ::= msg::[Message]
{
  top.errors := msg;
}
abstract production ifStmt
top::Stmt ::= c::Expr  t::Stmt  e::Stmt
{
  top.errors := c.errors ++ t.errors ++ e.errors;
  top.errors <-
    if c.typerep.isScalarType then []
    else [err(c.location, "If condition must be scalar type")];
}
```

Monoid attributes become [collection attributes](../collections) with the same append operator.
This means that non-propagated equations must use `:=` instead of `=`, and additional values can be contributed besides the propagated equation using the `<-` operator.

When propagated on a production with no children on which the attribute occurs, the empty value is used.
Otherwise, the append operator is used to combine the value of the attribute on all children with the attribute.

Monoid attributes commonly have list, string, integer or Boolean types.  If the type of the attribute is in the `Monoid` type class (as is the case with strings and lists), then the empty value and operator (the `with [], ++`) can be omitted.

# Functor attributes
Functor attributes allow for a mapping-style transformation over a tree, where we only wish to modify the tree in a few
places.
Thus the type of a functor attribute is effectively in the functor category, being a nonterminal that in some way encapsulates values that we wish to modify.
Functor transformations are distinct from forwarding, as these transformed trees are not necessarily semantically equivalent to the original tree. Also more than one functor transformation of the same tree is possible, while a production may only have one forward.

An example functor transformation is `host` in ableC, which transforms away ``injection'' productions by lifting declarations to higher points in the tree.

```
functor attribute host;

nonterminal Stmt;

attribute host occurs on Stmt;

abstract production nullStmt
top::Stmt ::=
{
  propagate host;
}
abstract production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  propagate host;
}
abstract production errorStmt
top::Stmt ::= msg::[Message]
{
  propagate host;
}
abstract production injectGlobalDeclsStmt
top::Stmt ::= lifted::Decls
{
  top.host = nullStmt();
  top.globalDecls = lifted.decls;
}
```

This translates to the following equivalent specification:

```
synthesized attribute host<a>::a;

nonterminal Stmt;

attribute host<Stmt> occurs on Stmt;

abstract production nullStmt
top::Stmt ::=
{
  top.host = nullStmt();
}
abstract production seqStmt
top::Stmt ::= s1::Stmt s2::Stmt
{
  top.host = seqStmt(s1.host, s2.host);
}
abstract production errorStmt
top::Stmt ::= msg::[Message]
{
  top.host = errorStmt(msg);
}
abstract production injectGlobalDeclsStmt
top::Stmt ::= lifted::Decls
{
  top.host = nullStmt();
  top.globalDecls = lifted.decls;
}
```

A functor attribute is implemented as just an ordinary synthesized attribute whose type is the same as the type of the nonterminal on which it occurs.  To enable this, a functor attribute forwards to an ordinary synthesized attribute with a type parameter `a`.
Functor attributes provide an overload for attribute occurrence such that `occurs on` for a functor attribute with no type argument provided will forward to an attribute occurrence with the nonterminal provided as the type argument.

`propagate` is overloaded for functor attributes such that propagating a functor attribute will result in an equation that constructs the same production with the result of accessing the attribute on all children.
Any children on which the attribute does not occur are simply used unchanged in the new tree.

Note that explicitly providing a different type as the type parameter is permitted, however attempting to propagate the attribute in this case would result in an error.  One may however wish to reuse a functor attribute in a different context, and provide explicit equations:

```
nonterminal ExtStmt;

attribute host<Stmt> occurs on ExtStmt;

abstract production extThing
top::ExtStmt ::= ...
{
  top.host = seqStmt(..., ...);
}
```

# Destruct attributes
Consider the problem of comparing two trees in some fashion, for example checking them for equality.  Some mechanism is needed to associate the nodes of two decorated trees of (possibly) the same shape.  This can be done by an inherited (destruct) attribute passing a [reference](/silver/concepts/decorated-vs-undecorated/#reference-decorated) to one tree being compared down the other, and a corresponding synthesized ([equality](/silver/concepts/automatic-attributes/#equality-attributes)) attribute that at every production determines whether the current tree is equal to the one that was passed down.

Destruct attributes can be thought of as sort of an inverse of functor attributes; functor attributes are to tree construction as destruct attributes are to tree deconstruction via pattern matching.

A destruct attribute is an inherited attribute on some tree that decomposes another decorated tree of the same shape; it is an error if a destruct attribute is ever demanded from a tree whose parent was constructed by a different production than the one provided in the attribute.

A destruct attribute might be used for comparing types in a functional language implementation.  Here types are represented by a `Type` nonterminal, with constructors for integer types, named data types, and function types:

```
destruct attribute compareTo;

nonterminal Type;

attribute compareTo occurs on Type;

abstract production intType
top::Type ::=
{
  propagate compareTo;
}

abstract production dataType
top::Type ::= name::String
{
  propagate compareTo;
}

abstract production fnType
top::Type ::= inputType::Type outputType::Type
{
  propagate compareTo;
}

```

The above translates to the following equivalent specification:

```
inherited attribute compareTo<a (i::InhSet)>::Decorated a with i;

nonterminal Type;

attribute compareTo<Type {}> occurs on Type;

abstract production intType
top::Type ::=
{
  -- No children for which to propagate the attribute
}

abstract production dataType
top::Type ::= name::String
{
  -- No children for which to propagate the attribute
}

abstract production fnType
top::Type ::= inputType::Type outputType::Type
{
  inputType.compareTo =
    case top.compareTo of
    | fnType(inputType2, outputType2) -> inputType2
    | _ -> error("Destruct attribute compareTo demanded on child a of production fnType when given value doesn't match")
    end;
  outputType.compareTo =
    case top.compareTo of
    | fnType(inputType2, outputType2) -> outputType2
    | _ -> error("Destruct attribute compareTo demanded on child a of production fnType when given value doesn't match")
    end;
}
```

The type of a destruct attribute is a [`Decorated` (reference) type](/silver/concepts/decorated-vs-undecorated/), such that attributes may be accessed on the corresponding tree.  The type of the destructed tree and the inherited attributes carried by the reference are specified as two type parameters on the attribute, of kind * and [InhSet](/silver/concepts/decorated-vs-undecorated/#inhset-types).

Destruct attributes provide an overload for attribute occurrence such that `occurs on` for a destruct attribute with no type arguments will forward to an attribute occurrence with the nonterminal and `{}` (the empty set of inherited attributes) provided as the type arguments.  Often one wishes to make use of inherited attributes on the deconstructed tree; if a single type argument is provided, it will be used as the set of inherited attributes for the reference.  For example writing
```
attribute compareTo<{someInh}> occurs on Type;
```
will forward to
```
attribute compareTo<{someInh} Type> occurs on Type;
```
giving a type `Decorated Type with {someInh}`; thus we could access `inputType.compareTo.someInh` in the `fnType` production.

Destruct attributes are typically used in conjunction with equality or ordering attributes, described next.

# Equality attributes
Equality attributes are used to compare trees for equality.  They are synthesized attributes of type `Boolean` that work in conjunction with a destruct attribute that specifies the tree to compare; the declaration of an equality attribute specifies what inherited attribute should be used.

```
equality attribute isEqual with compareTo
  occurs on Type;

aspect production intType
top::Type ::=
{
  propagate isEqual;
}

abstract production dataType
top::Type ::= name::String
{
  propagate isEqual;
}

abstract production fnType
top::Type ::= inputType::Type outputType::Type
{
  propagate isEqual;
}
```

The above translates to the following equivalent specification: 

```
synthesized attribute isEqual::Boolean occurs on Type;

aspect production intType
top::Type ::=
{
  top.isEqual =
    case top.compareTo of
    | intType() -> true
    | _ -> false
    end;
}

abstract production dataType
top::Type ::= name::String
{
  top.isEqual =
    case top.compareTo of
    | dataType(name2) -> name == name2
    | _ -> false
    end;
}

abstract production fnType
top::Type ::= inputType::Type outputType::Type
{
  top.isEqual =
    case top.compareTo of
    | fnType(_, _) -> inputType.isEqual && outputType.isEqual
    | _ -> false
    end;
}
```

The `==` operator is used to compare any children that do not have the `isEqual` attribute.

Note for any nonterminal types that have the standard `isEqual` and `compareTo` attributes defined in `silver:core`, the `==` operator itself is overloaded to use them for comparison.  Thus propagating `compareTo` and `isEqual` on a nonterminal type is comparable to writing `deriving Eq` in Haskell or similar languages.

# Ordering attributes
Ordering attributes are used define a total ordering for trees, e.g. to sort them or use them as map keys.  An ordering attribute pair consists of a "key" synthesized attribute of type `String` that assigns a unique identifier to every production, and the "result" synthesized attribute of type `Integer` that is similar in nature to an equality attribute.  The value of the result attribute is negative if the compared tree is "less" than the other, positive if it is "greater", and 0 if the trees are equal.

```
ordering attribute compareKey, compare with compareTo
  occurs on Type;

aspect production intType
top::Type ::=
{
  propagate compareKey, compare;
}

abstract production dataType
top::Type ::= name::String
{
  propagate compareKey, compare;
}

abstract production fnType
top::Type ::= a::Type b::Type
{
  propagate compareKey, compare;
}
```

The above translates to the following equivalent specification: 

```
synthesized attribute compareKey::String occurs on Type;
synthesized attribute compare::Integer occurs on Type;

aspect production intType
top::Type ::=
{
  top.compareKey = "example:intType";
  top.compare =
    case top.compareTo of
    | intType() -> 0
    | _ -> silver:core:compare(top.compareKey, top.compareTo.compareKey)
    end;
}

abstract production dataType
top::Type ::= name::String
{
  top.compareKey = "example:dataType";
  top.compare =
    case top.compareTo of
    | dataType(name2) -> silver:core:compare(name, name2)
    | _ -> silver:core:compare(top.compareKey, top.compareTo.compareKey)
    end;
}

abstract production fnType
top::Type ::= inputType::Type outputType::Type
{
  top.compareKey = "example:fnType";
  top.compare =
    case top.compareTo of
    | fnType(_, _) -> if inputType.compare != 0 then inputType.compare else outputType.compare
    | _ -> silver:core:compare(top.compareKey, top.compareTo.compareKey)
    end;
}
```

If the compared productions do not match, then they are compared according to their names as determined by the key attribute, using the standard library function `compare` from the [`Ord` type class](/silver/gen/silver/core/Ord/).
Otherwise the children of the matching production that have the attribute are compared via the attribute; any that lack the attribute are compared using the `compare` function.

Note for any nonterminal types that have the standard `compareKey`, `compare` and `compareTo` attributes defined in `silver:core`, the `compare` function itself (and other comparison operators) are overloaded to use the attributes for comparison.  Thus propagating `compareKey`, `compare` and `compareTo` on a nonterminal type is comparable to writing `deriving Ord` in Haskell or similar languages.

# Global propagate
In some cases we wish to propagate an attribute on all productions of a nonterminal with no exceptions.  Instead of adding `propagate` statements (and potentially aspects) for all productions, we can instead write
```
propagate attr1, attr2, ... on NT1, NT2, ...;
```
This generates an [aspect production](../aspects) for all known non-forwarding productions of these nonterminals.
Each of these aspect productions will contain `propagate attr1, attr2, ...;` in its body.

Sometimes one may wish to propagate on *almost* all productions of a nonterminal, but don't want to write `propagate` on all but a few production bodies.
This can be avoided by instead writing 
```
propagate attr1, attr2, ... on NT1, NT2, ... excluding prod1, prod2, ...;
```
This will generate propagating aspect productions for all but the listed productions.

We generally do not wish to propagate on forwarding productions as doing so would often be interfering, and the host language does not know about all forwarding productions anyway.  However if one does in fact wish to propagate on forwarding productions as well, they can simply add explicit propagate statements for each of these productions.

In some cases some non-forwarding propagate statements may not be exported by the definition of the nonterminal, such as with closed nonterminals or optioned grammars.  In these cases explicit propagate statements are required as well, however the omission of these will be caught by the flow analysis.

# Threaded Attributes

Sometimes you want attributes to be threaded through the tree in a particular way.

You might setup a threaded attribute like so
```
threaded attribute inh, syn;
```

And use it by calling it in this way.

`propagate inh, syn;` generates `child1.inh = top.inh; child2.inh = child1.syn; top.syn = child2.syn;` on non-forwarding prods

or ` child1.inh = top.inh; child2.inh = child1.syn; forward.inh = child2.syn;`
on forwarding prods

You can also do `thread inh, syn on top, child1, child2, prodattr1, prodattr2, top;` to adjust the order of threading or include prod attrs/locals  
