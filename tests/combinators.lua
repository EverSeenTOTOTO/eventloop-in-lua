return function(lu)
  local Promise = require("src/promise")
  local eventLoop = require("src/eventLoop")

  local function delay(value, ms)
    return Promise:new(function(resolve)
      eventLoop.setTimeout(function() resolve(value) end, ms)
    end)
  end

  return {
    testAll = function()
      local r = {}

      eventLoop.startEventLoop(function()
        Promise:all({ delay(40, 3), delay(42, 1), delay(44, 2) }):next(function(values) r.values = values end)
        Promise:all({ 1, Promise:resolve(2) }):next(function(values) r.plain = values end)
        Promise:all({}):next(function(values) r.empty = values end)
        Promise:all({ delay(1, 5), Promise:reject("boom"), delay(3, 1) })
          :next(function() r.rejected = "fulfilled" end, function(reason) r.rejected = reason end)
      end)

      lu.assertEquals(r.values, { 40, 42, 44 }, "all should fulfill with values in list order")
      lu.assertEquals(r.plain, { 1, 2 }, "all should accept plain values")
      lu.assertEquals(r.empty, {}, "all of an empty list should fulfill with an empty table")
      lu.assertEquals(r.rejected, "boom", "all should reject with the first rejection reason")
    end,

    testRace = function()
      local r = {}

      eventLoop.startEventLoop(function()
        Promise:race({ delay(1, 5), delay(2, 1), delay(3, 9) }):next(function(value) r.fulfilled = value end)
        Promise:race({ delay(1, 5), Promise:reject("boom") })
          :next(function(value) r.rejected = value end, function(reason) r.rejected = reason end)
        Promise:race({ 42 }):next(function(value) r.plain = value end)
      end)

      lu.assertEquals(r.fulfilled, 2, "race should fulfill with the first settled value")
      lu.assertEquals(r.rejected, "boom", "race should reject with the first rejection reason")
      lu.assertEquals(r.plain, 42, "race should accept plain values")
    end,

    testAny = function()
      local r = {}

      eventLoop.startEventLoop(function()
        Promise:any({ Promise:reject(1), delay(42, 1), delay(3, 5) })
          :next(function(value) r.fulfilled = value end, function(reason) r.fulfilled = reason end)
        Promise:any({ Promise:reject("a"), Promise:reject("b") })
          :next(function(value) r.allRejected = value end, function(err) r.allRejected = err end)
        Promise:any({}):next(function(value) r.empty = value end, function(err) r.empty = err end)
      end)

      lu.assertEquals(r.fulfilled, 42, "any should fulfill with the first fulfilled value")
      lu.assertEquals(r.allRejected.name, "AggregateError", "any should reject with an AggregateError")
      lu.assertEquals(r.allRejected.errors, { "a", "b" }, "AggregateError should keep reasons in list order")
      lu.assertEquals(r.empty.name, "AggregateError", "any of an empty list should reject with an AggregateError")
    end,

    testAllSettled = function()
      local r = {}

      eventLoop.startEventLoop(function()
        Promise:allSettled({ delay(1, 3), Promise:reject("boom"), 3 }):next(function(results) r.mixed = results end)
        Promise:allSettled({}):next(function(results) r.empty = results end)
      end)

      lu.assertEquals(#r.mixed, 3, "allSettled should return one result per element")
      lu.assertEquals(r.mixed[1].status, "fulfilled", "allSettled result 1 should be fulfilled")
      lu.assertEquals(r.mixed[1].value, 1, "allSettled result 1 should carry the value")
      lu.assertEquals(r.mixed[2].status, "rejected", "allSettled result 2 should be rejected")
      lu.assertEquals(r.mixed[2].reason, "boom", "allSettled result 2 should carry the reason")
      lu.assertEquals(r.mixed[3].status, "fulfilled", "allSettled result 3 should be fulfilled")
      lu.assertEquals(r.mixed[3].value, 3, "allSettled result 3 should carry the value")
      lu.assertEquals(r.empty, {}, "allSettled of an empty list should fulfill with an empty table")
    end,

    testFinally = function()
      local r = {}

      eventLoop.startEventLoop(function()
        Promise:resolve(42):finally(function(...) r.args = { ... } end):next(function(value) r.value = value end)
        Promise:reject("boom")
          :finally(function() end)
          :next(function() r.reason = "fulfilled" end, function(reason) r.reason = reason end)
        Promise:resolve(42)
          :finally(function()
            return Promise:new(function(resolve) eventLoop.setTimeout(resolve, 2) end)
          end)
          :next(function(value) r.delayed = value end)
        Promise:resolve(42)
          :finally(function() return Promise:reject("boom") end)
          :next(function(value) r.overridden = value end, function(reason) r.overridden = reason end)
        Promise:resolve(42):finally(nil):next(function(value) r.nilHandler = value end)
      end)

      lu.assertEquals(r.args, {}, "onFinally should be called without arguments")
      lu.assertEquals(r.value, 42, "finally should pass the value through")
      lu.assertEquals(r.reason, "boom", "finally should pass the exact reason through")
      lu.assertEquals(r.delayed, 42, "finally should wait for the promise returned by onFinally")
      lu.assertEquals(r.overridden, "boom", "a rejecting onFinally should replace the outcome")
      lu.assertEquals(r.nilHandler, 42, "finally(nil) should behave like next(nil)")
    end,

    testInvalidInput = function()
      lu.assertThrows(function() Promise:all(42) end, "all should throw on non-table input")
      lu.assertThrows(function() Promise:race(42) end, "race should throw on non-table input")
      lu.assertThrows(function() Promise:any(42) end, "any should throw on non-table input")
      lu.assertThrows(function() Promise:allSettled(42) end, "allSettled should throw on non-table input")
    end,
  }
end
