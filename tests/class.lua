return function(lu)
  local createClass = require("src/class")

  return {
    testPrototype = function()
      local Base = createClass()
      local Derived = Base:extend()
      local Derived2 = Derived:extend()

      lu.assertEquals(Base:isDerived(Derived), true)
      lu.assertEquals(Base:isDerived(Derived2), true)
      lu.assertEquals(Derived:isDerived(Derived2), true)

      local foo = Base:new()
      local bar = Derived:new()

      lu.assertEquals(Base:isInstance(foo), true)
      lu.assertEquals(Base:isInstance(bar), true)
      lu.assertEquals(Derived:isInstance(foo), false)
      lu.assertEquals(Derived:isInstance(bar), true)
    end,
    testConstructor = function()
      local Base = createClass(function(this, foo) this.foo = foo end)

      local bar = Base:new(42)

      lu.assertEquals(bar.foo, 42)
    end,
    testProperties = function()
      local Base = createClass(function(this, foo) this.foo = foo end)

      -- normal method
      function Base.prototype:normal() return self.foo end

      -- static method
      function Base:static(foo) return self:new(foo) end

      local Derived = Base:extend()

      local foo = Base:new(42)
      local bar = Derived:new(24)

      lu.assertEquals(foo:normal(), 42)
      lu.assertEquals(bar:normal(), 24)

      local baz = Derived:static(0)

      lu.assertEquals(Derived:isInstance(baz), true)
      lu.assertEquals(baz:normal(), 0)

      baz.foo = 1
      lu.assertEquals(baz:normal(), 1)
    end,
  }
end
