return function(lu)
  local Promise = require("src/promise")

  local returnValue = 42
  local thenable = Promise:new(function() end)
  local resolve, reject
  local p = Promise:new(function(a, b)
    resolve = a
    reject = b
  end)

  p:next(lu.done, function() lu.done("The promise should not be rejected.") end)

  resolve()
  returnValue = reject(thenable)

  lu.assertEquals(returnValue, nil, '"reject" function return value')
end
