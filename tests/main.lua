local lu = require("luaunit")

TestClass = require("tests/class")(lu)
TestPromise = require("tests/promise")(lu)
TestAsyncAwait = require("tests/async-await")(lu)

os.exit(lu.LuaUnit.run())
