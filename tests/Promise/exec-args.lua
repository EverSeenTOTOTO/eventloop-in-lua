return function(lu)
  local Promise = require("src/promise")

  local resolve, reject

  Promise:new(function(a, b)
    resolve = a
    reject = b
  end)

  lu.assertEquals(type(resolve), "function")
  lu.assertEquals(type(reject), "function")
end
