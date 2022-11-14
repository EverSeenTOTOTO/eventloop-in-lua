local createClass = require("src/class")
local microtask = require("src/microtask").microtask

local PStates = {
  Pending = "Pending",
  Fulfilled = "Fulfilled",
  Rejected = "Rejected",
}

local dict = {}

local function notify(p)
  for _, task in ipairs(dict[p].successors) do
    microtask(task)
  end
end

local function instanceof(any, proto)
  local status, is = pcall(function() return any.__proto__ == proto end)

  return status and is
end

local Promise = createClass(function(self, fn)
  dict[self] = {
    pstate = PStates.Pending,
    successors = {},
    once = false,
  }

  local function createCallback(finalState)
    return function(data)
      if dict[self].once then
        return
      else
        dict[self].once = true
      end

      if instanceof(data, self.__proto__) then
        if data == self then error("Promise-chain cycle") end

        data
          :next(function(value) dict[self].pdata = value end)
          :catch(function(value) dict[self].pdata = value end)
          :finally(function()
            dict[self].pstate = finalState
            notify(self)
          end)
      else
        dict[self].pdata = data
        dict[self].pstate = finalState

        notify(self)
      end
    end
  end

  local resolve = createCallback(PStates.Fulfilled)
  local reject = createCallback(PStates.Rejected)

  fn(resolve, reject)

  return self
end)

-- instance methods

local function factory(self, callback, predicate)
  return Promise:new(function(resolve, reject)
    local task = function()
      if predicate() then
        local status, result = pcall(callback)

        if status then
          resolve(result)
        else
          reject(result)
        end
      else
        -- skip callback
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
      microtask(task)
    end
  end)
end

function Promise.prototype:next(callback)
  return factory(
    self,
    function() return callback(dict[self].pdata) end,
    function() return dict[self].pstate == PStates.Fulfilled end
  )
end

function Promise.prototype:catch(callback)
  return factory(
    self,
    function() return callback(dict[self].pdata) end,
    function() return dict[self].pstate == PStates.Rejected end
  )
end

function Promise.prototype:finally(callback)
  return factory(self, callback, function() return dict[self].pstate ~= PStates.Pending end)
end

function Promise.prototype:__tostring()
  return string.format(
    "Promise { %s }",
    dict[self].pstate == PStates.Fulfilled and tostring(dict[self].pdata) or dict[self].pstate
  )
end

-- static methods

-- check if is a promise
function Promise:isPromise(any) return instanceof(any, Promise.prototype) end

function Promise:resolve(any)
  return Promise:isPromise(any) and Promise:new(function(res, rej) any:next(res):catch(rej) end)
    or Promise:new(function(res) res(any) end)
end

function Promise:reject(any)
  return Promise:new(function(_, rej) rej(any) end)
end

return Promise
