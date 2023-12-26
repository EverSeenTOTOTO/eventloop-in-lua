local lu = require("luaunit")

TestEventLoop = require("tests/event-loop")(lu)
TestClass = require("tests/class")(lu)
TestPromise = require("tests/promise")(lu)
TestAsyncAwait = require("tests/async-await")(lu)

os.exit(lu.LuaUnit.run())
