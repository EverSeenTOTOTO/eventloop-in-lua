return function(lu)
  local Promise = require("src/promise")

  local returnValue = "not nil"
  local p = Promise:new(function(resolve) returnValue = resolve(42) end)

  lu.assertEquals(returnValue, nil, '"resolve" function return value')

  p:next(function(value)
    if value ~= 42 then
      lu.done("The promise should be fulfilled with the provided value.")
      return
    end

    lu.done()
  end, function() lu.done("The promise should not be rejected.") end)
end
