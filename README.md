# eventloop-in-lua

Simulate the `async/await` syntax sugar and the eventloop behavior in Javascript when using Lua coroutines, based on [luv](https://github.com/luvit/luv/tree/master).

```lua
local uv = require("luv")

local function sleep(cost)
  return Promise:new(function(resolve)
    eventLoop.setTimeout(resolve, cost)
  end)
end

local readFile = function(path, callback)
  local fd = assert(uv.fs_open(path, "r", 438))
  local stat = assert(uv.fs_fstat(fd))
  local data = assert(uv.fs_read(fd, stat.size, 0))
  assert(uv.fs_close(fd))
  callback(data)
  -- to emulate NodeJS behavior, we need to flush microtasks manually after each (macro)task
  eventLoop.flushMicrotasks()
end

local readFileAsync = function(path)
  return Promise:new(function(resolve)
    readFile(path, resolve)
  end)
end

local start = uv.hrtime()
local count = function(name)
  return function()
    print(string.format("%s elapsed %fs", name, (uv.hrtime() - start) / 1e6))
  end
end

local main = async {
  function()
    -- try remove await{} here to see what happens
    await { sleep(500):next(count('timer')) }
    await { readFileAsync('README.md'):next(count('io')) }
    await { sleep(1000) }
    count('main')()
  end,
}

eventLoop.startEventLoop(main)
```

Output:

```
timer elapsed 497.526845s
io elapsed 497.931135s
main elapsed 997.841181s
```

## API

  See [tests](./tests) for more examples.

+ `eventLoop`

  - `setTimeout(callback, delay)`
  - `clearTimeout(timer)`
  - `setInterval(callback, delay)`
  - `clearInterval(timer)`
  - `queueMicrotask(microtask)`
  - `flushMicrotasks()`
  - `startEventLoop(main)`

+ `Promise`

  Static methods:

  - `Promise:new(executor)`
  - `Promise:extend(class)`
  - `Promise:isInstance(instance)`
  - `Promise:isDerived(class)`
  - `Promise:resolve(data)`
  - `Promise:reject(err)`
  - `Promise:all`(TODO)
  - `Promise:any`(TODO)
  - `Promise:race`(TODO)
  - `Promise:allSettled`(TODO)

  Instance methods:

  - `promise:next(onFulfilled, onRejected)`
  - `promise:catch(onRejected)`
  - `promise:finally`(TODO)

+ `async`

  A high-order function accepts a coroutine function and returns a function that returns a `Promise` once executed.

+ `await`

  A wrap function for `coroutine.yield`, accepts anything and promisify them, returns `result, true` if the promise got fulfilled and `result, false` if it encountered an error.

  ```lua
  async {function()
    await { 42 } -- coroutine.yield(Promise:new(function(resolve) resolve(42) end))
    await { "hello world" }
    await { Promise:new(...) }
  end}
  ```

## Important Note

You may write codes like this:

```lua
async {function main() await ... end}
main() -- will not work!
```

The reason is that `async` is a wrapper function, and its parameter should be a coroutine function which cannot be executed directly. This is not the same as Javascript keyword `async`. In the case above, `main` function is more similar to `function* main() yield...` in Javascript.

What you want is probably this:

```lua
local main = async {function() await ... end}
main()
```

## How to?

Function apply `foo({bar})` can be represented by `foo {bar}` in Lua, which is commonly used to create DSLs, we use this feature to simulate `async/await` keywords.

To see how to implement `async/await` with coroutine, you can read my code gist [here](https://gist.github.com/EverSeenTOTOTO/ac0a60de5568be71f6fc80c9e155ac7f).
