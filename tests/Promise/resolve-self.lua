return function(lu)
  local Promise = require("src/promise")

  local returnValue = 42
  local resolve

  local promise = Promise:new(function(res) resolve = res end)

  promise:next(function() lu.done("The promise should not be fulfilled.") end, function(reason)
    if reason == nil then
      lu.done("The promise should be rejected with a value.")
      return
    end

    lu.assertStrContains(reason, "Promise-chain cycle", "The promise should be rejected with a TypeError instance.")
  end)

  returnValue = resolve(promise)

  lu.assertEquals(returnValue, nil, '"resolve" function return value')
end
