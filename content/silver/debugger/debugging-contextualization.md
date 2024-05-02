# Contextualization Overview

## Theoretical View
- For the theoretical details of debugging contextualization, see Matthew Feraru’s honors thesis “Abstract Syntax Contextualization Framework for Debugging Attribute Grammar Specifications.” ***[TODO: insert link to thesis in UMN conservatory once uploaded within a couple of months].*** 
- The key idea of contextualization is to represent the location of the currently navigated-to node within an abstract syntax tree (AST) textually. This is mainly done through concrete syntax representations of nodes, concrete syntax highlighting, and a set of labels that describe the applications of Silver forwarding or higher-order attributes that generate AST subtrees. (Note that the "is-new" label cannot be implemented in Silver due to the current limitations of origin tracking).

## What is contextualization for debugging?
The thesis abstract:

`In this thesis, we explore an aspect of debugging attribute grammar (AG) specifications. AG frameworks in themselves are high-level languages that allow a
programmer to specify the syntax rules and semantics of a new programming language. The debugging of AG specifications is often done by interactively traversing abstract syntax trees (ASTs) that represent a parsed program in a meta-program. The goal of such debugging is to find AG specifications with semantic rules that observe correct inputs but incorrect outputs—the possible bugs of AG specifications.`

`For large programs, ASTs may be difficult to understand by a programmer; graphically rendering ASTs in a debugging interface is challenging and still does not make it straightforwardly easy to understand ASTs relative to source code. Resultantly, we propose a textual way to use source and source-like syntax to represent the location of a navigated-to AST node relative to its position in an entire AST and highlight any notable features of the tree, such as the application of reduction grammars. This contextualization framework of abstract syntax tree nodes has been prototyped to work on Silver [1] specifications, but it is applicable to any AG framework since it only relies on the core features of the AG paradigm itself.`

# Dependencies Overview

- All necessary contextualization information for an AST "node" visited comes from `DecoratedNode` in the Silver Java `core` runtime. 
- Information extracted from an instance of a `DecoratedNode` is captured in a `NodeContextMessage` object. They are records of contextualization for a node that is part of the path from the unique (we ignore reference attributes) root to the current navigated-to node. This is because we naturally do a DFS tree traversal while debugging, and hold visited nodes in a stack. 
- During tree navigation, we maintain a stack of `NodeContextMessage` objects implicitly representing the path from AST root to the current node.
- This stack is an instance of `ContextStack` (this is the "full" context stack from the thesis).
- `DecoratedNode` objects are pushed while following edges into the tree and popped when traversing back up into a `ContextStack`. It is the `ContextStack` itself that makes/generates new `NodeContextMessage` objects when new nodes are pushed.
- A `ContextStack` can generate its own verbose contextualization. This is useful for debugging the contextualization classes themselves. 
- To yield a final or "simplified" contextualization, a `SimplifiedContextStack` is employed. It is a heavy-weight wrapper around a (full) `ContextStack` instance. The `SimplifiedContextStack` compresses the stack of `NodeContextMessage` objects within its `ContextStack` into a smaller stack of `SimplifiedContextBox` objects. 
- It is this stack of `SimplifiedContextBox` objects within a `SimplifiedContextStack` instance that is then rendered to give our contextualization.
- `SimplifiedContextStack` supports basic text file and HTML representations currently. 

# Actually Calling the Contextualization
- Interactive debugging is all handled by the `Debug` class. 
## Initialization
- Before the main debugging loop is entered, a `ContextStack cStack` is created/made. (There are different decorating classes around a `ContextStack` if different *intermediate* contextualization representations are required, such as `FileContextVisualization`. These decorators need to return back the `ContextStack` object they are wrapping). 
- A `SimplifiedContextStack sStack` is also initialized with `cStack` as its parameter. 
- Currently, there are two methods to generate final simplified contextualization from `sStack`: `show()` and `generateHTMLFile()`. They, respectively, generate a text or HTML file to a path that can be specified in the constructor of `SimplifiedContextStack`.  
## In debugging loop
- Whenever a command that traverses deeper into an AST is called (e.g., **down** or **forwards**), `cStack.push(currentNode);` is called.
- Following this line, `sStack.show()` or `sStack.generateHTMLFile()` can be called to update the contextualization.
- Recall that `sStack` maintains a reference to `cStack`; whenever `cStack` is updated, then `sStack` will update itself based on its `cStack` when invoked to regenerate its contextualization file.

