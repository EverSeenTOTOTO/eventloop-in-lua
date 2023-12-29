local Promise = require("src/promise")

local function await(pack) return coroutine.yield(Promise:resolve(pack[1])) end

local async = function(pack)
  local g = coroutine.create(pack[1])

  local function resume(...)
    local status, promise = coroutine.resume(g, ...)

    if Promise:isInstance(promise) then -- await
      return promise:next(function(data) resume(data, true) end, function(err) resume(err, false) end)
    else -- return or error
      return status and Promise:resolve(promise) or Promise:reject(promise)
    end
  end

  return resume
end

return {
  await = await,
  async = async,
}
