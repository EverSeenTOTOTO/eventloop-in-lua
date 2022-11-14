return function(lu)
  local async = require("src/main").async
  local await = require("src/main").await
  local Promise = require("src/main").Promise
  local eventLoop = require("src/microtask").eventLoop

  local i = 0
  local function empty()
    i = i + 1
    return Promise:new(function(resolve) resolve("test_" .. i) end)
  end

  return {
    testEmpty = function()
      local f = async { function() end }

      lu.assertEquals(type(f), "function")
      lu.assertEquals(Promise:isPromise(f()), true)
    end,

    testReturn = function()
      local f = async {
        function() return 42 end,
      }
      local r = {}

      eventLoop(function()
        f():next(function(value) table.insert(r, value) end)
      end)

      lu.assertEquals(r, { 42 })
    end,

    testThrow = function()
      local f = async {
        function() error(42) end,
      }
      local r = {}

      eventLoop(function()
        f():catch(function(value) table.insert(r, value) end)
      end)

      lu.assertStrContains(r[1], "42")
    end,

    testParam = function()
      local f = async {
        function(x, y) return x + y end,
      }
      local r = {}

      eventLoop(function()
        f(24, 18):next(function(value) table.insert(r, value) end)
      end)

      lu.assertEquals(r, { 42 })
    end,

    testThrowMiddle = function()
      local r = {}
      local f = async {
        function()
          await { empty() }
          table.insert(r, 1)
          await { empty() }
          table.insert(r, 2)
          error(42)
          table.insert(r, 3)
          await { empty() }
          await { empty() }
        end,
      }

      f()

      lu.assertEquals(value, nil)
      lu.assertEquals(r, { 1, 2 })
    end,

    testAwaitReturn = function()
      local r = {}
      local f = async {
        function()
          local value, status = await { Promise:new(function(resolve) resolve(42) end) }

          table.insert(r, value)
          table.insert(r, status)
        end,
      }

      f()

      lu.assertEquals(r, { 42, true })
    end,

    testAwaitThrow = function()
      local r = {}
      local f = async {
        function()
          local value, status = await { Promise:new(function(_, reject) reject(42) end) }

          table.insert(r, value)
          table.insert(r, status)
        end,
      }

      f()
      lu.assertEquals(r, { 42, false })
    end,

    testAwaitNested = function()
      local r = {}
      local f = async {
        function()
          local value = await { await { await { 42 } } }

          table.insert(r, value)
        end,
      }
      f()

      lu.assertEquals(r, { 42 })
    end,

    -- testNested = function()
    --   local r = {}
    --   local f = async {
    --     function()
    --       await {
    --         Promise:new(async {
    --           function(resolve)
    --             await { empty() }
    --             resolve(42)
    --           end,
    --         }):next(async {
    --           function(value)
    --             await { empty() }
    --             table.insert(r, value)
    --           end,
    --         }),
    --       }
    --     end,
    --   }
    --   f()

    --   lu.assertEquals(r, { 42 })
    -- end,
  }
end
