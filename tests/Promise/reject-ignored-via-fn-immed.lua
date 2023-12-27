return function(lu)
  local Promise = require("src/promise")

  local returnValue = 42
  local thenable = Promise:new(function() end)
  local p = Promise:new(function(resolve, reject)
    resolve()
    returnValue = reject(thenable)
  end)

  lu.assertEquals(returnValue, nil, '"reject" function return value')

  p:next(lu.done, function() lu.done("The promise should not be rejected.") end)
end
