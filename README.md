# async-await-in-lua

Simulate the `async/await` syntax sugar in Javascript when writing Lua coroutines...

```lua
local uv = require('luv')

local function setTimeout(callback, delay)
  local t = uv.new_timer()
  uv.timer_start(t, delay, 0, function()
    uv.timer_stop(t)
    uv.close(t)
    callback()
  end)
  return t
end

local function sleep(cost)
  return Promise:new(function(resolve)
    setTimeout(resolve, cost)
  end)
end

local main = async {
  function()
    local start = os.time()

    await { sleep(1000) }

    print(string.format("elapsed %fs", os.time() - start)) -- elapsed 1.000000s
  end,
}

main()
```

## API

  See [tests](./tests) for more examples.

+ `Promise`

  Static methods:

  - `Promise:new`

  - `Promise:extend`

  - `Promise:isInstance`

  - `Promise:isDerived`

  - `Promise:resolve`

  - `Promise:reject`

  - `Promise:all`(TODO)

  - `Promise:any`(TODO)

  - `Promise:race`(TODO)

  - `Promise:allSettled`(TODO)

  Instance methods:

  - `promise:next`

  - `promise:catch`

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

## Important Notes

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
