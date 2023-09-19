---
title: Silver Language Server
---

{{< toc >}}

We have developed an implementation of the [Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol/)
for Silver, and a corresponding VS Code extension to provide highlighting, error reporting and other features.

## Installation

First, [install VS Code](https://code.visualstudio.com/download) and a recent (>11) version of Java.
Ensure that the `JAVA_HOME` environment variable is set to the place where Java is installed.
This may or may not happen automatically, depending on your operating system; I needed to add
```
export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64
```
to `~/.profile`.

There are a few different ways of installing the VS Code extension.

### From the extension marketplace

The extension is published on the VS Code extension marketplace; simply search for the extension "Silver LSP" with publisher MELT.
Note that this may not always be up to date with the latest version of Silver.
An alternative version of the Silver compiler can be specified in the extension settings by providing a path to `silver/jars/silver.composed.Default.jar` in your installation of Silver,
however this may misbehave if breaking changes have been made to the portions of the Silver compiler called from Java code in the language server implementation.

### From the latest build

A Jenkins-updated build of the extension, corresponding to the latest version of Silver on `develop`, is also available [on our downloads page](/downloads)
packaged as a `.vsix` file.  This can be installed in VS Code with the command `Extensions: Install from .VSIX...`.

See [below](#building-locally) for instructions on how to build the extension locally for development.


## Using the extension

The extension should provide errors and semantic highlighting for all Silver files in the VS Code workspace.
If you aren't seeing error messages, try checking the output view to see if something went wrong.
If the compiler does crash for some reason, this requires reloading VS Code.

The Silver compiler is a bit memory hungry, and stack hungry too.
For large projects such as Silver and ableC, you may need to increase the stack/heap space and/or disable
the [modular well-definedness analysis](/silver/concepts/modular-well-definedness) in the extension settings.

### Useful features

The language server supports the "find definition" and "find references" requests for values, types and attributes.
This can be used from VS Code by right-clicking on a name and choosing "Go to Definition/References" or "Find All References".
Note that there are a few bugs in these when dealing with features that are extensions in the Silver compiler, such as pattern matching.

There is a command "Clean Silver language server workspace" that performs a clean rebuild of all grammars.
In the future, we hope to add support for additional commands to perform refactoring, generate stub aspect definitions, etc.

### Using alternate extended versions of Silver

The language server can be made to work with extensions to the Silver compiler, such as extensions to provide concrete syntax quotation for other object languages like ableC.
For example, a workspace for ableC might contain the repos for silver, ableC, silver-ableC, and a number of ableC extensions.
To use the silver-ableC extension features, one must change a couple of settings;
"Compiler jar" should point to the path of the extended compiler jar,
e.g. `/home/lucas/melt/extensions/silver-ableC/jars/edu.umn.cs.melt.exts.silver.ableC.composed.with_all.jar`,
and "Parser Name" should be the full name of the extended Silver parser specified in the composed artifact grammar,
in this case `edu:umn:cs:melt:exts:silver:ableC:composed:with_all:svParse`.

### Using the Silver plugin to develop Silver

The VS Code extension is packaged with the grammars for Silver's standard library, such as `silver:core`, `silver:util` and `silver:langutil`.
However if the silver repository is included in a workspace, the workspace version of these grammars will override the packaged ones.
I typically also set the "Compiler jar" to `jars/silver.composed.Default.jar` to use my latest, locally built Silver jars.

Running the MWDA on Silver is very slow and resource intensive; I typically leave it disabled except when tracking down flow errors.
When running the analysis I have the JVM args set to `-Xmx12G -Xss40M`.  This may not be feasible on a machine with <16 GB of RAM.

There is also an issue where sometimes the language server process is not killed upon closing or reloading VS Code.
If you notice an excessive number of Java processes hogging memory, you can run `pkill -9 java` to kill them all;
the active VS Code instance will automatically re-launch its language server.

## Silver language server development

### Code structure

The language server is implemented using the [LSP4J](https://github.com/eclipse-lsp4j/lsp4j) library,
which provides Java bindings for the language server protocol.

* There are some utilities for hooking up Silver code to LSP4J, located at `silver/runtime/lsp4j`;
this is intended for reuse in implementing language servers for other languages with Silver implementations.
* The source of the Silver-specific language server is at `silver/language-server/langserver`.
`SilverLanguageServer.java` is the top-level class that deals with initialization;
most of the logic for responding to various requests is in `SilverLanguageService.java`.
`SilverCompiler.java` provides an abstraction around running builds and querying information from the most recent compilation results.
* A launcher using standard I/O channels, as needed for VS Code and the most common use cases, is at `silver/language-server/launcher`.
* The VS Code extension itself is located under `silver/support/vs-code/silverlsp`.

### Building locally

Building the language server and VS code extension locally requires installing Maven and npm.

First, check out Copper and install it to your local Maven repo:
```
git clone git@github.com:melt-umn/copper.git
cd copper/
mvn install
cd ..
```
This should only be needed once; this step is needed because we haven't yet been able to publish Copper to the Maven central repository.

Next, build the language server jar:
```
cd silver/language-server
./build.sh
cd ..
```
This will install the current compiler jars to your local Maven repository, build the common utilities under `silver/runtime/lsp4j`, and build the language server itself.
Note that since the language server, launcher, and most dependencies are versioned Maven artifacts; we are cheating a bit to pull in the Silver compiler.
The language server launcher jar will be located under `silver/language-server/launcher/target/launcher.jar`.

Finally, package the VS Code extension:
```
cd support/vs-code/silverlsp
vsce package
```
This will package the extension as `silverlsp-<version>.vsix`.

For convenience, there is also a top-level script `make-vscode-extension` that cleans everything, builds the language server and packages the extension.

### Other editors

In theory, our Silver language server implementation should work with other editors/IDEs that support that support the language server protocol.
The language server launcher jar can be built following the above instructions.
The available configuration settings and commands accepted by the VS Code extension can be found [here](https://github.com/melt-umn/silver/blob/develop/support/vs-code/silverlsp/package.json);
all are checked by the language server aside from `silver.jvmArgs` and `silver.compilerJar`,
which respectively control the JVM flags and an optional extra classpath jar passed to `java` when starting the server.

If you get the Silver language server working with another editor, feel free to contribute any editor modes or configurations that you develop!
