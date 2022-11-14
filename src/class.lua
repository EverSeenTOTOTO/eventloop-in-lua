-- create Javascript style class
return function(ctor, o)
  o = o or {}
  o.prototype = o.prototype or {}
  ctor = ctor or function(instance) return instance end

  function o:new(...)
    local instance = {
      __proto__ = o.prototype,
    }

    setmetatable(instance, o.prototype)
    o.prototype.__index = o.prototype

    -- ctor can be used to perform extra operations
    return ctor(instance, ...)
  end

  function o:extend()
    local derived = {}

    setmetatable(derived, self)
    self.__index = self

    return derived
  end

  return o
end
