---
title: Insert semantic token
weight: 300
---


```
imports silver:langutil:lsp as lsp;

terminal IdTypeDcl '' lexer classes {lsp:Type, lsp:Declaration};

concrete production nonterminalDcl
top::AGDcl ::=  'nonterminal' id::Name ';'
{
  top.unparse = "nonterminal " ++ id.unparse ++ ";";

 ...
} action {
  insert semantic token IdTypeDcl_t at id.location;
}
```

The `insert semantic token` action specifies an additional terminal that should be inserted in the list of terminals returned by the parser. These "semantic tokens" do not appear in the concrete syntax tree in any way, but only in the token stream returned by the parser. Terminals are inserted at the appropriate position in the list of parsed terminals according to the start character index in their location.

This may be useful if the parser is used for syntax higlighting purposes, e.g. in a semantic tokens feature of a language server implementation, where tokens are encoded based on the lexer classes of the terminals returned by the parser. Sometimes the desired semantic tokens do not exactly line up with the terminals used in the grammar, and so we would like to emit additional terminals with different or more specific semantic token types.
