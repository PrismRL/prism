--- @class LightEffect: Object
local LightEffect = prism.Object:extend "LightEffect"

--- @param time number
--- @param color Color4
--- @return Color4 color
function LightEffect:effect(time, color)
   return color -- OVERRIDE ME!
end

return LightEffect
