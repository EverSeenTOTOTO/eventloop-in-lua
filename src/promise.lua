-- part of these codes are stolen from corejs

local createClass = require("src/class")
local eventLoop = require("src/eventLoop")
local internal = require("src/internal")

local dict = internal.dict
local unhandled = internal.unhandled

local PStates = {
  Pending = "Pending",
  Fulfilled = "Fulfilled",
  Rejected = "Rejected",
}

local function notifySuccesor(p)
  local successors = dict[p].successors

  -- tasks are only queued here, never run, so a forward iteration is safe
  -- (and avoids the O(n) table.remove(successors, 1) per task)
  for i = 1, #successors do
    local task = successors[i]
    successors[i] = nil
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

          -- keep it strongly referenced for the unhandledRejection audit,
          -- the weak dict alone may let it go before startEventLoop sees it
          if dict[this].pstate == PStates.Rejected then unhandled[this] = true end

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
  -- rethrow with level 0 to keep the rejection reason intact across hops
  onRejected = onRejected or function(...) error(..., 0) end

  return self.class:new(function(resolve, reject)
    local task = function()
      if dict[self].pstate == PStates.Rejected then unhandled[self] = nil end

      -- the task only runs after `self` settles, so the pending branch is unreachable here
      local status, result = pcall(function()
        if dict[self].pstate == PStates.Fulfilled then
          return onFulfilled(dict[self].pdata)
        else
          return onRejected(dict[self].pdata)
        end
      end)

      -- resolve/reject return nothing, an `and/or` chain would always fall through to reject
      if status then
        resolve(result)
      else
        reject(result)
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

function Promise.prototype:finally(onFinally)
  if type(onFinally) ~= "function" then
    -- pass through, e.g. promise:finally(nil) behaves like promise:next()
    return self:next(onFinally, onFinally)
  end

  local class = self.class

  -- the original value/reason survives unless onFinally itself rejects or throws
  return self:next(function(value)
    return class:resolve(onFinally()):next(function() return value end)
  end, function(reason)
    return class:resolve(onFinally()):next(function() error(reason, 0) end)
  end)
end

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
  -- like JS, a promise of the same class resolves to itself, skipping a wrapping promise
  -- and an extra microtask hop; derived instances still go through assimilation
  if type(any) == "table" and any.class == self then return any end

  return self:new(function(res) res(any) end)
end

function Promise:reject(any)
  return self:new(function(_, rej) rej(any) end)
end

-- combinators accept array-like tables, values are promisified just like Promise:resolve

local function AggregateError(errors)
  return setmetatable({ name = "AggregateError", message = "All promises were rejected", errors = errors }, {
    __tostring = function(this)
      local reasons = {}
      for i, err in ipairs(this.errors) do
        reasons[i] = tostring(err)
      end
      return string.format("%s: %s (%s)", this.name, this.message, table.concat(reasons, ", "))
    end,
  })
end

function Promise:all(list)
  if type(list) ~= "table" then error("Promise:all accepts an array-like table, got " .. type(list)) end

  return self:new(function(resolve, reject)
    local results, remaining = {}, #list

    if remaining == 0 then return resolve {} end

    for i = 1, #list do
      self:resolve(list[i]):next(function(value)
        results[i] = value
        remaining = remaining - 1
        if remaining == 0 then resolve(results) end
      end, reject)
    end
  end)
end

function Promise:race(list)
  if type(list) ~= "table" then error("Promise:race accepts an array-like table, got " .. type(list)) end

  return self:new(function(resolve, reject)
    for i = 1, #list do
      self:resolve(list[i]):next(resolve, reject)
    end
  end)
end

function Promise:any(list)
  if type(list) ~= "table" then error("Promise:any accepts an array-like table, got " .. type(list)) end

  return self:new(function(resolve, reject)
    local errors, remaining = {}, #list

    if remaining == 0 then return reject(AggregateError {}) end

    for i = 1, #list do
      self:resolve(list[i]):next(resolve, function(err)
        errors[i] = err
        remaining = remaining - 1
        if remaining == 0 then reject(AggregateError(errors)) end
      end)
    end
  end)
end

function Promise:allSettled(list)
  if type(list) ~= "table" then error("Promise:allSettled accepts an array-like table, got " .. type(list)) end

  return self:new(function(resolve)
    local results, remaining = {}, #list

    if remaining == 0 then return resolve {} end

    for i = 1, #list do
      local function settle(result)
        results[i] = result
        remaining = remaining - 1
        if remaining == 0 then resolve(results) end
      end

      self:resolve(list[i]):next(
        function(value) settle { status = "fulfilled", value = value } end,
        function(reason) settle { status = "rejected", reason = reason } end
      )
    end
  end)
end

return Promise
