local pending = {}

local function eventLoop(main, ...)
  local value, status = main(...)

  while #pending > 0 do
    local n = #pending
    for i = 1, n do
      pending[i]()
      table.remove(pending, i)
      break
    end
  end

  return value, status
end

return {
  eventLoop = eventLoop,
  microtask = function(task) table.insert(pending, task) end,
}
