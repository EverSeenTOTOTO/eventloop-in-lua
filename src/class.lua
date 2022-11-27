-- create Javascript style class
return function(ctor, o)
  o = o or {}
  o.prototype = o.prototype or {}
  ctor = ctor or function(instance) return instance end

  function o:new(...)
    local instance = {
      __proto__ = self.prototype,
    }

    setmetatable(instance, instance.__proto__)
    instance.__proto__.__index = instance.__proto__

    -- ctor can be used to perform extra operations
    return ctor(instance, ...)
  end

  function o:extend()
    local derived = { prototype = { __proto__ = self.prototype } }

    -- derived.prototype = self.prototype:new()
    setmetatable(derived.prototype, derived.prototype.__proto__)
    derived.prototype.__proto__.__index = derived.prototype.__proto__

    setmetatable(derived, self)
    self.__index = self

    return derived
  end

  return o
end
