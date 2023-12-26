return function(lu)
  local Promise = require("src/promise")

  lu.assertEquals(type(Promise), 'table')
end
