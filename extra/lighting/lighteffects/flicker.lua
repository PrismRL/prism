--- @class TorchFlicker : LightEffect
--- @field baseIntensity number
--- @field flickerAmplitude number
--- @field colorShift number
--- @field speedA number
--- @field speedB number
--- @field speedC number
local TorchFlicker = prism.lighting.LightEffect:extend "Flicker"

--- @param opts table?
function TorchFlicker:__new(opts)
   opts = opts or {}

   self.flickerAmplitude = opts.flickerAmplitude or 0.3
   self.baseIntensity = 1 - self.flickerAmplitude
   self.colorShift = opts.colorShift or 0.2
   self.speed = opts.speed or 3
end

--- @param time number
--- @param color Color4
--- @return Color4
function TorchFlicker:effect(time, color)
   local flicker = love.math.noise(time * self.speed)

   local intensity = self.baseIntensity + flicker * self.flickerAmplitude

   local warm = flicker * self.colorShift

   return prism.Color4(
      math.max(0, color.r * intensity + warm),
      math.max(0, color.g * intensity),
      math.max(0, color.b * intensity - warm),
      color.a
   )
end

return TorchFlicker
