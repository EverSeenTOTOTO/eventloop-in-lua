return function(lu)
  local Promise = require("src/promise")

  local thenable = {
    next = function(_, resolve) resolve() end,
  }

  local thenableWithError = {
    next = function(_, resolve)
      resolve(thenable)
      error("ignored exception")
    end,
  }

  local function executor(resolve) resolve(thenableWithError) end

  Promise:new(executor):next(function() lu.done() end, lu.done)
end
