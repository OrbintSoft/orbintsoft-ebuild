# Copyright 2026 Stefano Balzarotti
# Distributed under the terms of the GNU General Public License v3
#
# Developer tooling for the orbintsoft overlay.
# Requires: app-portage/pkgcheck, app-portage/pkgdev (egencache),
#           dev-util/shellcheck, dev-libs/libxml2 (xmllint), checkmake
#           (go install github.com/checkmake/checkmake@latest). See CONTRIBUTING.md.
#
# Quick start:
#   make lint      # pkgcheck + shellcheck
#   make install   # register this tree as a Portage repo (needs root)
#   make metadata  # regenerate the gitignored md5-cache

REPO_NAME      := $(shell cat profiles/repo_name 2>/dev/null)
JOBS           ?= $(shell nproc 2>/dev/null || echo 1)
REPOS_CONF_DIR ?= /etc/portage/repos.conf

PKGCHECK   ?= pkgcheck
PKGDEV     ?= pkgdev
EGENCACHE  ?= egencache
SHELLCHECK ?= shellcheck
CHECKMAKE  ?= checkmake
XMLLINT    ?= xmllint
EBUILD     ?= ebuild

# shellcheck targets: every file with a shell/openrc shebang, plus OpenRC
# conf.d fragments (which are sourced and carry no shebang of their own).
# Parsed as bash; per-file `# shellcheck` directives are added when each
# package is cleaned up (PLAN.md Phase 1).
SHELLCHECK_OPTS ?= --shell=bash
SH_SOURCES := $(sort \
	$(shell grep -rIlE '^#!.*(\bsh\b|bash|openrc-run)' --exclude-dir=.git . 2>/dev/null) \
	$(shell find . -path ./.git -prune -o -type f -name '*.confd' -print))

# XML sources: every *.xml in the tree (currently all metadata.xml).
XML_SOURCES := $(shell find . -path ./.git -prune -o -name '*.xml' -print)

.DEFAULT_GOAL := help

.PHONY: help lint lint-ebuild lint-sh lint-make lint-xml test manifest metadata install uninstall clean

help: ## Show this help
	@echo "orbintsoft overlay — make targets:"
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

lint: lint-ebuild lint-sh lint-make lint-xml ## Run all linters (pkgcheck + shellcheck + checkmake + xmllint)

lint-ebuild: ## Run pkgcheck over the whole overlay
	$(PKGCHECK) scan

lint-sh: ## Run shellcheck on scripts under files/
	@if [ -n "$(strip $(SH_SOURCES))" ]; then \
		echo "shellcheck $(SHELLCHECK_OPTS) $(SH_SOURCES)"; \
		$(SHELLCHECK) $(SHELLCHECK_OPTS) $(SH_SOURCES); \
	else \
		echo "no shell sources to check"; \
	fi

lint-make: ## Lint the Makefile itself (checkmake)
	$(CHECKMAKE) --config=checkmake.ini Makefile

# Well-formedness only, offline (--nonet): pkgcheck (lint-ebuild) does the
# DTD/semantic validation of metadata.xml, so we don't duplicate it here and
# stay machine-agnostic (no dependency on a local copy of the gentoo DTD).
lint-xml: ## Check all *.xml are well-formed (xmllint; DTD checks done by pkgcheck)
	@if [ -n "$(strip $(XML_SOURCES))" ]; then \
		echo "xmllint --noout --nonet $(XML_SOURCES)"; \
		$(XMLLINT) --noout --nonet $(XML_SOURCES); \
	else \
		echo "no xml sources to check"; \
	fi

manifest: ## Regenerate thin Manifests for all packages (pkgdev)
	$(PKGDEV) manifest

metadata: ## Regenerate the gitignored md5-cache (needs `make install` first)
	$(EGENCACHE) --update --repo $(REPO_NAME) --jobs $(JOBS)

test: ## Build+install one package locally: make test PKG=cat/name (ebuild(1); CI uses stage3, see PLAN.md Phase 2)
	@test -n "$(PKG)" || { echo "usage: make test PKG=cat/name"; exit 2; }
	@set -e; for e in $(PKG)/*.ebuild; do \
		echo ">> $$e"; $(EBUILD) "$$e" clean install; \
	done

install: ## Register this tree in $(REPOS_CONF_DIR) as '$(REPO_NAME)' (needs root)
	@test -n "$(REPO_NAME)" || { echo "profiles/repo_name is empty"; exit 2; }
	install -d -m0755 $(REPOS_CONF_DIR)
	@printf '[%s]\nlocation = %s\nauto-sync = no\n' \
		'$(REPO_NAME)' '$(CURDIR)' > $(REPOS_CONF_DIR)/$(REPO_NAME).conf
	@echo "Registered '$(REPO_NAME)' -> $(CURDIR)"

uninstall: ## Remove the repos.conf entry created by `make install`
	rm -f $(REPOS_CONF_DIR)/$(REPO_NAME).conf

clean: ## Remove generated artifacts (md5-cache, pkg_desc_index)
	rm -rf metadata/md5-cache metadata/pkg_desc_index
