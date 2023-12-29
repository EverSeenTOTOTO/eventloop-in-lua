local uv = require("luv")
local el = require("src/eventLoop")

local fail = function(msg)
  print(msg)
  os.exit(1)
end

local once = false
local lu = {
  done = function(msg)
    if once == false then
      once = true
    else
      fail("done() called more than once")
    end

    if msg ~= nil then fail(msg) end
  end,
  assertEquals = function(lhs, rhs, msg)
    msg = msg or "assertEquals failed"
    if type(lhs) == "table" and type(rhs) == "table" then
      if #lhs ~= #rhs then fail(msg) end
      for i = 1, #lhs do
        if lhs[i] ~= rhs[i] then fail(msg) end
      end
      return
    end

    if lhs ~= rhs then fail(msg) end
  end,
  assertStrContains = function(str, pattern, msg)
    msg = msg or "assertStrContains failed"

    if not string.find(str, pattern:gsub("-", "%%-")) then fail(msg) end
  end,
  assertThrows = function(fn, msg)
    msg = msg or "assertThrows failed"

    local status, r = pcall(fn)
    if status then fail(msg) end
  end,
}

local function runGroupTests(path)
  local tests = require(path)(lu)
  for key, test in pairs(tests) do
    print(string.format("Running: %s:%s", path, key))
    once = false
    test()
  end
end

local function scandir(path)
  local fd = assert(uv.fs_scandir(path))
  local children = {}
  while true do
    local name, typo = uv.fs_scandir_next(fd)

    if name ~= nil then
      if name:sub(-3) == "lua" then table.insert(children, path .. "/" .. name:sub(0, -5)) end
      if typo == "directory" then
        for _, kid in ipairs(scandir(path .. "/" .. name)) do
          table.insert(children, kid)
        end
      end
    else
      break
    end
  end
  return children
end

local function runTests(path)
  local files = scandir(path)

  for _, file in ipairs(files) do
    local test = require(file)

    print(string.format("Running: %s", file))
    once = false
    el.startEventLoop(function() test(lu) end)
  end
end

runGroupTests("tests/class")
runGroupTests("tests/event-loop")
runTests("tests/Promise")
runGroupTests("tests/async-await")
