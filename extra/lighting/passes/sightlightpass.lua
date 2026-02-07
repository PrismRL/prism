--- A display pass that modifies the colour of every cell/actor based on the perspective of a player actor.
--- @class SightLightPass : DisplayPass
--- @overload fun(lightSystem: LightSystem): SightLightPass
local SightLightPass = spectrum.DisplayPass:extend "SightLightPass"

--- @param lightSystem LightSystem
function SightLightPass:__new(lightSystem)
   self.lightSystem = lightSystem
end

--- @param player Actor
function SightLightPass:setPlayer(player)
   self.player = player
end

local dummy = prism.Color4()
function SightLightPass:run(entity, x, y, drawable)
   local sight = self.player:get(prism.components.Sight)
   local darkvision = sight and sight.darkvision or 0

   local light = self.lightSystem:getRTValuePerspective(x, y, self.player)
   light = light or dummy

   -- Preserve original color
   local base = drawable.color:copy()
   local baseBackground = drawable.background:copy()

   -- Apply lighting normally
   if prism.Actor:is(entity) then
      local value = math.min(light:average(), 1)
      drawable.color = drawable.color * value
      drawable.background = drawable.background * value
   else
      drawable.color.r = drawable.color.r * light.r
      drawable.color.g = drawable.color.g * light.g
      drawable.color.b = drawable.color.b * light.b

      drawable.background.r = drawable.background.r * light.r
      drawable.background.g = drawable.background.g * light.g
      drawable.background.b = drawable.background.b * light.b
   end

   -- Linear darkness (no perceptual luminance)
   local brightness = drawable.color:average()
   local darkness = math.min(math.max(1 - brightness, 0), 1)
   darkness = math.max(darkness - darkvision, 0)

   -- Knee at 0.25: everything below stays bright
   if darkness <= 0.6 then
      darkness = 0
   else
      -- Remap [0.25 .. 1] → [0 .. 1]
      darkness = (darkness - 0.6) / 0.4
   end

   -- Shape the curve (optional but recommended)
   local restore = math.pow(darkness, 1.5)
   local alphaLoss = darkness * 0.70

   -- Lerp back toward base color
   drawable.color = drawable.color:lerp(base, restore)
   drawable.background = drawable.background:lerp(baseBackground, restore)
   -- Fade opacity as darkness increases
   drawable.color.a = base.a * (1 - alphaLoss)
end

return SightLightPass
