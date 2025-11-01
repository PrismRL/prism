--- The Sight System manages the sight of actors. It is responsible for updating the FOV of actors, and
--- keeping track of which actors are visible to each other.
--- @class SightSystem : System
local SightSystem = prism.System:extend("SightSystem")

function SightSystem:getRequirements()
   return prism.systems.SensesSystem
end

-- These functions update the fov and visibility of actors on the level.
---@param level Level
---@param actor Actor
function SightSystem:onSenses(level, actor)
   -- check if actor has a sight component and if not return
   local sensesComponent = actor:get(prism.components.Senses)
   if not sensesComponent then return end
   --- @cast sensesComponent Senses

   local sightComponent = actor:get(prism.components.Sight)
   if not sightComponent then return end
   local sightLimit = sightComponent.range

   local actorPos = actor:getPosition()
   if not actorPos then return end

   -- we check if the sight component has a fov and if so we clear it
   if sightComponent.fov then
      local sightLimit = sightComponent.range
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

   self:updateSeenActors(level, actor)
end

---@param level Level
---@param actor Actor
function SightSystem:updateSeenActors(level, actor)
   -- if we don't have a sight component we return
   local sensesComponent = actor:get(prism.components.Senses)
   if not sensesComponent then return end

   actor:removeAllRelations(prism.relations.SeesRelation)

   for x, y, _ in sensesComponent.cells:each() do
      for other, _ in pairs(level.actorStorage:getSparseMap():get(x, y)) do
         actor:addRelation(prism.relations.SeesRelation, other)
         actor:addRelation(prism.relations.SensesRelation, other)
      end
   end
end

---@param level Level
---@param sensesComponent Senses
---@param origin Vector2
---@param maxDepth integer
function SightSystem.computeFOV(level, sensesComponent, origin, maxDepth)
   level:computeFOV(origin, maxDepth, function(x, y)
      sensesComponent.cells:set(x, y, level:getCell(x, y))
   end)
end

return SightSystem
