--- @class LightEffect: Object
--- @field spatiallyUniform boolean
local LightEffect = prism.Object:extend "LightEffect"

-- Custom effects remain spatial by default. Opt in only when the result is
-- independent of x/y. Effects may optionally write into out to avoid allocation.
LightEffect.spatiallyUniform = false

--- @param time number
--- @param color Color4
--- @param x? integer
--- @param y? integer
--- @param out? Color4
--- @param cache? table Per-light spatial cache, reset when the light is recast.
--- @return Color4 color
function LightEffect:effect(time, color, x, y, out, cache)
   return color -- OVERRIDE ME!
end

return LightEffect
