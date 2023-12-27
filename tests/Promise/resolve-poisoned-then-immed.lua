return function(lu)
  local Promise = require("src/promise")

  local returnValue = 42
  local value = {}
  local poisonedThen = {
    next = function() error(value) end,
  }
  local p = Promise:new(function(resolve) returnValue = resolve(poisonedThen) end)

  lu.assertEquals(returnValue, nil, '"resolve" function return value')

  p:next(function() lu.done("The promise should not be fulfilled.") end, function(val)
    if val ~= value then
      lu.done("The promise should be fulfilled with the provided value.")
      return
    end

    lu.done()
  end)
end
