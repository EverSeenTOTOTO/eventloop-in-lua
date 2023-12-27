return function(lu)
  local Promise = require("src/promise")

  local thenable = {
    next = function(resolve) resolve() end,
  }

  local thenableWithError = {
    next = function(resolve)
      resolve(thenable)
      error("ignored exception")
    end,
  }

  local function executor(resolve) resolve(thenableWithError) end

  Promise:new(executor):next(lu.done, lu.done)
end
