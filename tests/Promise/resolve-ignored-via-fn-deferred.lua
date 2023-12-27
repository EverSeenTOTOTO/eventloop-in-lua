return function(lu)
  local Promise = require("src/promise")

  local returnValue = 42
  local thenable = Promise:new(function() end)
  local resolve, reject
  local p = Promise:new(function(res, rej)
    resolve = res
    reject = rej
  end)

  p:next(function() lu.done("The promise should not be fulfilled.") end, function() lu.done() end)

  reject(thenable)
  returnValue = resolve()

  lu.assertEquals(returnValue, nil, '"resolve" function return value')
end
