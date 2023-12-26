return function(lu)
  local el = require("src/eventLoop")

  return {
    testSetTimeout = function()
      local r = {}
      local timer = el.setTimeout(function() table.insert(r, 42) end, 3)
      el.setTimeout(function() table.insert(r, 0) end, 1)
      el.setTimeout(function()
        table.insert(r, 1)
        el.clearTimeout(timer)
      end, 2)

      el.startEventLoop(el.flushMicrotasks)

      lu.assertEquals(r, { 0, 1 })
    end,
    testSetInterval = function()
      local r = {}
      local timer
      timer = el.setInterval(function()
        table.insert(r, 0)
        if #r == 2 then el.clearInterval(timer) end
      end, 1)

      el.startEventLoop(el.flushMicrotasks)

      lu.assertEquals(r, { 0, 0 })
    end,
    testQueueMicrotask = function()
      local r = {}

      el.setTimeout(function()
        el.queueMicrotask(function() table.insert(r, 0) end)
      end, 1)
      el.queueMicrotask(function() table.insert(r, 1) end)

      el.startEventLoop(el.flushMicrotasks)

      lu.assertEquals(r, { 1, 0 })
    end,
    testBlock = function()
      local r = {}

      local timer = el.setTimeout(function() table.insert(r, 0) end, 2)

      local loop = 0
      local block
      block = function()
        if loop >= 1e6 then
          el.clearTimeout(timer) -- timer callback has no chance to run
          return
        end
        loop = loop + 1
        el.queueMicrotask(block)
      end

      el.setTimeout(block, 1)

      el.startEventLoop(el.flushMicrotasks)

      lu.assertEquals(r, {})
    end,
  }
end
