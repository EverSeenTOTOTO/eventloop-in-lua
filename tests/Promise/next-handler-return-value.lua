return function(lu)
  local Promise = require("src/promise")

  Promise:resolve(1):next(function() return 42 end):next(function(value)
    if value ~= 42 then
      lu.done("The derived promise should be fulfilled with the handler's return value.")
      return
    end

    lu.done()
  end, function() lu.done("The derived promise should not be rejected.") end)
end
