local pending = {}

local function eventLoop(main, ...)
  local value, status = main(...)

  while #pending > 0 do
    pending[1]()
    table.remove(pending, 1)
  end

  return value, status
end

return {
  eventLoop = eventLoop,
  microtask = function(task) table.insert(pending, task) end,
}
