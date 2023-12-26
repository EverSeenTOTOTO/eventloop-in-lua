local uv = require('luv')

local lu = {
  assertEquals = function(lhs, rhs)
    if type(lhs) == 'table' and type(rhs) == 'table' then
      for i = 1, #lhs do
        if lhs[i] ~= rhs[i] then return false end
      end
      return true
    end

    assert(lhs == rhs)
  end,
  assertStrContains = function(str, pattern)
    assert(string.find(str, pattern))
  end,
}

local function scandir(path)
  local fd = assert(uv.fs_scandir(path))
  local children = {}
  while true do
    local name, typo = uv.fs_scandir_next(fd)

    if name ~= nil then
      if name:sub(-3) == 'lua' then
        table.insert(children, path .. '/' .. name:sub(0, -5))
      end
      if typo == 'directory' then
        for _, kid in ipairs(scandir(path .. '/' .. name)) do
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
    if file ~= 'tests/main' then
      local ret = require(file)(lu)
      if type(ret) == 'table' then
        for name, test in pairs(ret) do
          test()
          print(string.format("%s\t%s:%s", "PASS", file, name))
        end
      else
        print(string.format("%s\t%s", "PASS", file))
      end
    end
  end
end

runTests('tests')
