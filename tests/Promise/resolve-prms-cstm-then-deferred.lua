return function(lu)
  local Promise = require("src/promise")

  local returnValue = 42
  local value = {}
  local thenable = Promise:new(function(resolve) resolve() end)
  local resolve
  local promise = Promise:new(function(res) resolve = res end)

  function thenable:next(resolve) resolve(value) end

  promise:next(function(val)
    if val ~= value then
      lu.done("The promise should be fulfilled with the provided value.")
      return
    end

    lu.done()
  end, function() lu.done("The promise should not be rejected.") end)

  returnValue = resolve(thenable)

  lu.assertEquals(returnValue, nil, '"resolve" function return value')
end
