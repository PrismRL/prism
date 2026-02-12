--- @class HeartbeatEffectOptions
--- @field bpm? number
--- @field amplitude? number
--- @field bias? number
--- @field sharpness? number

--- A light effect that pulses the light like a heartbeat.
--- @class HeartbeatEffect : LightEffect
--- @overload fun(options?: HeartbeatEffectOptions): HeartbeatEffect
local HeartbeatEffect = prism.lighting.LightEffect:extend "HeartbeatEffect"

--- @param opts HeartbeatEffectOptions
function HeartbeatEffect:__new(opts)
   opts = opts or {}

   -- Beats per minute
   self.bpm = opts.bpm or 43

   -- Intensity of the pulse
   self.amplitude = opts.amplitude or 0.17

   -- Baseline multiplier
   self.bias = opts.bias or 1.0

   -- Controls how sharp the pulse is (higher = snappier)
   self.sharpness = opts.sharpness or 6.0
end

--- @param time number
--- @param color Color4
--- @param x integer
--- @param y integer
--- @return Color4
function HeartbeatEffect:effect(time, color, x, y)
   -- Convert BPM to seconds per beat
   local period = 60 / self.bpm

   -- Phase in [0, 1)
   local t = (time % period) / period

   -- Primary beat (sharp spike)
   local beat1 = math.exp(-self.sharpness * (t / 0.15) ^ 2)

   -- Secondary beat (weaker, delayed)
   local dt = t - 0.25
   local beat2 = math.exp(-self.sharpness * (dt / 0.12) ^ 2) * 0.5

   local pulse = beat1 + beat2
   local scale = self.bias + pulse * self.amplitude

   return prism.Color4(
      math.max(0, color.r * scale),
      math.max(0, color.g * scale),
      math.max(0, color.b * scale),
      color.a
   )
end

return HeartbeatEffect
