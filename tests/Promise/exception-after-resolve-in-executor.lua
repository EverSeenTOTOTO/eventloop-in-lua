return function(lu)
  local Promise = require("src/promise")

  local thenable = {
    next = function(resolve) resolve() end,
  }

  local function executor(resolve, reject)
    resolve(thenable)
    error("ignored exception")
  end

  Promise:new(executor):next(lu.done, lu.done)
end
