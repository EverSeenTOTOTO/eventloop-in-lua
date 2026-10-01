local uv = require("luv")
local internal = require("src/internal")

local microtasks = internal.microtasks
local unhandled = internal.unhandled
local dict = internal.dict

-- both the head cursor and the tail are tracked explicitly: table.remove(microtasks, 1)
-- is O(n) per pop, and `#microtasks` is undefined on a table with nil holes.
-- The shared cursor also makes flushMicrotasks reentrant for free: a nested call
-- joins the same drain loop instead of dispatching tasks twice.
-- An error thrown by a task propagates, leaving the unflushed tasks queued.
local function flushMicrotasks()
  while microtasks.head <= microtasks.tail do
    local pending = microtasks[microtasks.head]
    microtasks[microtasks.head] = nil
    microtasks.head = microtasks.head + 1
    pending()
  end

  microtasks.head, microtasks.tail = 1, 0
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
  -- the timer may have already fired and closed, closing it again would abort libuv
  if uv.is_closing(timer) then return end
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
  queueMicrotask = function(task)
    microtasks.tail = microtasks.tail + 1
    microtasks[microtasks.tail] = task
  end,
  startEventLoop = function(main)
    main()
    flushMicrotasks()
    uv.run("default")

    assert(microtasks.head > microtasks.tail, "microtask queue should be empty after event loop")

    for p in pairs(unhandled) do
      unhandled[p] = nil
      error(string.format("unhandledRejection detected:\n\t%s", tostring(dict[p].pdata)))
    end
  end,
}
