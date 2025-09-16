---
title: Debugging with CodeProber
weight: 950
---

[CodeProber](https://codeprober.org/) is a very helpful tool for debugging compilers,
built by Anton Risberg Alaküla at Lund University.
It enables one to explore syntax trees and view the values of attributes using a graphical interface.
Installation instructions and demos can be found on [GitHub](https://github.com/lu-cs-sde/codeprober).

## Setting up CodeProber with a Silver project
Silver has been adapted to work with CodeProber. All that is required is to define an entry point function
`codeProberParse`, which can be in the same grammar as `main`.
This function should take a `[String]` argument and return an `IO` action of any `Decorated` type.
The file to parse will be provided as the last item in the list, preceded by any extra arguments specified in the interface.
For example:
```
fun codeProberParse IO<Decorated Root> ::= args::[String] = do {
  when_(null(args), fail("Invalid arguments to codeProberParse"));
  let fileName = last(args);
  content <- readFile(fileName);
  let result = parse(content, fileName);
  when_(!result.parseSuccess, fail(result.parseErrors));
  return decorate result.parseTree.ast_Root with {};
};
```
Then the CodeProber server can be launched as
```
java -jar /path/to/codeprober.jar mylang.jar
```
This will print a local URL from which to explore the tree in the browser.

## Tips
CodeProber can also be given a workspace directory, allowing it to view and edit files instead of only a temporary buffer in the browser.
```
java -Dcpr.workspace=/path/to/workspace -jar /path/to/codeprober.jar mylang.jar
```

Additional command-line arguments can also be passed when invoking the jar.
For example, to launch CodeProber for the ableC-prolog extension, one can run in the `ableC-prolog` directory
```
java -Xss8M -Dcpr.workspace=.. -jar ../../codeprober/codeprober.jar compiler.jar -Iinclude -I../../extensions/ableC-string/include -I../../extensions/ableC-allocation/include -I../../extensions/ableC-constructor/include -I../../extensions/ableC-template-constructor/include -I../../extensions/ableC-vector/include -I../../extensions/ableC-unification/include
```

CodeProber can also be used for debugging the Silver compiler when building a Silver project, for example:
```
java -Xss20M -Xmx7G -Dcpr.workspace=/path/to/project -jar /path/to/codeprober.jar jars/silver.compiler.composed.Default.jar -I /path/to/project/grammars/ project:grammar:name
```

For better performance, try changing the "AST cache strategy" in the settings tab to "Full".  This will cause each probe to be computed on the same underlying tree, rather than re-computing all attributes for each probe.
