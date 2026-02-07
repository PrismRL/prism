--- A light to emit from an entity.
--- @class Light : Component
--- @field private color Color4
--- @overload fun(color: Color4, radius: integer, effect?: LightEffect): Light
local Light = prism.Component:extend "Light"

function Light:__new(color, radius, effect)
   self.color = color
   self.radius = radius
   self.lightEffect = effect
end

function Light:attenuate(distance)
   local atten = math.max(0, (self.radius - distance) / self.radius)
   return atten * atten
end

function Light:getColor()
   return self.color
end

return Light
