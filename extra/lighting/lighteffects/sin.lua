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
--- @param out? Color4
--- @param cache? table
--- @return Color4
function SineEffect:effect(time, color, x, y, out, cache)
   -- Sample smooth spatial noise
   local n
   if cache then
      if cache.spatialScale ~= self.spatialScale then
         cache.spatialScale = self.spatialScale
         cache.noise = {}
      end
      local key = prism.Vector2._hash(x, y)
      n = cache.noise[key]
      if n == nil then
         n = love.math.noise(x * self.spatialScale, y * self.spatialScale)
         cache.noise[key] = n
      end
   else
      n = love.math.noise(x * self.spatialScale, y * self.spatialScale)
   end

   -- Map noise to phase offset
   local phase = n * self.noiseScale

   local s = math.sin(time * self.speed + phase)

   -- Base intensity derived from amplitude
   local baseIntensity = 1.0 - self.amplitude
   local scale = baseIntensity + s * self.amplitude

   return prism.Color4.compose(
      out or prism.Color4(),
      math.max(0, color.r * scale),
      math.max(0, color.g * scale),
      math.max(0, color.b * scale),
      color.a
   )
end

return SineEffect
