---
title: Implicit Monads
weight: 200
---

{{< toc >}}


Implicit use of monads allows us to write equations in a manner similar to inference rules in their simplicity, only considering success cases, and ignoring the presence of the effect represented by the monad.
Equations can be written which use monadic values as if they did not have monads in their types and which do not include results for failure cases.
We then rewrite these equations using monadic operations to include failure cases.

Consider the following inference rule for typing an application in the simply-typed lambda calculus:
```
  Gamma |- t1 : T1 -> T2    Gamma |- t2 : T1
----------------------------------------------
             Gamma |- t1 t2 : T2
```
In this rule, we are able to assume that `t1` and `t2` will be typable, and that they will type to the appropriate types for the application itself to be typable.
These assumptions make this rule easy to write and read, but inapplicable to error cases.
In contrast, in attribute equations, we want our equations to always give a result, so we must consider the error cases where the subterms are untypable or they are typable but the application itself is not.
The following fragment of a Silver grammar shows this, using a `Maybe` type for potential failure of typing:
```
inherited attribute Gamma::[Pair<String Type>];
synthesized attribute ty::Maybe<Type>;

abstract production app
top::Tm ::= t1::Tm t2::Tm
{
  t1.Gamma = top.Gamma;
  t2.Gamma = top.Gamma;
  top.ty = case t1.ty, t2.ty of
           | just(arrow(T11, T12)), just(T2) ->
             if typesEqual(T11, T2)
             then just(T12)
             else nothing()
           | _, _ -> nothing()
           end;
}
```
Here we need to match on whether `t1` and `t2` are typable, as well on whether `t1` has a function type, then consider whether `t2` has the correct argument type.
If any of these checks fail, we must explicitly state that typing failed by outputting a `nothing()`.

Implicit monad use makes this equation much simpler.
We can assume `t1.ty` and `t2.ty` are built by `just`, meaning they are typable, and then simply check that `t1` has a function type and `t2` has the correct argument type.
We do not need to write the failure cases, only the success cases, resulting in the following equation for `ty`:
```
  top.ty = case t1.ty of
           | arrow(T1, T2) ->
             if typesEqual(T1, t2.ty)
             then T2
             end
           end;
```
Our rewriting will translate this into an equation equivalent to the original equation from above, which always gives a result, success or failure.

