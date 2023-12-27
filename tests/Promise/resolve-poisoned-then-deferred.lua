return function(lu)
  local Promise = require("src/promise")

  local returnValue = 42
  local value = {}
  local resolve
  local poisonedThen = {
    next = function() error(value) end,
  }
  local p = Promise:new(function(res) resolve = res end)

  p:next(function() lu.done("The promise should not be fulfilled.") end, function(val)
    if val ~= value then
      lu.done("The promise should be fulfilled with the provided value.")
      return
    end

    lu.done()
  end)

  returnValue = resolve(poisonedThen)

  lu.assertEquals(returnValue, nil, '"resolve" function return value')
end
