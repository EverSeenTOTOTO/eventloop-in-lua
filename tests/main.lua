local lu = require("luaunit")

TestPromise = require("tests/promise")(lu)
TestAsyncAwait = require("tests/async-await")(lu)

os.exit(lu.LuaUnit.run())
