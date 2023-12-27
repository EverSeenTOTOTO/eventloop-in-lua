return function(lu)
  local Promise = require("src/promise")

  local returnValue = nil
  local value = {}
  local thenable = Promise:new(function(resolve) resolve() end)
  local promise = Promise:new(function(resolve) returnValue = resolve(thenable) end)

  lu.assertEquals(returnValue, nil, '"resolve" function return value')

  promise:next(function(val)
    if val == value then
      lu.done("The promise should be fulfilled with the provided value.")
      return
    end

    lu.done()
  end, function() lu.done("The promise should not be rejected.") end)
end
