# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = source
BUILDDIR      = build

# Put it first so that "make" without argument is like "make help".
help:
	@echo "Project Commands"
	@echo "  install     to install project dependencies"
	@echo "  watch       to serve the docs with hot reloading"
	@echo "  build       to build the production docs"
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

install:
	python3 -m venv venv
	. venv/bin/activate
	pip install -r requirements.txt

generate: install
	$(MAKE) clean
	python3 scripts/gen.py ../spectrum/ source/reference/spectrum
	python3 scripts/gen.py ../engine/ source/reference/prism
	python3 scripts/gen.py ../geometer/ source/reference/geometer
	python3 scripts/gen.py ../extra/ source/reference/extra

watch: generate
	sphinx-autobuild source build/html

build: generate
	$(MAKE) clean
	$(MAKE) html

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
