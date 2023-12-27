return function(lu)
  local Promise = require("src/promise")

  local returnValue = 42
  local thenable = Promise:new(function() end)
  local p = Promise:new(function(resolve, reject)
    reject(thenable)
    returnValue = resolve()
  end)

  lu.assertEquals(returnValue, nil, '"resolve" function return value')

  p:next(function() lu.done("The promise should not be fulfilled.") end, function() lu.done() end)
end
