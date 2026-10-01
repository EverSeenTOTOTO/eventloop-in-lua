return function(lu)
  local internal = require("src/internal")
  local Promise = require("src/promise")
  local eventLoop = require("src/eventLoop")

  local function dictSize()
    local count = 0
    for _ in pairs(internal.dict) do
      count = count + 1
    end
    return count
  end

  local function collect()
    -- weak table entries are only reclaimed on a full cycle, run a few to be safe
    for _ = 1, 3 do
      collectgarbage("collect")
    end
  end

  return {
    testSettledPromisesAreCollectable = function()
      -- other suites may leave eternally pending promises behind, so compare sizes:
      -- ~300 settled promises must not grow the dict, a strong dict would keep them all
      local before = dictSize()

      eventLoop.startEventLoop(function()
        for i = 1, 100 do
          Promise:resolve(i):next(function(v) return v + 1 end):next(function() end)
        end
      end)

      collect()

      lu.assertEquals(dictSize() - before < 100, true, "settled and dropped promises should be collected")
    end,

    testLivePromisesAreKept = function()
      local kept = nil

      eventLoop.startEventLoop(function()
        kept = Promise:new(function() end) -- stays pending forever
      end)

      collect()

      lu.assertEquals(internal.dict[kept] ~= nil, true, "a reachable promise should stay in the dict")
    end,
  }
end
