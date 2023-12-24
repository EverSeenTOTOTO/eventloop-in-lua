return function(lu)
  local Promise = require("src/promise")
  local uv = require("luv")
  local eventLoop = function(fn)
    fn()
    uv.run()
  end

  return {
    testIsPromise = function()
      lu.assertEquals(Promise:isInstance(42), false)

      local function foo() end

      lu.assertEquals(Promise:isInstance(foo), false)
      lu.assertEquals(Promise:isInstance(Promise:new(foo)), true)
    end,
    testExtend = function()
      local MyPromise = Promise:extend()
      local p = MyPromise:resolve()

      lu.assertEquals(MyPromise:isInstance(MyPromise), false)
      lu.assertEquals(MyPromise:isInstance(p), true)
      lu.assertEquals(Promise:isInstance(p), true)
      lu.assertEquals(p:next() ~= p, true)
    end,
    testStaticResolve = function()
      local p = Promise:resolve(42)
      lu.assertEquals(Promise:isInstance(p), true)
      lu.assertEquals(Promise:resolve(p), p)
    end,

    testThen = function()
      local r = {}
      local tp = eventLoop(function()
        local p = Promise:resolve(42)

        return p:next(function(value) table.insert(r, value) end)
      end)

      lu.assertEquals(r, { 42 })
    end,

    testThenReturn = function()
      local r = {}
      eventLoop(function()
        local p = Promise:resolve(42)
        local tp = p:next(function(value) return value end)

        tp:next(function(value) table.insert(r, value) end)
      end)

      lu.assertEquals(r, { 42 })
    end,

    testThenThrow = function()
      local r = {}
      eventLoop(function()
        local p = Promise:resolve(42)
        local tp = p:next(function(value) error(value) end)

        tp:catch(function(value) table.insert(r, value) end)
      end)

      lu.assertStrContains(r[1], "42")
    end,

    testCatch = function()
      local r = {}
      local cp = eventLoop(function()
        local p = Promise:new(function(_, rej) rej(42) end)

        return p:catch(function(value) table.insert(r, value) end)
      end)

      lu.assertEquals(r, { 42 })
    end,

    testIgnoring = function()
      local r = {}
      eventLoop(function()
        local p = Promise:new(function(_, rej) rej(42) end)

        local function loop()
          if #r < 3 then
            p
              :next(function() table.insert(r, 24) end) -- should never execute
              :catch(function(value) table.insert(r, value) end)
              :next(loop)
          end
        end

        loop()
      end)

      lu.assertEquals(r, { 42, 42, 42 })
    end,

    testPersistState = function()
      local r = {}
      eventLoop(function()
        Promise:new(function(resolve, reject)
          resolve()
          reject() -- no effect
        end):catch(function()
          table.insert(r, 42) -- should never execute
        end)

        Promise:new(function(resolve, reject)
          reject()
          resolve() -- no effect
        end):next(function()
          table.insert(r, 42) -- should never execute
        end)
      end)

      lu.assertEquals(r, {})
    end,

    testNewNested = function()
      local r = {}
      eventLoop(function()
        local p = Promise:new(function(resolve)
          Promise:new(function(resolve2) resolve2(42) end):next(function(val)
            table.insert(r, val)
            resolve()
          end)
        end)

        p:next(function() table.insert(r, 24) end)
      end)

      lu.assertEquals(r, { 42, 24 })
    end,

    testResolveNested = function()
      local r = {}
      eventLoop(function()
        Promise:new(function(resolve)
          resolve(Promise:resolve(42):next(function(value) return value end))
          resolve(24)
        end):next(function(value) table.insert(r, value) end)
      end)

      lu.assertEquals(r, { 42 })
    end,

    testThenReturnNested = function()
      local r = {}
      eventLoop(function()
        Promise:resolve()
          :next(function()
            return Promise:resolve():next(function() table.insert(r, 1) end):next(function() table.insert(r, 2) end)
          end)
          :next(function() table.insert(r, 3) end)
      end)

      lu.assertEquals(r, { 1, 2, 3 })
    end,

    testThenNested = function()
      local r = {}
      eventLoop(function()
        Promise:resolve()
          :next(function()
            Promise:resolve():next(function() table.insert(r, 1) end):next(function() table.insert(r, 3) end)
          end)
          :next(function() table.insert(r, 2) end)
      end)

      lu.assertEquals(r, { 1, 2, 3 })
    end,

    -- testCycle = function()
    --   lu.assertErrorMsgContains("Promise-chain cycle", function()
    --     eventLoop(function()
    --       local p
    --       p = Promise:resolve():next(function() return p end)
    --     end)
    --   end)
    -- end,

    -- testMultiSuccessors = function()
    --   local r = {}
    --   eventLoop(function()
    --     local p1, p2 = Promise:resolve():next(), Promise:resolve():next()
    --     p1:next(function() table.insert(r, 1) end)
    --     p2:next(function() table.insert(r, 3) end)
    --     p1:next(function() table.insert(r, 2) end)
    --   end)

    --   lu.assertEquals(r, { 1, 2, 3 })
    -- end,
  }
end
