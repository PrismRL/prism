--- @class FlickerEffectOptions
--- @field baseIntensity? number
--- @field speed? number
--- @field flickerAmplitude? number
--- @field colorShift? number

--- An effect that makes the light flicker, reminiscent of a torch.
--- @class FlickerEffect : LightEffect
--- @overload fun(options?: FlickerEffectOptions): FlickerEffect
local FlickerEffect = prism.lighting.LightEffect:extend "FlickerEffect"

--- @param opts FlickerEffectOptions
function FlickerEffect:__new(opts)
   opts = opts or {}

   self.flickerAmplitude = opts.flickerAmplitude or 0.3
   self.baseIntensity = 1 - self.flickerAmplitude
   self.colorShift = opts.colorShift or 0.2
   self.speed = opts.speed or 3
end

--- @param time number
--- @param color Color4
--- @return Color4
function FlickerEffect:effect(time, color)
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

return FlickerEffect
