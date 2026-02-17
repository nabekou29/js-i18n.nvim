.PHONY: test
test:
	@echo "Running tests..."
	nvim -l tests/busted.lua tests
	rm -rfv tests/.tmp_projects

.PHONY: clean-test
clean-test:
	@echo "Cleaning up test files..."
	rm -rf .tests
	rm -rf tests/.tmp_projects

.PHONY: format
format:
	@echo "Formatting files..."
	stylua -g '*.lua' .

PANVIMDOC_DIR := .panvimdoc
$(PANVIMDOC_DIR):
	git clone --depth 1 https://github.com/kdheepak/panvimdoc.git $(PANVIMDOC_DIR)

.PHONY: docs
docs: $(PANVIMDOC_DIR)
	@echo "Generating vimdoc..."
	cd $(PANVIMDOC_DIR) && ./panvimdoc.sh \
		--project-name js-i18n \
		--input-file ../README.md \
		--doc-mapping false \
		--description "JavaScript/TypeScript i18n support for Neovim" \
		--demojify true \
		--dedup-subheadings true \
		--treesitter true \
		--ignore-rawblocks true \
		--shift-heading-level-by 0 \
		--increment-heading-level-by 0
	mkdir -p doc
	mv $(PANVIMDOC_DIR)/doc/js-i18n.txt doc/js-i18n.txt
