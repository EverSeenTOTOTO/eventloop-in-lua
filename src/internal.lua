-- dict is weak-keyed so settled, unreachable promises can be collected.
-- unhandled keeps rejected promises without a rejection handler strongly referenced,
-- otherwise they would be collected before startEventLoop can audit them.
return {
  microtasks = { head = 1, tail = 0 },
  dict = setmetatable({}, { __mode = "k" }),
  unhandled = {},
}
