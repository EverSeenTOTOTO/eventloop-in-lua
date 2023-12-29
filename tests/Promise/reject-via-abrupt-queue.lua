return function(lu)
  local Promise = require("src/promise")

  local thenable = Promise:resolve(42)
  local p = Promise:new(function() error(thenable) end)

  p:next(function() lu.done("The promise should not be fulfilled.") end)
    :next(function() lu.done("The promise should not be fulfilled.") end, function(x)
      if x ~= thenable then
        lu.done("The promise should be rejected with the resolution value.")
        return
      end
      lu.done()
    end)
end
