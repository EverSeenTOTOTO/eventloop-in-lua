return function(lu)
  local Promise = require("src/promise")

  -- a promise returned from the handler is assimilated, just like resolve(promise)
  Promise:resolve(1):next(function() return Promise:resolve(42) end):next(function(value)
    if value ~= 42 then
      lu.done("The derived promise should be fulfilled with the returned promise's value.")
      return
    end

    lu.done()
  end, function() lu.done("The derived promise should not be rejected.") end)
end
