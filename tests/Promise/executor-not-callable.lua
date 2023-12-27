return function(lu)
  local Promise = require("src/promise")

  lu.assertThrows(function() Promise:new("not callable") end)

  lu.assertThrows(function() Promise:new(1) end)

  lu.assertThrows(function() Promise:new(nil) end)

  lu.assertThrows(function() Promise:new {} end)
end
