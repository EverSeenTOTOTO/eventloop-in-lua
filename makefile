# pick the first interpreter that can load luv, fallback to `lua` for its error message
LUA := $(shell for bin in luajit lua; do command -v $$bin >/dev/null 2>&1 && $$bin -e 'require("luv")' >/dev/null 2>&1 && echo $$bin && break; done)
LUA := $(if $(LUA),$(LUA),lua)

.PHONY: lint
lint:
	stylua -g "**/*.lua" -- src
	stylua -g "**/*.lua" -- tests

.PHONY: test
test:
	$(LUA) tests/main.lua

.PHONY: start
start:
	$(LUA) src/main.lua
