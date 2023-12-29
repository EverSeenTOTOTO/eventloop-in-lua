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
  while #dict[p].successors > 0 do
    local task = dict[p].successors[1]
    table.remove(dict[p].successors, 1)
    eventLoop.queueMicrotask(task)
  end
end

local function isThenable(any) return type(any) == "table" and type(any.next) == "function" end

local Promise = createClass(function(this, fn)
  if type(fn) ~= "function" then error("Promise resolver " .. tostring(fn) .. " is not a function") end

  dict[this] = {
    pstate = PStates.Pending,
    successors = {},
  }

  local function createCallback(isResolve)
    local finalState = isResolve and PStates.Fulfilled or PStates.Rejected
    return function(data)
      if dict[this].pstate ~= PStates.Pending then return end

      local done = function(value)
        dict[this].pdata = value
        dict[this].pstate = finalState
        notifySuccesor(this)
      end

      if data and isThenable(data) then -- resolve(thenable)
        if data == this then
          dict[this].pdata = "Promise-chain cycle"
          dict[this].pstate = PStates.Rejected
          return
        end

        -- reject(any) will directly return any, but resolve(any) will continue resolve if any is thenable
        if not isResolve then
          done(data)
          return
        end

        local poisonedStatus, poisonedResult = pcall(function() return data:next(done, done) end)

        -- next method has been poisoned, only errors are handled
        if not poisonedStatus and data.next ~= this.constructor.prototype.next then
          createCallback(false)(poisonedResult)
        end
      else
        done(data)
      end
    end
  end

  local resolve = createCallback(true)
  local reject = createCallback(false)
  local immedStatus, immedErr = pcall(function() fn(resolve, reject) end)

  if not immedStatus and dict[this].pstate == PStates.Pending then
    dict[this].pdata = immedErr
    dict[this].pstate = PStates.Rejected
  end
end)

-- instance methods

function Promise.prototype:next(onFulfilled, onRejected)
  onFulfilled = onFulfilled or function(...) return ... end
  onRejected = onRejected or function(...) error(...) end

  return self.constructor:new(function(resolve, reject)
    local function done(callback)
      local status, result = pcall(callback)

      if status then
        resolve(result)
      else
        reject(result)
      end
    end

    local task = function()
      if dict[self].pstate == PStates.Fulfilled then
        done(function() return onFulfilled(dict[self].pdata) end)
      elseif dict[self].pstate == PStates.Rejected then
        done(function() return onRejected(dict[self].pdata) end)
      else
        -- skip callback, e.g. Promise:reject(42):next(callback)
        done(function()
          if dict[self].pstate == PStates.Fulfilled then
            return dict[self].pdata
          else
            error(dict[self].pdata)
          end
        end)
      end
    end

    if dict[self].pstate == PStates.Pending then
      table.insert(dict[self].successors, task)
    else
      eventLoop.queueMicrotask(task)
    end
  end)
end

function Promise.prototype:catch(onRejected) return self:next(nil, onRejected) end

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
