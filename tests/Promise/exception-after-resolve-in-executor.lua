return function(lu)
  local Promise = require("src/promise")

  local thenable = {
    next = function(_, resolve) resolve() end,
  }

  local function executor(resolve)
    resolve(thenable)
    error("ignored exception")
  end

  Promise:new(executor):next(lu.done, lu.done)
end
