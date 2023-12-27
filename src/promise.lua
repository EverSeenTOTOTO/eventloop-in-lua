-- part of these codes are stolen from corejs

local createClass = require("src/class")
local eventLoop = require("src/eventLoop")

local PStates = {
  Pending = "Pending",
  Fulfilled = "Fulfilled",
  Rejected = "Rejected",
}

local dict = {}

local function notifySuccesor(p)
  for _, task in ipairs(dict[p].successors) do
    eventLoop.queueMicrotask(task)
  end
end

local Promise = createClass(function(this, fn)
  if type(fn) ~= "function" then error("Promise resolver " .. tostring(fn) .. " is not a function") end

  dict[this] = {
    pstate = PStates.Pending,
    successors = {},
  }

  local function createCallback(finalState)
    return function(data)
      if dict[this].pstate ~= PStates.Pending then return end

      if this.constructor:isInstance(data) then -- resolve(another promise)
        if data == this then
          dict[this].pdata = "Promise-chain cycle"
          dict[this].pstate = PStates.Rejected
          return
        end

        data
            :next(function(value) dict[this].pdata = value end)
            :catch(function(value) dict[this].pdata = value end)
            :next(function()
              dict[this].pstate = finalState
              notifySuccesor(this)
            end)
      else
        dict[this].pdata = data
        dict[this].pstate = finalState

        notifySuccesor(this)
      end
    end
  end

  local resolve = createCallback(PStates.Fulfilled)
  local reject = createCallback(PStates.Rejected)
  local immedStatus, immedErr = pcall(function() fn(resolve, reject) end)

  if not immedStatus and dict[this].pstate == PStates.Pending then
    dict[this].pdata = immedErr
    dict[this].pstate = PStates.Rejected
  end
end)

-- instance methods

function Promise.prototype:next(onFulfilled, onRejected)
  return self.constructor:new(function(resolve, reject)
    local task = function()
      if dict[self].pstate == PStates.Fulfilled then
        local status, result = pcall(function() return onFulfilled(dict[self].pdata) end)

        if status then
          resolve(result)
        else
          reject(result)
        end
      elseif dict[self].pstate == PStates.Rejected then
        local status, result = pcall(function() return onRejected(dict[self].pdata) end)

        if status then
          resolve(result)
        else
          reject(result)
        end
      else
        -- skip callback, e.g. Promise:reject(42):next(callback)
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
      eventLoop.queueMicrotask(task)
    end
  end)
end

function Promise.prototype:catch(onRejected)
  return self.constructor:new(function(resolve, reject)
    local task = function()
      -- whether to call next/catch callback
      if dict[self].pstate == PStates.Rejected then
        local status, result = pcall(function() return onRejected(dict[self].pdata) end)

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
      eventLoop.queueMicrotask(task)
    end
  end)
end

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
