return function(lu)
  local Promise = require("src/promise")

  local thenable = Promise:resolve()
  local returnValue = 42
  local p = Promise:new(function(_, reject) returnValue = reject(thenable) end)

  lu.assertEquals(returnValue, nil, '"reject" function return value')

  p:next(function() lu.done("The promise should not be fulfilled.") end, function(x)
    if x ~= thenable then
      lu.done("The promise should be rejected with the resolution value.")
      return
    end

    lu.done()
  end)
end