# File Details
- All files are currently located in the Silver Java runtime in the `core` packet. 
- *TODO: create new debugging package (not just contextualization issue).*

## ` DecoratedNode.java`
### Added Functionality

### To extract concrete syntax for a `DecoratedNode`
- Concrete syntax representations will either be the parsed source syntax associated with a `DecoratedNode` or its pretty print representation.
- The former is to be used only if no *horizontal* edges were crossed to get to this node. *horizontal* edges refer to either forwarding edges (entering rewrite-rules) or "into" higher-order attribute edges because these constructs may introduce nodes that are not associated with parsed syntax. 
- `getPrettyPrint()`. Returns ``pp`` attribute or `Util.genericShow()` if it is not present.
- `getFilename()`. Returns via origin tracking the file name parsed that generated this node.
- `getStartCoordiantes()` and `getEndCoordiantes()`. Return `FileCoordinate` objects. These objects just store a row and column position.
- The combination of a filename, start coordinate, and an end coordiante denote the parsed concrete syntax that generated this node.

### Labels
- These labels are used to represent applications of rewrite rules (forwardings) or higher-order attributes, the two constructs we consider that can generate *horizontal* edges.
- A `redex` is a forwarding node; a `contractum` is a forwarded-to node.
- `getIsRedex()` and `getIsContractum()` represent if a node is involved with a forwarding based on the `forwardParent` field.
- `getRedex()` and `getContractum()` return the first ancestor of a node that has either respective property or null if none.
- `getIsAttributeRoot()`. Returns whether or not this node is the root of a higher-order attribute subtree. This is true if this node is an attribute of its parent node.
- To represent the nesting of forwarding edges, `getIsTranslation()` returns the number of forwarding edges encountered from root to this node (0 if none). 
- To represent the nesting of higher-order attributes for this node, `getIsAttribute()` returns the number of higher-order attribute entry edges encountered from root to this node (0 if none). 
- These implement the "labels" and "headers" further described in Matthew Feraru's thesis ***[TODO: insert link to thesis in UMN conservatory once uploaded within a couple of months].*** for the `NodeContextMessage` record. 

### TODOs
- While these additions are implemented efficiently in `DecoratedNode`, we want to move all of these functionalities to a contextualization utility class to keep `DecoratedNode` as minimal as possible (OK to recompute redexes and contractums on parents each time, etc.).
- Find a way to track reference attributes.
- Higher-order attributes have not been navigated-into yet, so higher-order attribute-related functionality has only been tested to work in the absence of them.

## `FileCoordinate.java`
- Very straightforward container of a row and column index into a file.
### TODO
- Create another wrapping class to represent <FileName, StartFileCoord, EndFileCoord>, a complete concrete syntax file location.


## `NodeContextMessage.java`
### Functionality
- Wrap extracted information from `DecoratedNode` about an individual node part of a path from the current node to the abstract syntax tree root--a record of a node for contextualization purposes.
- They are the elements of the "full"/intermediate stack maintained in a `ContextStack`. This info is then compressed in `SimplifiedContextStack`.
- 4 sections of information are maintained about a node (given as parameter in `NodeConextMessage` constructor.)
1. Section 1. (HEADERS). Headers are either TRANSLATION-X (for rewrite rules) or HIGHER-ORDER (for higher-order attributes). They represent the cumulative nesting of these constructs a current node has relative to the program root. Headers are dependent on a node's labels and its ancestors' labels.
2. Section 2. (CONCRETE SYNTAX). Concrete syntax representation of the current node. Should hold parsed concrete syntax from the source file if headers are empty (no rewrite rules or higher-order attributes traversed yet), or the node's pretty print attribute otherwise.

3. Section 3. (PRODUCTION). Store the production name (we currently keep file lines as well. But they are not needed for the current version of the SimplifiedContextStack). 

4. SECTION 4. (labels). Labels represent whether the current node is involved with horizontal edges. Current possible labels are is-contractum and is-redex (for forwarding relationship) and is-attribute-root (for higher-order attribute subtree roots). Labels are currently extracted from DecoratedNode itself. 

- The `GetSection_()` functions are to intermediately generate a file representation of such a node within a full `ContextStack`. 
- To extract information for a `SimplifiedContextStack`'s `SimplifiedContextBox`es, use the simple getter functions for respective properties, e.g. `isRedex()` or `getProdName()`. 
### TODOs
- Add contextualization labels/any info needed to support **reference attributes**.
- Once remove `ContextStack` and store an intermediate stack of `NodeContextMessage` objects directly in `SimplifiedContextStack`, remove all `GetSection_()` methods. 


