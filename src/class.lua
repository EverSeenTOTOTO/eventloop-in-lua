-- create Javascript style class
return function(ctor, o)
  o = o or {}
  o.prototype = o.prototype or {}
  ctor = ctor or function(instance) return instance end

  -- useful when we want to access class itself in prototype methods
  o.prototype.constructor = o

  local function setPrototype(t, p)
    setmetatable(t, p)
    p.__index = p
  end

  local function newInstance(self)
    local instance = {
      __proto__ = self.prototype,
    }

    setPrototype(instance, instance.__proto__)

    return instance
  end

  -- create instance
  function o:new(...)
    local instance = newInstance(self)

    -- ctor can be used to perform extra operations before return instance
    return ctor(instance, self, ...) or instance
  end

  -- create derived class
  function o:extend()
    local derived = { prototype = newInstance(self) }

    derived.prototype.constructor = derived
    setPrototype(derived, self)

    return derived
  end

  function o:isDerived(class) return self:isInstance(class.prototype) end

  function o:isInstance(instance)
    local status, proto = pcall(function() return instance.__proto__ end)

    while status and proto ~= nil do
      if proto == self.prototype then return true end
      status, proto = pcall(function() return proto.__proto__ end)
    end

    return false
  end

  return o
end
