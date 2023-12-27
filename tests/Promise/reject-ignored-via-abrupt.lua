return function(lu)
  local Promise = require("src/promise")

  local thenable = Promise:new(function() end)
  local p = Promise:new(function(resolve)
    resolve()
    error(thenable)
  end)

  p:next(lu.done, function() lu.done("The promise should not be rejected.") end)
end
