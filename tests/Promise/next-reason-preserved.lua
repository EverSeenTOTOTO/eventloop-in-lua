return function(lu)
  local Promise = require("src/promise")

  -- the rejection reason should survive intermediate handlers unchanged
  Promise:reject("boom"):next(function() end):next(function() end, function(reason)
    if reason ~= "boom" then
      lu.done("The rejection reason should be preserved across handlers, got: " .. tostring(reason))
      return
    end

    lu.done()
  end)
end
