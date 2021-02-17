---
title: Convenience Aspects
weight: 300
---

{{< toc >}}

```
attribute foopp occurs on BarExpr;

aspect foopp on top::BarExpr of
| barInit1([],_) -> "emptyFoopp"
| barInit1(h::t,_) -> h ++ "Foopp" ++ top.hiddenAttr
| barInit2(h :: t,value) -> h ++ " and then " ++ toString(value)
| barInit3(_,val) -> toString(val) ++ top.hiddenAttr
| barInit4() -> "Foopp"
| _ -> top.hiddenAttr
end;
```

Convenience Aspects offer a means of defining aspect productions for a particular attribute in a much easier manner, using a more concise syntax.


> _**Example:**_

To start with, here's a small example. The following two code sections have the same semantics.

```
attribute foopp occurs on FooExpr;

aspect foopp on FooExpr of
| addfoo(l, _) -> "foo " ++ l.prettierprint
| subtractFoo(l,r) -> "foo " ++ l.prettierprint ++ "-" ++ r.prettierprint
| _ -> "default"
end;

```

```
attribute foopp occurs on FooExpr;

aspect production addfoo
top::FooExpr ::= l::FooExpr r::FooExpr
{
  top.foopp = "foo " ++ l.prettierprint;
}
aspect production subtractFoo
top::FooExpr ::= l::FooExpr r::FooExpr
{
  top.foopp = "foo " ++ l.prettierprint ++ "-" ++ r.prettierprint;
}
aspect default production
top::FooExpr ::=
{
  top.foopp = "default";
}
```

## Syntax

Specified in roughly similar manner as [EBNF form](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form ). Using Convenience aspects involves constructing them with this syntax.

```
'aspect' <attr-name> 'on' [<custom-top-name>::]<type> ['using' ('<-' | ':=' | '=') ] 'of' '|' <match-rule-list> 'end' ';'
```

`attr-name` refers to the name of the attribute you want to define aspect productions for. 

`match-rule-list` is a list of patterns constructed much like pattern matching. The subpatterns beneath them can be any valid pattern for pattern matching, but the pattern at the top should
only be `varPattern` (where you just provide a name),`Production Patterns`, or `Wildcard` patterns only.

The term `'using' ('<-' | ':=' | '=')` means that you can provide the operator that is used to assign to your new attribute. It defaults to `=` if you don't provide this.

`custom-top-name` allows you to use other attributes from the production to define your attribute.

An example below demonstrates `custom-top-name` and `using`, where `custom-top-name` is set as "top"

> _**Example:**_
```
synthesized attribute bagList :: [String] with ++ occurs on BazExpr;

aspect bagList on top::BazExpr using <- of
| bazInit2(h::t,value) -> [h, toString(value)]
| bazInit3(_,val) -> [top.hiddenAttr]
| bazInit4() -> explode(top.hiddenAttr,"\t")
| _ -> []
end;
```

You can also define your custom name using a `varPattern`, like so (the last pattern demonstrates this), but only for the default production will this one work.

```
synthesized attribute gAttribute :: String occurs on BazExpr;
aspect gAttribute on BazExpr of
    | bazInit2(h::t,value) -> h ++ toString(value)
    | bazInit3(_,val) -> toString(val)
    | coolName -> coolName.hiddenAttr
end;
```


Note that `varPatterns` and `Wildcard` patterns can shadow other ones, as in the following, where the `bazInit3(_,val)` aspect production is not made, because the `coolName` varPattern shadows it.

```
aspect bagList2 on top::BazExpr using <- of
| bazInit2(h::t,value) -> [h, toString(value)]
| coolName -> coolName.hiddenAttr
| bazInit3(_,val) -> ["ignored", toString(val)]
end;

```
