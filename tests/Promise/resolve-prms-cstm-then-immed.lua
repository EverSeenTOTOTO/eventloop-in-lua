---@diagnostic disable: duplicate-set-field
return function(lu)
  local Promise = require("src/promise")

  local returnValue = 42
  local value = {}
  local lateCallCount = 0
  local thenable = Promise:new(function(resolve) resolve() end)

  function thenable:next(resolve) resolve(value) end

  local promise = Promise:new(function(resolve) returnValue = resolve(thenable) end)

  lu.assertEquals(returnValue, nil, '"resolve" function return value')

  function thenable:next() lateCallCount = lateCallCount + 1 end

  promise:next(function(val)
    if val ~= value then
      lu.done("The promise should be fulfilled with the provided value.")
      return
    end

    if lateCallCount > 0 then
      lu.done("The `then` method should be executed synchronously.")
      return
    end

    lu.done()
  end, function() lu.done("The promise should not be rejected.") end)
end
