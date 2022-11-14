.PHONY: lint
lint:
	stylua -g "**/*.lua" -- src
	stylua -g "**/*.lua" -- tests

.PHONY: test
test:
	lua tests/main.lua

.PHONY: start
start:
	lua src/main.lua
