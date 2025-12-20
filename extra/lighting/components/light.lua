--- @class Light : Component
--- @field private color Color4
--- @overload fun(color: Color4): Light
local Light = prism.Component:extend "Light"

function Light:__new(color, radius, effect)
   self.color = color
   self.radius = radius or 6
   self.lightEffect = effect
end

function Light:attenuate(distance, out)
   local atten = math.max(0, (self.radius - distance) / self.radius)
   return atten * atten
end

function Light:getColor()
   return self.color
end

return Light