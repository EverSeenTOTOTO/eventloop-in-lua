-- part of these codes are stolen from corejs

local createClass = require("src/class")
local eventLoop = require("src/eventLoop")
local internal = require("src/internal")

local dict = internal.dict

local PStates = {
  Pending = "Pending",
  Fulfilled = "Fulfilled",
  Rejected = "Rejected",
}

local function notifySuccesor(p)
  while #dict[p].successors > 0 do
    local task = table.remove(dict[p].successors, 1)
    eventLoop.queueMicrotask(task)
  end
end

local function isThenable(any) return type(any) == "table" and type(any.next) == "function" end

local Promise = createClass {
  constructor = function(this, fn)
    if type(fn) ~= "function" then error("Promise resolver " .. tostring(fn) .. " is not a function") end

    dict[this] = {
      pstate = PStates.Pending,
      successors = {},
    }

    local function createCallback(finalState)
      return function(data)
        if dict[this].pstate ~= PStates.Pending then return end

        local done = function(value, customState)
          dict[this].pdata = value
          dict[this].pstate = customState or finalState

          if dict[this].pstate == PStates.Rejected then dict[this].unhandled = true end

          notifySuccesor(this)
        end

        -- reject(any) will directly return any
        if finalState == PStates.Rejected or not isThenable(data) then -- resolve(thenable)
          done(data)
          return
        end

        if data == this then
          done("Promise-chain cycle", PStates.Rejected)
          return
        end

        local poisonedStatus, poisonedResult = pcall(function()
          return data:next(
            done,
            -- resolve(rejectedPromise) will reject with rejectedPromise's reason
            function(value) done(value, PStates.Rejected) end
          )
        end)

        -- next method has been poisoned, only errors are handled
        if not poisonedStatus and data.next ~= this.class.prototype.next then
          -- done(poisonedResult, PStates.Rejected); this is incorrect because poisenResult may be thanable
          createCallback(PStates.Rejected)(poisonedResult)
        end
      end
    end

    local resolve = createCallback(PStates.Fulfilled)
    local reject = createCallback(PStates.Rejected)
    local immedStatus, immedErr = pcall(function() fn(resolve, reject) end)

    if not immedStatus and dict[this].pstate == PStates.Pending then
      dict[this].pdata = immedErr
      dict[this].pstate = PStates.Rejected
      notifySuccesor(this)
    end

    return this
  end,
}

-- instance methods

function Promise.prototype:next(onFulfilled, onRejected)
  onFulfilled = onFulfilled or function(...) return ... end
  onRejected = onRejected or function(...) error(...) end

  return self.class:new(function(resolve, reject)
    local task = function()
      if dict[self].pstate == PStates.Rejected then dict[self].unhandled = false end

      local status, result = pcall(function()
        if dict[self].pstate == PStates.Fulfilled then
          onFulfilled(dict[self].pdata)
        elseif dict[self].pstate == PStates.Rejected then
          onRejected(dict[self].pdata)
        else
          -- skip callback, e.g. Promise:reject(42):next(callback)
          if dict[self].pstate == PStates.Fulfilled then
            return dict[self].pdata
          else
            error(dict[self].pdata)
          end
        end
      end)

      return status and resolve(result) or reject(result)
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
  local state = dict[self].pstate
  local data = dict[self].pdata

  return string.format(
    "Promise { %s%s }",
    state == PStates.Fulfilled and tostring(data) or "<" .. state .. ">",
    state == PStates.Rejected and " " .. tostring(data) or ""
  )
end

-- static methods

function Promise:resolve(any)
  return self:new(function(res) res(any) end)
end

function Promise:reject(any)
  return self:new(function(_, rej) rej(any) end)
end

return Promise
