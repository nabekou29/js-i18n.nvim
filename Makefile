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
