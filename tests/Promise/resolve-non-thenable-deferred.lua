return function(lu)
  local Promise = require("src/promise")

  local returnValue = 42
  local nonThenable = {
    next = nil,
  }
  local resolve
  local p = Promise:new(function(res) resolve = res end)

  p:next(function(value)
    if value ~= nonThenable then
      lu.done("The promise should be fulfilled with the provided value.")
      return
    end

    lu.done()
  end, function() lu.done("The promise should not be rejected.") end)

  returnValue = resolve(nonThenable)

  lu.assertEquals(returnValue, nil, '"resolve" function return value')
end
