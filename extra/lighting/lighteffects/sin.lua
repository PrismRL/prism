--- @class SineEffectOptions
--- @field amplitude? number
--- @field speed? number
--- @field spatialScale? number
--- @field noiseScale? number

--- An effect that makes the light wax and wane in a smooth wave.
--- @class SineEffect : LightEffect
--- @overload fun(options?: SineEffectOptions)
local SineEffect = prism.lighting.LightEffect:extend "SineEffect"

--- @param opts SineEffectOptions
function SineEffect:__new(opts)
   opts = opts or {}

   self.amplitude = opts.amplitude or 0.2
   self.speed = opts.speed or 2.0

   -- Frequency of spatial sampling
   self.spatialScale = opts.spatialScale or 0.15

   -- Strength of phase distortion
   self.noiseScale = opts.noiseScale or math.pi
end

--- @param time number
--- @param color Color4
--- @param x integer
--- @param y integer
--- @return Color4
function SineEffect:effect(time, color, x, y)
   -- Sample smooth spatial noise
   local n = love.math.noise(x * self.spatialScale, y * self.spatialScale)

   -- Map noise to phase offset
   local phase = n * self.noiseScale

   local s = math.sin(time * self.speed + phase)

   -- Base intensity derived from amplitude
   local baseIntensity = 1.0 - self.amplitude
   local scale = baseIntensity + s * self.amplitude

   return prism.Color4(
      math.max(0, color.r * scale),
      math.max(0, color.g * scale),
      math.max(0, color.b * scale),
      color.a
   )
end

return SineEffect
