---
title: Type class and instance declarations
weight: 600
---

Silver supports ad-hoc polymorphism via type classes.  These are closely modeled on [type classes in languages such as Haskell](https://www.haskell.org/tutorial/classes.html).

## Class and Instance Declarations
```
class Eq a {
  eq :: (Boolean ::= a a) = \ x::a y::a -> !(x != y);
  neq :: (Boolean ::= a a) = \ x::a y::a -> !(x == y);
}

instance Eq Integer {
  eq = eqInteger;
  neq = neqInteger;
}

instance Eq Float {
  eq = eqFloat;
}
```

`Eq` is a type class in the standard library, providing the functions `eq` and `neq` (the `==` and `!=` operators forward to calls to these functions.)  Implementations of these functions are provided for various types by defining _instances_.  The `Eq` type class provides defaults for both of these methods, such that instances need only provide an implementation for one function or the other.

## Type constraints
Type classes may be used as constraints on variables in type signatures; any constraints on a function's type must be resolved in order to use the function.  The members of a type class automatically have the declared class as a constraint; for example in type checking `eq(42, 128)` the constraint `Eq Integer` must be resolved, by looking up that instance.

Function and production signatures can also introduce type constraints, allowing type class members to be used with polymorphic types:
```
function allEqual
Eq a => Boolean ::= xs::[a]
{
  return
    case xs of
    | h1 :: h2 :: t -> h1 == h2 && allEqual(h2 :: t)
    | _ -> true
    end;
}
```

## Instance constraints
Instances can also have type constraints:
```
instance Eq a => Eq [a] {
  eq = \ x::[a] y::[a] -> length(x) == length(y) && all(zipWith(eq, x, y));
  neq = \ x::[a] y::[a] -> length(x) != length(y) || any(zipWith(neq, x, y));
}

instance Eq a => Eq Maybe<a> {
  eq = \ x::Maybe<a> y::Maybe<a> ->
    case x, y of
    | just(w), just(z) -> w == z
    | nothing(), nothing() -> true
    | _, _ -> false
    end;
}

instance Eq a, Eq b => Eq Pair<a b> {
  eq = \ x::Pair<a b> y::Pair<a b> -> x.fst == y.fst && x.snd == y.snd;
  neq = \ x::Pair<a b> y::Pair<a b> -> x.fst != y.fst || x.snd != y.snd;
}
```
To satisfy any of these instances, the constraints on the matched instance must be satisfied as well.  For example `eq([42], [42])` would need to satisfy `Eq [Integer]`, which matches the instance `Eq [a]`, in turn giving the constraint `Eq Integer` that must be satisfied.

## Superclasses
Type classes can extend existing type classes with additional members:
```
class Eq a => Ord a {
  compare :: (Integer ::= a a) = \ x::a y::a ->
    if x == y then 0 else if x <= y then -1 else 1;
  
  lt :: (Boolean ::= a a) = \ x::a y::a -> compare(x, y) < 0;
  lte :: (Boolean ::= a a) = \ x::a y::a -> compare(x, y) <= 0;
  gt :: (Boolean ::= a a) = \ x::a y::a -> compare(x, y) > 0;
  gte :: (Boolean ::= a a) = \ x::a y::a -> compare(x, y) >= 0;
}

instance Ord Integer {
  compare = \ x::Integer y::Integer -> x - y;
  lt = ltInteger;
  lte = lteInteger;
  gt = gtInteger;
  gte = gteInteger;
}

instance Ord a => Ord [a] {
  lte = \ x::[a] y::[a] ->
    case x, y of
    | h1::t1, h2::t2 -> h1 <= h2 && t1 <= t2
    | [], _ -> true
    | _, _ -> false
    end;
}
```
Here the `Ord` type class extends `Eq`.  Any constraint `Ord a` implicitly also adds a constraint for `Eq a`, and any instance of `Ord` must have a corresponding instance of `Eq` for the same type.

## Higher-kinded type classes
Type classes can be defined for [higher-kinded types](/silver/concepts/types#kinds).  For example, the `Functor` type class has kind `* -> *`:
```
class Functor (f :: * -> *) {
  map :: (f<b> ::= (b ::= a) f<a>); 
}

instance Functor [] {
  map = \ f::(b ::= a) l::[a] ->
    if null(l) then []
    else f(head(l)) :: map(f, tail(l));
}

instance Functor Maybe {
  map = \ f::(b ::= a) m::Maybe<a> ->
    case m of
    | just(x)   -> just(f(x))
    | nothing() -> nothing()
    end;
}
```