The implementation described in this page is based on our SLE paper [Monadification of attribute grammars](https://doi.org/10.1145/3426425.3426941).

We have started to make use of monadification in our software (such as in [this pull request](https://github.com/melt-umn/ableC/pull/176#issuecomment-731640092)).
We plan to continue to use it to reduce boilerplate.


## Monads

In general, a monad is a functor with particular operations called bind, return, and, optionally, fail.
In non-Silver notation, bind takes a monadic value of type `M<T>` and a function of type `T -> M<S>` and gives a value of type `M<S>`, propagating a monadic value through a computation.
Return takes a non-monadic value and turns it into a monadic value.
Fail, which a particular monad may or may not have, creates a monadic value representing failure, as with `nothing()` in the example above.

At this time, Silver does not have type classes, a prerequisite for defining general-purpose monads.
Until this changes, we are limited to the specific monads which Silver explicitly includes.
These monads (functors over type `T`) are:
* `Maybe<T>`, with constructors `just(T)` for success and `nothing` for failure
* `Either<S T>`, with constructors `right(T)` for success and `left(S)` for failure with an error code of type `S`
* `[T]`, a list representing nondeteriministic computations
* `State<S T>`, representing a computation resulting in type `T` carrying a computational state of type `S`
* `IOMonad<T>`, threading input and output through a computation resulting in type `T`

While all of these monads are supported for implicit use, our main focus is on the first two.


## Attribute and Equation Modes

Our rewriting scheme requires three modes for soundness:  restricted, implicit, and unrestricted.
The implicit mode is the most significant part of our rewriting, so we leave the more in-depth discussion of it until last.


### Restricted

Restricted attributes are intended to be the semantic attributes without effects.
For example, the typing context `Gamma` we saw above for the simply-typed lambda calculus would be a restricted attribute.

Restricted attributes must be declared to be restricted.
For example, the `Gamma` attribute would be declared as follows:
```
restricted inherited attribute Gamma::[Pair<String Type>];
```

Restricted equations (equations for restricted attributes) may only access restricted attributes in them; they may not access implicit or unrestricted attributes.
For example, this means equations for `Gamma` may not access `ty`, which will be an implicit attribute.
They may not use monads implicitly, meaning they must treat monadic values as if they are monadic.

Restricted equations may optionally be marked by `restricted`, giving an equation such as
```
restricted t1.Gamma = ...
```


### Unrestricted

Unrestricted attributes are intended for the extras which are generally not considered part of the language semantics, but which make the compiler or interpreter being defined usable.
For example, pretty printing or collecting type errors might be unrestricted attributes.

The unrestricted mode is the default mode for attributes.
If an attribute is not declared to be restricted or implicit, it is assumed to be unrestricted.
Unrestricted attributes may also be declared to be unrestricted:
```
unrestricted synthesized attribute errors::[String];
```

Unrestricted equations may access attributes in any mode.
An equation for type errors for our application production might look like this:
```
  top.errors = case t1.ty, t2.ty of
               | just(arrow(T11, T12)), just(T2) ->
                 if typesEqual(T11, T2)
                 then []
                 else ["Type mismatch in application"]
               | just(arrow(_, _)), nothing() -> []
               | just(T), _ -> ["Non-function applied"]
               | _, _ -> []
               end ++ t1.errors ++ t2.errors;
```
Even though `ty` will be an implicit equation, where we will pretend it does not have a `Maybe` type, we can match on the `Maybe` type's constructors here to determine whether or not to generate type errors.
In fact, we *must* match on the `Maybe` type's constructors to correctly determine whether to generate error messages.
Unrestricted equations must treat monadic values explicitly, as restricted equations must.

As with restricted equations, we may optionally mark unrestricted equations:
```
  unrestricted top.errors = ...
```


### Implicit

Implicit attributes are the heart of our scheme.
They are intended for effectful attributes, such as possibly-failing typing, and provide a way for us to write equations while ignoring the presence of effects.
As with restricted attributes, implicit attributes must be declared:
```
implicit synthesized attribute ty::Maybe<Type>;
```
The type of an implicit attribute must be a monadic type.
If the type is not monadic, there is no purpose in making the attribute implicit, and it should be restricted instead.

Implicit equations may access restricted attributes or other implicit attributes, provided the other implicit attributes have the same monad as the attribute being defined.
They may treat monads implicitly, meaning ignoring the presence of the monad, as we saw in the improved equation for typing the application above.
In fact, implicit equations may not treat monads explicitly.
This means they may not match on monadic type constructors, and they may not apply functions which expect a value of a monadic type as an argument.

Consider again the implicit equation for typing an application from above:
```
  top.ty = case t1.ty of
           | arrow(T1, T2) ->
             if typesEqual(T1, t2.ty)
             then T2
             end
           end;
```
There are several places where we treat our monad implicitly here:
* When we match `t1.ty` against the `arrow` type constructor, we are ignoring the monad on the type of `t1.ty` and treating it as a bare value of type `Type`.
* When we use `t2.ty` as an argument to the `typesEqual` function, we are ignoring the monad on the type of `t2.ty` and treating it as a bare value of type `Type`.
* We do not write the failure cases here for if `t1` does not have an arrow type or if `t2` does not have the expected argument type.
* We also do not write the failure cases for if `t1` or `t2` is untypable.

We can follow the same pattern of ignoring the monad on the type when using other operations in Silver.
For example, if we have an attribute `x : Either<String Integer>`, we could write an equation
```
  top.x = t1.x + t2.x;
```
or any other operation allowed for expressions of type `Integer`.
In general, if an operation is allowed for an expression of type `T`, it may be used in an implicit equation for an expression of type `M<T>`, where `M` is any monad.

Implicit equations, as the other modes, may also be optionally marked:
```
  implicit top.ty = ...
```


## Using Implicit Equations to Gather Error Messages

One use of implicit equations is to generate error messages while not needing to duplicate the actual equation for typing or another analysis.
For example, in the equation for `errors` in an application we see above, we are duplicating and even expanding on the original typing equation.
Using an `Either` implicitly, we can generate error messages at the same time as determining the type of the application.

We have the attributes `Gamma` and `errors` as before, but we change the type of our `ty` attribute to use an `Either` monad:
```
implicit synthesized attribute ty::Either<String Type>;
```
We then write an implicit equation for `ty` as above, but filling in the cases where the subterms are typable and the application is not with error messages:
```
  top.ty = case t1.ty of
           | arrow(T1, T2) ->
             if typesEqual(T1, t2.ty)
             then T2
             else left("Type mismatch in application")
           | _ -> left("Non-function applied")
           end;
```
While we can't use monadic values explicitly in implicit equations, we can write monadic failures, as with the uses of `left` above.
We aren't using the failure values resulting from these explicitly, which is why it is permissible to write them.

We can then write an equation for `errors` which checks whether `top.ty` is a `left` to add error messages to the list:
```
  top.errors = case top.ty, t1.ty, t2.ty of
               | left(s), right(_), right(_) -> [s]
               | _, _, _ -> []
               end ++ t1.errors ++ t2.errors;
```
This equation for `errors` filters out any repeated errors from the subterms.
For example, if `t1.ty` is `left(s)` for some `s`, `top.ty` would also be `left(s)` because the error message is passed up through the equation.
By matching on `top.ty`, `t1.ty`, and `t2.ty`, we ensure that we aren't getting an error message from a subterm twice.
However, this might miss some errors we might like; for example, if `t2.ty` is a `left` and `t1.ty` is `right(boolType())`, we would like to get the error from `t2.ty` and the error for `t1` not being a function.
We could do this either by reverting to the original `errors` equation we had above, or by not filtering out repeated error messages.
An alternative equation for `errors` is
```
  top.errors = case top.ty of
               | left(s) -> [s]
               | right(_) -> []
               end ++ t1.errors ++ t2.errors;
```
This equation can include the same error multiple times, but it ensures all the errors we produce are gathered.
If the error message is made more specific to the error causing it, such as by adding a location in the file (e.g. `left("Line 35:  Non-function applied")`, the duplicated errors could be filtered out at the point they are to be reported to the user.


## Empty Equations for Implicit Attributes

We add a new type of equation, called an empty equation, for implicit attributes.
This equation does not have an expression on its right-hand side:
```
  implicit top.a = ;
```
An empty equation can be used to show that there is no non-failure value an attribute could have.

Consider small-step evaluation in the simply-typed lambda calculus.
We have an attribute `next` for the next evaluation step:
```
  implicit synthesized attribute next::Maybe<Tm>;
```
Abstractions are values which cannot take an evaluation step, so they must have a failure value for `next`.
We could accomplish this by writing an equation explicit assigning `nothing()` for `next`.
Instead, we write an empty equation, which is equivalent to explicitly writing the failure value:
```
abstract production abs
top::Tm ::= x::String T::Type body::Tm
{
  implicit top.next = ;
}
```
This fits better with the philosophy of implicit use, where we want to ignore the presence of the monad.
It shows that there is no value of type `Tm` which makes sense for the next step of evaluation an abstraction.

We require the marking `implicit` to avoid writing accidental empty equations.
Not requiring the marker could lead to accidental empty equations being introduced by forgetting to fill in an equation with the correct expression, leading to difficult-to-identify bugs.


