local uv = require("luv")

local microtasks = {}

local function flushMicrotasks()
  while #microtasks > 0 do
    local pending = microtasks[1]
    table.remove(microtasks, 1)
    pending()
  end
end

local function setTimeout(callback, timeout)
  local timer = uv.new_timer()
  local function ontimeout()
    uv.timer_stop(timer)
    uv.close(timer)
    callback()
    flushMicrotasks()
  end
  uv.timer_start(timer, timeout, 0, ontimeout)
  return timer
end

local function clearTimeout(timer)
  uv.timer_stop(timer)
  uv.close(timer)
end

local function setInterval(callback, interval)
  local timer = uv.new_timer()
  local function ontimeout()
    callback()
    flushMicrotasks()
  end
  uv.timer_start(timer, interval, interval, ontimeout)
  return timer
end

return {
  setTimeout = setTimeout,
  clearTimeout = clearTimeout,
  setInterval = setInterval,
  clearInterval = clearTimeout,
  flushMicrotasks = flushMicrotasks,
  queueMicrotask = function(task) table.insert(microtasks, task) end,
  startEventLoop = function(main)
    main()
    flushMicrotasks()
    uv.run("default")
    assert(#microtasks == 0, "microtask queue should be empty after event loop")
  end,
}
