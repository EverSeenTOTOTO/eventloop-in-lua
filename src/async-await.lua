local Promise = require("src/promise")
local uv = require("luv")

local function await(pack) return coroutine.yield(Promise:resolve(pack[1])) end

local async = function(pack)
  local g = coroutine.create(pack[1])

  local pdata, pstatus -- the return value of each await

  local function resume(param, ...)
    local gstatus, promise -- the return value of whole async function

    if param then -- initial call
      gstatus, promise = coroutine.resume(g, param, ...)
    else -- recursive call, use prev yield value
      gstatus, promise = coroutine.resume(g, pdata, pstatus)
    end

    if Promise:isInstance(promise) then -- await
      return promise
        :next(function(data)
          pdata = data
          pstatus = true
        end)
        :catch(function(err)
          pdata = err
          pstatus = false
        end)
        :next(resume)
    else -- return or error
      return gstatus and Promise:resolve(promise) or Promise:reject(promise)
    end
  end

  return function(...)
    local r = resume(...)
    uv.run()
    return r
  end
end

return {
  await = await,
  async = async,
}
