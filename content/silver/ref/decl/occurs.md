---
title: Occurs declarations
weight: 400
---

{{< toc >}}

Quick examples:

```
attribute pp occurs on Expr;

attribute fst<a> occurs on Pair<a b>;
```

## Syntax

An occurs-on declaration indicates that a (separately declared) attribute occurs on the (separately declared) nonterminal specified.
Most commonly, a nonterminal `with` clause will be used instead of this form of declaration directly.

For parameterized attributes, an occurs declaration also plays the crucial role of indicating how the attribute's type parameters should be determined, given a nonterminal and its type parameters.
If the attribute is not parameterized, the angle brackets are omitted.

<pre>
attribute <i>name</i> &lt; <i>types...</i> &gt; occurs on <i>nonterminal type</i>;
</pre>

Note that attributes can only occurs on _nonterminal_ types.
Also note that inside the angle brackets is a _type_ list as opposed to a _type variable_ list.
Thus, the following is a valid occurs on declaration:

```
synthesized attribute ast<a> :: a;
attribute ast<AbstractExpr> occurs on ConcreteExpr;
```

Only those type variables that appear in the nonterminal type on the right may appear in the type list for the attribute on the left.

## Convenience syntax

The most strongly preferred, whenever possible, means of declaring attribute occurrences is described on the [nonterminal declaration page](/silver/ref/decl/nonterminals/).
There is also a means of merging occurs on declarations with the [attribute declarations](/silver/ref/decl/attributes/) themselves.
Occurs declarations by themselves are rare in Silver code.


Additionally it is possible to declare more than one attribute, more than one nonterminal, or both in one occurs on declaration:

```
attribute env, pp, errors occurs on Expr, Stmt;
```

However, this syntax also falls prey to the same limitation described on the [attributes](/silver/ref/decl/attributes/) page.

## Occurs-on type constraints

Attributes bear some resemblance to [type classes](/silver/ref/decl/typeclasses), in that they define some operation (such as pretty-printing or translation)
with different behavior over different types.  By analogy, occurs-on declarations are sort of like instance declarations.

With type classes, we sometimes would like to abstract over any type that has an instance of some type class,
which we can do by writing type class type constraints.
Similarly, we sometimes would like to abstract over any type that has some attribute(s) occuring on it.
This can be done using attribute occurs-on constraints, for example
```
function getErrors
attribute env occurs on a,
attribute errors {env} occurs on a =>
[Message] ::= env::Env x::a
{
  x.env = env;
  return x.errors;
}
```
Here `attribute env occurs on a` is a constraint stating values of type `a` can be supplied with the inherited attribute `env`.
`attribute errors {env} occurs on a` states that the attribute `errors` can be demanded from `a` values that have been decorated
with at least `env`.
To call `getErrors` for some type `Foo`, the attrbutes `env` and `errors` must occur on `Foo`,
and the [flow type](/silver/concepts/modular-well-definedness/) of `errors` on `Foo` must be no larger than `{env}`.

The flow type in a synthesized occurs-on type constraint can also be polymorphic - for example,
```
function getErrorsFromReference
attribute errors i1 occurs on a,
i1 subset i2 =>
[Message] ::= x::Decorated a with i2
{
  return x.errors;
}
```
Here if `errors` and `env` occur on `Foo` and `errors` has a flow type of `{env}`,
`getErrorsFromReference` can be called on `Decorated Foo with {env}` or `Decorated Foo with {env, someInh}`.

Using occurs-on constraints for this sort of helper function is not super useful;
more compelling use cases involve uses of them in conjunction with type classes and productions.
For example, the Silver standard library defines this instance for `Eq`:
```
instance attribute compareTo<a {}> occurs on a,
         attribute isEqual {compareTo} occurs on a
         => Eq a {
  eq = \ x::a y::a -> decorate x with {compareTo = decorate y with {};}.isEqual;
}
```
Here `compareTo` is an inherited [destruct attribute](/silver/concepts/automatic-attributes#destruct-attributes) that specifies the tree being compared,
and `isEqual` is a synthesized [equality attribute](/silver/concepts/automatic-attributes#equality-attributes) that computes whether a tree is equal to the specified one.
This instance defines an instance for `Eq a`, for any `a` where `compareTo` occurs on `a` (where the type of the compared tree is `a` decorated with `{}`),
and where `isEqual` occurs on `a`, depending on at most `compareTo`.

Another examples is in the Silver compiler's implementation of the environment.
The nonterminal `QNameLookup` represents the result of looking up some entity from the environment:
```
nonterminal QNameLookup<a> with fullName, typeScheme, errors, dcl<a>, found;
synthesized attribute fullName::String;
synthesized attribute typeScheme::PolyType;
synthesized attribute dcl<a>::a;
synthesized attribute found::Boolean;
```
The environment implementation is polymorphic over different `*DclInfo` types for declarations in different namespaces:
```
synthesized attribute lookupValue :: Decorated QNameLookup<ValueDclInfo> occurs on QName;
synthesized attribute lookupType :: Decorated QNameLookup<TypeDclInfo> occurs on QName;
synthesized attribute lookupAttribute :: Decorated QNameLookup<AttributeDclInfo> occurs on QName;
```
Every `*DclInfo` nonterminal has the attributes `fullName` and `typeScheme`, and the [annotation](/silver/ref/decl/annotations/) `sourceLocation` occurring on them.
This is expressed using occurs-on constraints on the `customLookup` production:
```
abstract production customLookup
attribute fullName {} occurs on a,
attribute typeScheme {} occurs on a,
annotation sourceLocation occurs on a =>
top::QNameLookup<a> ::= kindOfLookup::String dcls::[a] name::String l::Location 
{
  top.found = !null(top.dcls); -- currently accurate
  top.dcl = head(top.dcls);
  
  top.fullName = if top.found then top.dcl.fullName else "undeclared:value:" ++ name;
  top.typeScheme = if top.found then top.dcl.typeScheme else monoType(errorType());
  
  top.errors := 
    (if top.found then []
     else [err(l, "Undeclared " ++ kindOfLookup ++ " '" ++ name ++ "'.")]) ++
    (if length(dcls) <= 1 then []
     else [err(l, "Ambiguous reference to " ++ kindOfLookup ++ " '" ++ name ++ "'. Possibilities are:\n" ++ printPossibilities(dcls))]);
}
```
Here we can access the `fullName` and the `typeScheme` of the resolved `dcl` in a generic fashion, despite not knowing the specific nonterminal type of `a`.
When a lookup returns multiple ambiguous possibilities, we would like to include their full names and locations in the reported error message.
This is done by the function `printPossibilities`:
```
function printPossibilities
attribute fullName {} occurs on a,
annotation sourceLocation occurs on a =>
String ::= lst::[a]
{
  return implode("\n", map(\ dcl::a ->
    "\t" ++ dcl.fullName ++ " (" ++ dcl.sourceLocation.filename ++ ":" ++ toString(dcl.sourceLocation.line) ++ ")",
    lst));
}
```
