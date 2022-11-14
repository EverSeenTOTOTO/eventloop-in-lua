local Promise = require("src/promise")
local eventLoop = require("src/microtask").eventLoop

local function await(pack) return coroutine.yield(Promise:resolve(pack[1])) end

local async = function(pack)
  local g = coroutine.create(pack[1])

  local pdata, pstatus -- the return value of each await

  local function resume(param, ...)
    local gstatus, promise -- the return value of whole async function

    if param then -- initial call
      gstatus, promise = coroutine.resume(g, param, ...)
    else -- recursive call
      gstatus, promise = coroutine.resume(g, pdata, pstatus)
    end

    if Promise:isPromise(promise) then -- await
      return eventLoop(function()
        return promise
          :next(function(data)
            pdata = data
            pstatus = true
          end)
          :catch(function(err)
            pdata = err
            pstatus = false
          end)
          :finally(resume)
      end)
    else -- return or error
      return gstatus and Promise:resolve(promise) or Promise:reject(promise)
    end
  end

  return resume
end

return {
  await = await,
  async = async,
}
