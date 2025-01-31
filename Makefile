PROJECT = perception
SHELL = /bin/bash
NVIM ?= nvim
PANVIMDOC_USE_DOCKER ?= true

ifeq ($(PANVIMDOC_USE_DOCKER), true)
	PANVIMDOC_CMD := docker run --rm -v .:/data panvimdoc:latest
else
	PANVIMDOC_CMD := ./panvimdoc.sh
endif

DOCKER ?= docker
PANVIMDOC_IMAGE ?= panvimdoc:latest
PANVIMDOC_GIT ?= https://github.com/kdheepak/panvimdoc.git
PANVIMDOC_IMAGE_EXISTS := $(shell $(DOCKER) inspect $(PANVIMDOC_IMAGE) > /dev/null 2>&1; echo $$?)

.PHONY: all doc version panvimdoc-build

all: version doc

doc: version panvimdoc-build
	@# For mini.doc:
	@# $(NVIM) --headless --noplugin -u ./scripts/doc_init.lua -c 'lua require("mini.doc").generate()' -c qa
	@# @echo
	@# For panvimdoc:
	@echo Generating docs...
	@$(PANVIMDOC_CMD) --project-name $(PROJECT) --input-file README.md --toc true \
		--vim-version "Neovim version 0.10" --description "" --demojify true \
		--treesitter true --shift-heading-level-by -1 --doc-mapping true
	@echo Generating tags...
	@$(NVIM) --headless --clean -c "helptags doc/" -c qa
	@echo Done.

version:
	@echo ---
	@$(NVIM) --version | awk 'NR==1||NR==3{print}'
	@echo ---

panvimdoc-build:
	@if [[ $(PANVIMDOC_USE_DOCKER) == true ]]; then \
		if [[ $(PANVIMDOC_IMAGE_EXISTS) != 0 ]]; then \
			echo "Could not find local panvimdoc image, building..."; \
			DIR=$(shell mktemp -d); \
			pushd $$DIR; \
			git clone $(PANVIMDOC_GIT) .; \
			$(DOCKER) build -t $(PANVIMDOC_IMAGE) .; \
			popd; \
			echo rm -rf $$DIR; \
			echo Done; \
		else \
			echo "Found panvimdoc image, proceeding."; \
		fi; \
	else \
		echo "Not using docker"; \
	fi

# vim: ft=make ts=4 noexpandtab