## `ContextStack.java`
### Functionality
- Maintain a stack of `NodeContextMessage` objects. Whenever tree navigation occurs, update this stack with the traversal (DFS).
- I.e., if heading deeper into the tree (or across a forwarding edge), `push()` the new current node, and if going up a parent link, `pop()` from the stack.
- This is ultimately an intermediate store of information to generate the final `SimplifiedContextStack` contextualization representation.
- Currently, use `get()` to access individual `NodeContextMessage` objects.
- Can define child classes that inherit from `ContextVisualization` (a wrapper around `ContextStack`) to add extra methods to visualize an intermediate full stack (e.g., `FileContextVisualization` generates a text file)
### TODOs
- Move the stack of `NodeContextMessage` objects directly into `SimplifiedContextStack`; i.e., get rid of `ContextStack` entirely and only ever render a final simplified contextualization.



## `SimplifiedContextStack.java`
### Functionality
- Core of contextualization for debugging: the 'SimplifiedContextStack' is basically a heavyweight decorator over a ContextStack to generate a simplified (one node per tree order/horizontal-edge encountered) stack.
- Its `ContextStack` member `full_stack` is dynamically updated while debugging occurs. Then, extracting a contextualization from a SimplifiedContextStack requires calling 'updateSimplifiedStack()' to create an updated `SimplifiedContextStack` (of `SimplifiedConextBox` objects) based on the current  state of the ContextStack `full_stack`.  
- It currently can print some primitive text representations to a text file, or generate a better HTML file. (Filenames can be specified upon SimplifiedContextStack construction).
- **THIS IS THE FINAL RESULT OF CONTEXTUALIZATION: RENDERING THIS FILE.**

### TODOs
- Move `full_stack` (the wrapped `ContextStack`) updating directly into here; i.e., push/pop nodes into the simplified stack directly and get rid of `ContextStack` entirely.
- Would then maintain a stack of `NodeContextMessage` objects and another stack of `SimplifiedContextBox` objects. The former would be used to update the latter stack.
- Avoid having to rebuild the entire stack each time as a result of this internal updating (instead of relying on `ContextStack` to update). 
- Find better than O(n^2) time complexity for production name assignment

## `SimplifiedContextBox.java`
### Functionality
- The `SimplifiedContextBox` maintains all information needed for an individual element as part of simplified debugging contextualization.
- Objects of this class are the elements of a SimplifiedContextStack.
- One fully represents a path in an abstract syntax tree that has no horizontal edges (edges created by forwarding/translation or higher-order attribute entry links)
- The `SimplifiedContextStack` creates one of these boxes each time it encounters a horizontal edge (plus the original started at the program root).

- Tree Order represents how many horizontal edges have been navigated across (by type separately).
- Text Syntax represents the current path through concrete syntax.
- `text_syntax` should store parsed concrete syntax when (x, y) from tree order are both 0. Otherwise, it will be the pretty print representation. This is for the first production associated with a SimplifiedContextBox (widest-spanning)
- `syntax_to_highlight` should be highlighted within `text_syntax`. It represents the deepest (least-spanning) navigated-to node within the path of productions such a box represents. 
- Productions Visited. Just a list of production names this box's abstract syntax tree path represents. They should be added with increasing tree depth.

- Interesting Features. Records which nodes are associated with horizontal edges themselves. This info comes from `NodeContextMessage` objects stored in the basic ContextStack from which a SimplifiedContextStack is built from.

- There are currently HTML and toString representations of an individual box. When adding/generating HTML, the headers are added within SimplifiedContextStack. 

### TODOs
- *POTENTIAL FUTURE RESEARCH PROJECT:* some extra information while doing tree traversal will be needed to make highlighting unique if there are multiple instances of `syntax_to_highlight` within `text_syntax`.


## `ProductionName.java`
### Functionality
- Simple container for a production name paired with an index.
### TODOs
- Implement an HTML-specific toString() with highlighting.


## `Feature.java`
### Functionality
- Container for a contextualization label (i.e., is-redex, is-contractum, is-attribute-root). 
- Maintains the production name (`baseProd`) it is associated with.
- Also maintains, where applicable, the "`target`" production associated with a label (e.g., the target of a redex is the forwarded-to contractum if visited).
### TODOs
- Implement an HTML-specific toString() with highlighting. 

