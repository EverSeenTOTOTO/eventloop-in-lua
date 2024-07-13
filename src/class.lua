-- create Javascript style class

local function setPrototype(o, proto)
  proto = proto or o.__proto__
  setmetatable(o, proto)
  proto.__index = proto
end

local function getPrototype(o) return o.__proto__ end

local function createClass(prototype)
  local class = {}

  class.prototype = prototype or {}
  class.prototype.constructor = class.prototype.constructor or function(instance, ...) return instance end

  -- useful when we want to access class itself in prototype methods.
  -- In Javascript, it is actually the constructor (class.prototype.constructor === class)
  -- In Lua, our class is a table while constructor is a function, so we need to distinguish them.
  class.prototype.class = class

  -- create new instance, instance.__proto__ === self.prototype
  function class:new(...)
    local instance = { __proto__ = self.prototype }

    setPrototype(instance)

    return self.prototype.constructor(instance, ...) or instance
  end

  -- create derived class, derived.prototype -> self.prototype
  function class:extend(newPrototype)
    newPrototype = newPrototype or {}

    newPrototype.super = self.prototype

    -- prototype members, e.g. constructor, ...
    newPrototype.__proto__ = self.prototype
    setPrototype(newPrototype)

    local derived = createClass(newPrototype)

    newPrototype.class = derived

    -- static members, e.g. new, extend, ...
    setPrototype(derived, self)

    return derived
  end

  function class:isDerived(derived) return self:isInstance(derived.prototype) end

  function class:isInstance(instance)
    if type(instance) ~= "table" then return false end

    local proto = getPrototype(instance)
    while proto ~= nil do
      if proto == self.prototype then return true end
      proto = getPrototype(proto)
    end

    return false
  end

  return class
end

return createClass
