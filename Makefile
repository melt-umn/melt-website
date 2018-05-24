SHELL := /bin/bash

usage:
	@echo "To do local development of the site:"
	@echo "make env    (once, to get setup)"
	@echo "make serve  (to incrementally rebuild the site and locally host it)"

# The full site build process
all: env doc site

env:
	_scripts/ready-environment.sh

# doc only works on coldpress
doc:
	_scripts/build-silver-docs.sh

site:
	_scripts/build-jekyll-site.sh

serve:
	JEKYLL_COMMAND="serve --incremental" _scripts/build-jekyll-site.sh

clean:
	rm -rf "_site" ".sass-cache" "_data/sv_wiki.yml"
	[ -L vendor ] && rm -rf $(readlink -f vendor) || true
	[ -e vendor ] && rm -rf vendor || true

.PHONY: usage all env doc site clean serve
