-- create Javascript style class
return function(ctor, o)
  o = o or {}
  o.prototype = o.prototype or {}
  ctor = ctor or function(instance) return instance end

  -- useful when we want to access class itself in prototype methods
  o.prototype.constructor = o

  local function setprototype(t, p)
    setmetatable(t, p)
    p.__index = p
  end

  -- create instance
  function o:new(...)
    local instance = {
      __proto__ = self.prototype,
    }

    setprototype(instance, instance.__proto__)

    -- ctor can be used to perform extra operations before return instance
    return ctor(instance, self, ...) or instance
  end

  -- create derived class
  function o:extend()
    local derived = { prototype = { __proto__ = self.prototype } }

    derived.prototype.constructor = derived

    setprototype(derived.prototype, derived.prototype.__proto__)
    setprototype(derived, self)

    return derived
  end

  function o:isDerived(clazz)
    return clazz.prototype and clazz.prototype.__proto__ and clazz.prototype.__proto__ == self.prototype or false
  end

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
