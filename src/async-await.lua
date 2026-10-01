local Promise = require("src/promise")

local function promisify(any)
  if Promise:isInstance(any) then return any end
  return Promise:resolve(any)
end

local function await(pack) return coroutine.yield(promisify(pack[1])) end

local async = function(pack)
  local g = coroutine.create(pack[1])

  local function resume(...)
    local status, value = coroutine.resume(g, ...)

    -- a returned Promise is indistinguishable from a yielded one, tell them apart by the coroutine status
    if status and coroutine.status(g) == "suspended" then -- await
      -- forward resume's return so the whole chain settles with the coroutine's eventual outcome
      return promisify(value):next(
        function(data) return resume(data, true) end,
        function(err) return resume(err, false) end
      )
    else -- return or error
      return status and Promise:resolve(value) or Promise:reject(value)
    end
  end

  return resume
end

return {
  await = await,
  async = async,
}
