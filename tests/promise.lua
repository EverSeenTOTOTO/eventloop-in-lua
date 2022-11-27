return function(lu)
  local Promise = require("src/promise")
  local eventLoop = require("src/microtask").eventLoop

  return {
    testIsPromise = function()
      lu.assertEquals(Promise:isPromise(42), false)

      local function foo() end

      lu.assertEquals(Promise:isPromise(foo), false)
      lu.assertEquals(Promise:isPromise(Promise:new(foo)), true)
    end,
    testNew = function()
      local p = Promise:resolve()

      lu.assertEquals(Promise:isPromise(p), true)
      lu.assertEquals(p.__proto__, Promise.prototype)
    end,
    testExtend = function()
      local MyPromise = Promise:extend()
      local p = MyPromise:resolve()

      lu.assertEquals(MyPromise:isPromise(MyPromise), false)
      lu.assertEquals(MyPromise:isPromise(p), true)
      -- lu.assertEquals(p.__proto__, MyPromise.prototype)
      lu.assertEquals(MyPromise.prototype.__proto__, Promise.prototype)
    end,
    testStaticResolve = function()
      local p = Promise:resolve(42)
      lu.assertEquals(Promise:isPromise(p), true)
      lu.assertEquals(Promise:resolve(p), p)
    end,

    testThen = function()
      local r = {}
      local tp = eventLoop(function()
        local p = Promise:resolve(42)

        return p:next(function(value) table.insert(r, value) end)
      end)

      lu.assertEquals(Promise:isPromise(tp), true)
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

      lu.assertEquals(Promise:isPromise(cp), true)
      lu.assertEquals(r, { 42 })
    end,

    testFinally = function()
      local r = {}
      local fp = eventLoop(function()
        local p = Promise:resolve(42)

        return p:finally(function(any) table.insert(r, any) end)
      end)

      lu.assertEquals(r, {})
      lu.assertEquals(Promise:isPromise(fp), true)
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
              :finally(loop)
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
        Promise:new(function(resolve)
          Promise:resolve():next(function()
            table.insert(r, 42)
            resolve()
          end)
        end):next(function() table.insert(r, 24) end)
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

    testCycle = function()
      lu.assertErrorMsgContains("Promise-chain cycle", function()
        eventLoop(function()
          local p
          p = Promise:resolve():next(function() return p end)
        end)
      end)
    end,

    testMultiSuccessors = function()
      local r = {}
      eventLoop(function()
        local p1, p2 = Promise.resolve():next(), Promise.resolve():next()
        p1:next(function() table.insert(r, 1) end)
        p2:next(function() table.insert(r, 3) end)
        p1:next(function() table.insert(r, 2) end)
      end)

      lu.assertEquals(r, { 1, 2, 3 })
    end,
  }
end
