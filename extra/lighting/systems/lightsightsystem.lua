--- @class LightSightSystem : SightSystem
--- @field private lightColor Color4
--- @field private position Vector2
--- @field private actorPosition Vector2
--- @field private removedPositions Vector2[]
local LightSightSystem = prism.systems.SightSystem:extend "LightSightSystem"

LightSightSystem.DEFAULT_DARKVISION = 2 / 16

function LightSightSystem:initialize(level)
   self.super.initialize(self, level)
   self.lightColor = prism.Color4()
   self.position = prism.Vector2()
   self.actorPosition = prism.Vector2()
   self.removedPositions = {}
end

-- These functions update the fov and visibility of actors on the level.
---@param level Level
---@param actor Actor
function LightSightSystem:onSenses(level, actor)
   -- check if actor has a sight component and if not return
   local sensesComponent = actor:get(prism.components.Senses)
   if not sensesComponent then return end

   local sightComponent = actor:get(prism.components.Sight)
   if not sightComponent then return end

   local actorPos = actor:getPosition(self.actorPosition)
   if not actorPos then return end

   local sightLimit = sightComponent:getRange()
   -- we check if the sight component has a fov and if so we clear it
   if sightComponent:hasFov() then
      self.computeFOV(level, sensesComponent, actorPos, sightLimit)
   else
      -- we have a sight component but no fov which essentially means the actor has blind sight and can see
      -- all cells within a certain radius  generally only simple actors have this vision type
      for x = actorPos.x - sightLimit, actorPos.x + sightLimit do
         for y = actorPos.y - sightLimit, actorPos.y + sightLimit do
            sensesComponent.cells:set(x, y, level:getCell(x, y))
         end
      end
   end

   local lightSystem = level:getSystem(prism.systems.LightSystem)
   --- @cast lightSystem LightSystem

   local darkvision = sightComponent.darkvision or self.DEFAULT_DARKVISION
   local removed, count = self.removedPositions, 0
   local vec = self.position
   for x, y, cell in sensesComponent.cells:each() do
      local value = lightSystem:getValuePerspective(x, y, actor, self.lightColor)
      local luminance = value and value:average() or 0

      vec:compose(x, y)
      if luminance < darkvision and actorPos:distanceChebyshev(vec) > 1 then
         count = count + 1
         removed[count] = removed[count] or prism.Vector2()
         removed[count]:compose(x, y)
      end
   end

   for i = 1, count do
      local position = removed[i]
      sensesComponent.cells:set(position.x, position.y, nil)
   end

   self:updateSeenActors(level, actor)
end

return LightSightSystem
