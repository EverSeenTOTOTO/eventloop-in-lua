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
    print(string.format("%s end %fms", name, (uv.hrtime() - start) / 1e6))
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
timer end 497.156447ms
io end 499.710329ms
main end 1498.829462ms
```

## Run

Install [luv](https://github.com/luvit/luv) first, e.g. `luarocks install luv`, then:

```bash
make test   # test suite
make start  # example entry
```

The makefile picks the first interpreter (`luajit` or `lua`) that can `require("luv")`; override it with `make LUA=lua5.4 test` if needed.

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
  - `Promise:all(list)`
  - `Promise:any(list)`
  - `Promise:race(list)`
  - `Promise:allSettled(list)`

  Instance methods:

  - `promise:next(onFulfilled, onRejected)`
  - `promise:catch(onRejected)`
  - `promise:finally(onFinally)`

  The combinators (`all`/`any`/`race`/`allSettled`) accept array-like tables, and their elements are promisified just like `Promise:resolve`.

  - `all` rejects with the first rejection reason, otherwise fulfills with all values in list order.
  - `any` fulfills with the first fulfilled value, otherwise rejects with an `AggregateError`-like table `{ name = "AggregateError", errors = { ... } }`.
  - `race` settles with the first settled element (an empty list stays pending forever).
  - `allSettled` never rejects, it fulfills with `{ { status = "fulfilled", value = ... }, { status = "rejected", reason = ... } }`.
  - `finally` calls `onFinally` without arguments on settlement; the original value/reason passes through unless `onFinally` returns a rejecting promise or throws. A non-callable `onFinally` is ignored, like `promise:next(nil)`.

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

## Important Notes

1. You may write codes like this:

```lua
async {function main() await ... end}
main() -- will not work!
```

The reason is that `async` acts a wrapper function, taking a coroutine function as its parameter that cannot be directly executed.. This differs from the `async` keyword in Javascript. In the provided case, the `main` function is more similar to a generator function `function* main() yield...` in Javascript.

What you want is probably this:

```lua
local main = async {function() await ... end}
main()
```

2. Lua's coroutines are stackful, unlike JavaScript's stackless coroutines. This difference allows you to write code in Lua that would be impossible in JavaScript, as follows:

```lua
local main = async {
  function()
    local foo = function()
      local bar = function()
        local baz = function()
          return await { 42 }
        end

        return baz()
      end
      return bar()
    end

    local r = await { foo() }
    print(r) -- 42
  end
}
```


## How to?

Function apply `foo({bar})` can be represented by `foo {bar}` in Lua, which is commonly used to create DSLs, we use this feature to simulate `async/await` syntax.

To see how to implement `async/await` with coroutine, you can read my code gist [here](https://gist.github.com/EverSeenTOTOTO/ac0a60de5568be71f6fc80c9e155ac7f).
