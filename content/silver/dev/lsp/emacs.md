---
title: Emacs Support with LSP
---

{{< toc >}}


Emacs LSP support allows for copper specific syntax highlighting through semantic tokens, lookup of declarations (preliminary), and showing errors and warnings in silver buffers. 

## Prerequisites
Above and beyond the standard Silver requirements, you need Maven (to build the silver lsp server), and of course, Emacs (26+ recommended).

## Configuring Emacs prerequisites

To get started, you will need to have the package [lsp-mode](https://emacs-lsp.github.io/lsp-mode/page/installation/)  installed. Note that some features of lsp-mode require additional packages, but configuring lsp-mode is a
bit out of scope of this article. There's more information about the additional features in [here](https://emacs-lsp.github.io/lsp-mode/page/installation/#vanilla-emacs), if you're configuring with vanilla emacs.

Once you have that, you'll also need to have the [silver-mode.el](https://github.com/melt-umn/silver/blob/develop/support/emacs/silver-mode/silver-mode.el)
file loaded in some manner. This can be done by adding the path to the file to your `load-path`.

``` elisp
(add-to-list 'load-path "/path/to/silver/support/emacs/silver-mode/silver-mode.el")
```

But if you do use a package manager like [straight](https://github.com/radian-software/straight.el), I made a recipe for setting up the silver-mode as a package.

```elisp
(straight-use-package
  `(silver-mode :type git :repo "melt-umn/silver" :files ("support/emacs/silver-mode/*.el")))
```



## Setting up LSP

`LSP` has two components, the client and the server.

### Setting up LSP Server 

Checkout [copper](https://github.com/melt-umn/copper) somewhere on your system, and run `mvn install` in that repo to build and install copper.

Then, go to `silver/language-server/` and run `./build.sh` to build the language server. When it finishes
you should have a jar `/silver/language-server/launcher/target/launcher.jar`.

After that, make a script `silver-language-server`, put it in your `$PATH` somehow (I put it in `~/bin/`, where the other silver scripts are linked to), and put the following contents into it:

```sh
#!/usr/bin/env sh

java -Xmx7G -Xss21M -jar /path/to/silver/language-server/launcher/target/launcher.jar

```

This lets us launch the server by calling `silver-language-server` in our shell.

### Setting up Emacs as a Silver LSP client

This is where advice becomes fragmented, as the ways and methods of configuring emacs vary. I have two
methods outlined here, one for vanilla emacs users, and one for users of [Doom Emacs](https://github.com/doomemacs/doomemacs/).


#### Vanilla Emacs

Insert this snippet into your configuration to setup the silver lsp client, and its variables.


```elisp
;; Assumes silver-mode is somewhere in your load-path
(require 'silver-mode)
;; Likewise, but for lsp-mode 
(require 'lsp-mode)
(add-hook 'silver-mode-hook #'lsp)
;; useful for debugging lsp errors, will show contents of requests when you call lsp-workspace-show-log
;; with this option on
;; (setq lsp-log-io t)
(setq lsp-semantic-tokens-enable t)
(setq lsp-modeline-diagnostics-enable t)

(defgroup lsp-silver nil
  "LSP support for silver using the silver-language-server."
  :group 'lsp-mode
  :link '(url-link "https://github.com/melt-umn/silver"))

(defcustom-lsp lsp-silver-enable-mwda t
  "Enable the modular well-definedness analysis"
  :type 'boolean
  :group 'lsp-silver
  :package-version '(lsp-mode . "8.0.1")
  :lsp-path "silver.enableMWDA")

(defcustom-lsp lsp-silver-jvm-args "-Xmx6G -Xss20M "
  "Language server JVM flags"
  :type 'string
  :group 'lsp-silver
  :package-version '(lsp-mode . "8.0.1")
  :lsp-path "silver.jvmArgs")

(defcustom-lsp lsp-silver-compiler-jar nil
  "Path to the jar containing an alternate version of the Silver compiler"
  :type 'string
  :group 'lsp-silver
  :package-version '(lsp-mode . "8.0.1")
  :lsp-path "silver.compilerJar")

(defcustom-lsp lsp-silver-parser-name "silver:compiler:composed:Default:svParse"
  "Full name of the Silver parser to use, must be set if compiler jar is specified"
  :type 'string
  :group 'lsp-silver
  :package-version '(lsp-mode . "8.0.1")
  :lsp-path "silver.parserName")
(add-to-list 'lsp-language-id-configuration '(silver-mode . "silver"))
(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection (lambda () "silver-language-server"))
                  :activation-fn (lsp-activate-on "silver")
                  :multi-root t
                  :server-id 'silver-language-server))
```




#### (Optional) Configuration of `lsp` variables

The variables matching `lsp-silver-*` above set configuration options for the silver lsp client, and should
be sent to the LSP server on startup. You can set them to whatever you like here when you initialize them, but can also set them on a project specific basis, using a mode like [envrc-mode](https://github.com/purcell/envrc) to set a particular parser and jar for different projects.

For envrc-mode in particular, I have a hook to modify those variables on a per-project basis, using environment variables I set up in each project directory.

```elisp
(add-hook 'envrc-mode-hook (lambda ()
                           (setq! lsp-silver-parser-name (env-or-default "SILVER_PARSER" "silver:compiler:composed:Default:svParse")
                                  lsp-silver-compiler-jar (env-or-default "SILVER_JAR" "/path/to/silver/build/jars/silver.compiler.composed.Default.jar"))))
```

#### Doom emacs

"Stubborn Martian hackers" who use [Doom Emacs](https://github.com/doomemacs/doomemacs/) can configure their setup for silver in the following way:

`~/doom.d/packages.el`
```elisp
...
(package! silver-mode :recipe (:host github :repo "melt-umn/silver" :files ("support/emacs/silver-mode/*.el")))
...
```

`~/doom.d/config.el`
```elisp
...
(use-package! silver-mode
  :hook (silver-mode . rainbow-delimiters-mode)
  :mode "\\.sv$"
  :defer t
  :config
  (set-popup-rules!
    '(("^\\*compilation\\*" :ignore t :regexp t :align 'right :width 0.5 :quit nil :ttl nil))
    )
  (add-hook 'silver-mode-hook #'lsp! 'append)

  (after! lsp-mode
    ;; (setq lsp-log-io t)
    (setq lsp-semantic-tokens-enable t)
    (setq lsp-modeline-diagnostics-enable t)

    (defgroup lsp-silver nil
      "LSP support for silver using the silver-language-server."
      :group 'lsp-mode
      :link '(url-link "https://github.com/melt-umn/silver"))

    (defcustom-lsp lsp-silver-enable-mwda t
      "Enable the modular well-definedness analysis"
      :type 'boolean
      :group 'lsp-silver
      :package-version '(lsp-mode . "8.0.1")
      :lsp-path "silver.enableMWDA")

    (defcustom-lsp lsp-silver-jvm-args "-Xmx6G -Xss20M "
      "Language server JVM flags"
      :type 'string
      :group 'lsp-silver
      :package-version '(lsp-mode . "8.0.1")
      :lsp-path "silver.jvmArgs")

    (defcustom-lsp lsp-silver-compiler-jar nil
      "Path to the jar containing an alternate version of the Silver compiler"
      :type 'string
      :group 'lsp-silver
      :package-version '(lsp-mode . "8.0.1")
      :lsp-path "silver.compilerJar")

    (defcustom-lsp lsp-silver-parser-name "silver:compiler:composed:Default:svParse"
      "Full name of the Silver parser to use, must be set if compiler jar is specified"
      :type 'string
      :group 'lsp-silver
      :package-version '(lsp-mode . "8.0.1")
      :lsp-path "silver.parserName")
    (add-to-list 'lsp-language-id-configuration '(silver-mode . "silver"))
    (lsp-register-client
     (make-lsp-client :new-connection (lsp-stdio-connection (lambda () "silver-language-server"))
                      :activation-fn (lsp-activate-on "silver")
                      :multi-root t
                      :server-id 'silver-language-server)))

  )
```

## Trying it on Silver

After this, just visit a silver file, and `lsp-mode` should prompt you to set the workspace folder. For the `silver` repo, I generally set it to the root directory of that repo.

Then, it should just work (TM), and LSP will after a bit start giving you additional syntax highlighting, error popups, and warnings. Consult `lsp-mode` [docs](https://emacs-lsp.github.io/lsp-mode/page/keybindings/) for keybindings, or look them up using your emacs. I have had some limited success finding declarations with `lsp-find-declaration`, but my experience has been mostly unsuccessfull. Silver lsp is still in its infancy. 
