local uv = require("luv")
local el = require("src/eventLoop")

local lu = {
  done = function(msg) assert(msg == nil, msg) end,
  assertEquals = function(lhs, rhs, msg)
    if type(lhs) == "table" and type(rhs) == "table" then
      for i = 1, #lhs do
        if lhs[i] ~= rhs[i] then return false end
      end
      return true
    end

    assert(lhs == rhs, msg)
  end,
  assertStrContains = function(str, pattern, msg) assert(string.find(str, pattern:gsub("-", "%%-")), msg) end,
  assertThrows = function(fn, msg)
    local status = pcall(fn)
    assert(not status, msg)
  end,
}

local function runGroupTests(path)
  local tests = require(path)(lu)
  for key, test in pairs(tests) do
    test()
    print(string.format("PASS: %s:%s", path, key))
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

    el.startEventLoop(function() test(lu) end)
    print(string.format("PASS: %s", file))
  end
end

runGroupTests("tests/class")
runGroupTests("tests/event-loop")
runTests("tests/Promise")
runGroupTests("tests/async-await")
