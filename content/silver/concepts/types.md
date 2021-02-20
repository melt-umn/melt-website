---
title: Types
weight: 200
---

{{< toc >}}

The primitive types in Silver are:

```
String
Boolean
Integer
Float
IO
```

For more information on these primitive types, see the corresponding sections on expressions for [Booleans](/silver/ref/expr/booleans/), [Numeric Operations](/silver/ref/expr/numeric/), [Strings](/silver/lib/string/), and [IO](/silver/lib/io/).)

## Function and production types

Functions and production have types that look similar to their signatures, but with
the names removed:

```
(<Type> ::= <Type> ...)
```

> _**Example:**_ The following function signature:
```
function pluck
String ::= lst::String index::Integer
```
> has type
```
(String ::= String Integer)
```


## Lists

Lists are given a special syntax for types:

```
[ <Type> ]
```

See [Lists](/silver/lib/list/) for more information on lists.

> _**Example:**_ The map function would have the following signature:
```
function map
[b] ::= (b ::= a) [a]
```


## Nonterminals and terminals

Nonterminal declarations create a type (as do terminal declarations.) All type
names must be capitalized, as lower case names are considered type variables
(see [Type Variables](#type-variables).)

> _**Example:**_ The following nonterminal declaration:
```
nonterminal Expr;
```
> creates the type _`Expr`_.

> _**Note:**_ Attributes with a nonterminal type are often called _`higher-order attributes`_ in the attribute grammar literature\cite{vogt89}.  For example:
```
synthesized attribute transformed :: Expr;
```
> is a "higher-order attribute."


Nonterminals additionally have a "decorated" form, whose type is simply prefixed
with the keyword _`Decorated`_.  See [Decorated vs Undecorated](/silver/concepts/decorated-vs-undecorated/) for more information.

> _**Example:**_
```
Expr
Decorated Expr
```
> Each of these lines is a valid, and importantly different, type.

> _**Note:**_ Attributes with a decorated nonterminal type are often called **reference attributes** in the attribute grammar literature\cite{hedin00}.  For example:
```
synthesized attribute declaration :: Decorated Dcl;
```
> is a "reference attribute."


## Type variables

Lower case type names are considered to be type variables.  Type variables are
declared in a function or production signature only (using a new type variable
name elsewhere will result in an ``undefined type" error.)

> _**Example:**_
```
function reverse
[a] ::= l::[a]   -- 'a' is a new type variable
{
  local attribute foo:[b]; -- ERROR: 'b' is not in scope
}
```

Type variables are always held abstract where they are in scope. Once something
is declared to be of type _`a`_, that cannot be refined to, for example,
_`Integer`_ as long as _`a`_ is in scope.

> _**Example:**_
```
function reverse
[a] ::= l::[a]
{
  return [1,2]; -- ERROR: 'a' is not Integer
}
```

> _**Example:**_ But, the following is perfectly okay:
```
global foo :: [Integer] = reverse([1,2,3]);
```

## Polymorphic nonterminal types

Nonterminal types in Silver maybe be polymorphic, parameterized with type arguments.

> _**Example:**_
```
nonterminal Either<a b>;

production left
top::Either<a b> ::= x::a
{}
production right
top::Either<a b> ::= x::b
{}

global res :: Either<String Integer> = right(42);
```

We can also define *type aliases*, giving a name to a more complex type;
type aliases may also be polymorphic.

> _**Example:**_
```
type EitherString<a> = Either<String a>;
global res :: EitherString<Integer> = right(42);
```

## Kinds
Silver supports higher-kinded types, similar to languages such as Haskell.

Kinds may be thought of as the "types of types": i.e. a value has a type, and a type has a kind.
All the types described above (e.g. `Maybe Integer` or `[Integer]`) have kind `*` -- that is, they are the type of a value.
However, higher-kinded types also exist.  `Maybe` by itself has kind `* -> *`;
it can be thought of as a type-level "function" that expects to be applied to one type argument.
`[]` is the unapplied list type constructor, also of kind `* -> *`;
`[Integer]` is just syntactic sugar for `[]<Integer>`.

Type variables may refer to higher-kinded types.
> _**Example:**_ _`f`_ has kind `* -> *`:
```
function foo
[f<a>] ::= mkF::(f<a> ::= a) xs::[a]
{
  return map(mkF, xs);
}
```

Silver does its best to figure out the kinds of type variables, but by default it assumes types to have kind `*`.
Kind signatures can help if Silver infers the wrong kind, and are also helpful as documentation.

Higher-kinded types are often seen in conjunction with type classes.
> _**Example:**_ The `Functor` type class defines a `map` operation of over types that wrap a value.
> _`f`_ has a kind signature: it is declared to have kind `* -> *`
```
class Functor (f :: * -> *) {
  map :: (f<b> ::= (b ::= a) f<a>);
}
```

Types of kind `* -> * -> *` and higher can be partially applied; all unsupplied type arguments must be provided as `_`.
> _**Example:**_ `Either` has kind `* -> * -> *`, so `Either<String _>` has kind `* -> *`; `Either<String>` is illegal.

Partially-applied type arguments must be filled in from left to right;
it is illegal for a supplied type argument to follow one that is not supplied.
> _**Example:**_ `Either<_ String>` is illegal.

Function types can also be partially applied by writing a function signature type containing `_` in place of parameter/result types.
When a higher-kinded function type is applied, the parameter types are filled in before the return type.
> _**Example:**_ `(_ ::= Integer _)` has kind `* -> * -> *`;  writing
> `(_ ::= Integer _)<String Boolean>` is equivalent to `(Boolean ::= Integer String)`.

Nonterminal types may also be parameterized by higher-kinded type variables,
resulting in kinds such as `(* -> *) -> *`.
> _**Example:**_ Higher-kinded type parameters are somewhat uncommon,
> but one place where they are useful is for something known as _monad transformers_,
> such as `MaybeT`:
```
synthesized attribute run<a> :: a;

nonterminal MaybeT<(m :: * -> *) (a :: *)> with run<m<Maybe<a>>;

abstract production maybeT
top::MaybeT<m a> ::= x::m<Maybe<a>>
{
  top.run = x;
}

```
> Here `MaybeT` has kind `(* -> *) -> * -> *`: it transforms a type of kind `* -> *` into a type of kind `* -> *`,
> e.g. `MaybeT<[] _>` is a type of kind `* -> *`, and `Maybe<[] Integer>` has kind `*`.

Type aliases can also have kinds other than `*`.
> _**Example:**_
```
type Optional = Maybe;
```
> declares `Optional` as a type alias of kind `* -> *` for `Maybe`

Note that type aliases that are declared with type parameters aren't really types --
they must be fully applied everywhere that they are referenced.
Permitting them to be partially applied would make type checking undecidable.
> _**Example:**_ For the type alias
```
type MyEither<a b> = Either<a b>;
```
> writing just the type `MyEither` or `MyEither<Integer _>` would be an error,
> since `MyEither` must be applied to two type arguments everywhere that it is used.
