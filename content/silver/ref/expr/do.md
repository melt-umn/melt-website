---
title: Do
weight: 400
---

{{< toc >}}


## Do notation

Do notation is provided as semantic sugar for expressing complex [monadic](/silver/concepts/monads) computations.

At its simplest, a do expression looks something like:
```
do {
  <action1>;
  val1 <- <action2>;
  val2 <- <action3 involving val1>;
  <action 4 involving val1 and 2>;
  return <expression involving val1 and 2>;
}
```
Each action has a monadic type, and the vals are names.  This translates to a sequence of binds, of the expressions on the right hand side of <- and a lambda with val1 as a parameter and the translation of the rest as the body.
Sometimes we want to ignore the value returned by an action, in which case the lambda has a dummy parameter that gets ignored.
`return` is simply syntactic sugar for calling `pure`.

We sometimes may also wish to bind non-monadic values within a monadic computation.  We may also wish to conditionally perform monadic actions, by nesting `do`-expressions inside of `if`s.  For example:
```
local result::IOMonad<Integer> = do {
  txt::String <- readFileM("file.txt");
  let isEmpty::Boolean = length(txt) == 0;
  if isEmpty then
    printM("Empty!\n)
  else pure(());
  if txt == "Hello" then do {
    printM("World");
    return 2;
  }
  else
    pure(length(txt));
};
```

The `bind` and `pure` operations for any particular monadic type are specified via type classes.  Silver also implements [GHC's applicative do desugaring](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/applicative_do.html), using the `map` and `ap` methods of the `Functor` and `Applicative` type classes in place of `bind` where possible; this sometimes allows for better efficiency.  

## MDo notation
While Silver generally supports recursive and mutually-recursive bindings globally and in production bodies,
the bindings within a monadic computation can typically only refer to previous bindings.
This is sometimes an annoying limitation - for example in dealing with lists as lazy "streams" of data, as found in the Silver driver:
```
rootStream :: [Maybe<RootSpec>] <-
  unsafeInterleaveIO(compileGrammars(svParser, benv, grammarStream, a.doClean));

let grammarStream :: [String] =
  buildGrammars ++
  eatGrammars(length(buildGrammars), buildGrammars, rootStream, unit.grammarList);

let unit :: Decorated Compilation =
  decorate
    compilation(
      foldr(consGrammars, nilGrammars(), catMaybes(rootStream)), ...)
  with ...;
...
```
Here `rootStream` depends on `grammarStream`, which depends on `unit`, which depends on `rootStream`.

Recursive monadic computations can be defined by wrapping them in the monadic fixed-point combinator `mfix :: (m<a> ::= (m<a> ::= a))`,
defined by the [`MonadFix`](/silver/gen/silver/core/Monad/#class_MonadFix) type class.
Since doing this manually can be somewhat tedious, Silver supports the mutually-recursive `mdo` notation [as found in Haskell](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/recursive_do.html).
`mdo` syntax is identical to regular `do`, except that all bindings are mutually visible.
`mdo` is desugared to an ordinary `do` by inserting `mfix` where needed.  Consider the following (contrived) example:
```
mdo {
  setState(123);
  even :: (Boolean ::= Integer) <- pure(\ x::Integer -> if x == 0 then true else odd(x - 1, ()));
  setState(456);
  let odd :: (Boolean ::= Integer ()) = \ x::Integer () -> if x == 0 then false else even(x - 1);
  i::Integer <- getState();
  return even(i);
}
```
This desugars to
```
do {
  setState(123);
  _rec_res_1 :: ((Boolean ::= Integer), (Boolean ::= Integer ())) <-
    mfix(\ _rec_res_1 :: ((Boolean ::= Integer), (Boolean ::= Integer ())) -> do {
      let even :: (Boolean ::= Integer) = _rec_res_1.1;
      let odd :: (Boolean ::= Integer ()) = _rec_res_1.2;
      even :: (Boolean ::= Integer) <- pure(\ x::Integer -> if x == 0 then true else odd(x - 1, ()));
      setState(456);
      let odd :: (Boolean ::= Integer ()) = \ x::Integer () -> if x == 0 then false else even(x - 1);
      return (even, odd);
    });
  let even :: (Boolean ::= Integer) = _rec_res_1.1;
  let odd :: (Boolean ::= Integer ()) = _rec_res_1.2;
  i::Integer <- getState();
  return even(i);
}
```