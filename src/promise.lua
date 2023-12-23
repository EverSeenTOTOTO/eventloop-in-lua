-- part of these codes are stolen from corejs

local createClass = require("src/class")
local schedule = require("src/microtask").schedule

local PStates = {
  Pending = "Pending",
  Fulfilled = "Fulfilled",
  Rejected = "Rejected",
}

local dict = {}

local function notify(p)
  for _, task in ipairs(dict[p].successors) do
    schedule(task)
  end
end

local Promise = createClass(function(this, fn)
  dict[this] = {
    pstate = PStates.Pending,
    successors = {},
    once = false,
  }

  local function createCallback(finalState)
    return function(data)
      if dict[this].once then
        return
      else
        dict[this].once = true
      end

      if this.constructor:isInstance(data) then -- resolve(Promise)
        if data == this then error("Promise-chain cycle") end

        data
          :next(function(value) dict[this].pdata = value end)
          :catch(function(value) dict[this].pdata = value end)
          :next(function()
            dict[this].pstate = finalState
            notify(this)
          end)
      else
        dict[this].pdata = data
        dict[this].pstate = finalState

        notify(this)
      end
    end
  end

  local resolve = createCallback(PStates.Fulfilled)
  local reject = createCallback(PStates.Rejected)

  fn(resolve, reject)
end)

-- instance methods

local function factory(self, callback, predicate)
  return self.constructor:new(function(resolve, reject)
    local task = function()
      -- whether to call next/catch callback
      if predicate() then
        local status, result = pcall(callback)

        if status then
          resolve(result)
        else
          reject(result)
        end
      else
        -- skip callback, e.g. Promise:reject(42):next(callback) shuold still returns a promise
        if dict[self].pstate == PStates.Fulfilled then
          resolve(dict[self].pdata)
        else
          reject(dict[self].pdata)
        end
      end
    end

    if dict[self].pstate == PStates.Pending then
      table.insert(dict[self].successors, task)
    else
      schedule(task)
    end
  end)
end

function Promise.prototype:next(onFulfilled)
  onFulfilled = onFulfilled or function() end
  return factory(
    self,
    function() return onFulfilled(dict[self].pdata) end,
    function() return dict[self].pstate == PStates.Fulfilled end
  )
end

function Promise.prototype:catch(onRejected)
  onRejected = onRejected or function() end
  return factory(
    self,
    function() return onRejected(dict[self].pdata) end,
    function() return dict[self].pstate == PStates.Rejected end
  )
end

-- TODO: finally

function Promise.prototype:__tostring()
  return string.format(
    "Promise { %s }",
    dict[self].pstate == PStates.Fulfilled and tostring(dict[self].pdata) or dict[self].pstate
  )
end

-- static methods

function Promise:resolve(any)
  return self:isInstance(any) and any or self:new(function(res) res(any) end)
end

function Promise:reject(any)
  return self:new(function(_, rej) rej(any) end)
end

return Promise
