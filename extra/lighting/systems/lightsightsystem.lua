local LightSightSystem = prism.systems.SightSystem:extend "LightSightSystem"

LightSightSystem.DEFAULT_DARKVISION = 2 / 16

-- These functions update the fov and visibility of actors on the level.
---@param level Level
---@param actor Actor
function LightSightSystem:onSenses(level, actor)
   -- check if actor has a sight component and if not return
   local sensesComponent = actor:get(prism.components.Senses)
   if not sensesComponent then return end

   local sightComponent = actor:get(prism.components.Sight)
   if not sightComponent then return end

   local actorPos = actor:getPosition()
   if not actorPos then return end

   local sightLimit = sightComponent.range
   -- we check if the sight component has a fov and if so we clear it
   if sightComponent.fov then
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
   local removed = {}
   local actorPosition = actor:expectPosition()
   local vec = prism.Vector2()
   for x, y, cell in sensesComponent.cells:each() do
      local value = lightSystem:getValuePerspective(x, y, actor)
      local luminance = value and value:average() or 0

      vec:compose(x, y)
      if luminance < darkvision and actorPosition:distanceChebyshev(vec) > 1 then
         table.insert(removed, prism.Vector2(x, y))
      end
   end

   for _, vec in pairs(removed) do
      sensesComponent.cells:set(vec.x, vec.y, nil)
   end

   self:updateSeenActors(level, actor)
end

return LightSightSystem

