--- @class SensesSystem : System
local SensesSystem = prism.System:extend("SensesSystem")
SensesSystem.name = "Senses"

function SensesSystem:onTurn(level, actor)
   if actor:has(prism.components.PlayerController) then return end
   self:triggerRebuild(level, actor)
end

function SensesSystem:postInitialize(level)
   for actor, _ in level:query(prism.components.Senses):iter() do
      self:triggerRebuild(level, actor)
   end
end

---@param level Level
---@param event Message
function SensesSystem:onYield(level, event)
   for actor in level:query(prism.components.Senses):iter() do
      if actor:get(prism.components.PlayerController) then self:triggerRebuild(level, actor) end
   end
end

function SensesSystem:triggerRebuild(level, actor)
   --- @type Senses
   local senses = actor:get(prism.components.Senses)
   if not senses then return end

   senses.cells = prism.SparseGrid()
   senses.actors = prism.ActorStorage()
   actor:removeAllRelationships(prism.relationships.Senses)

   level:trigger("onSenses", level, actor)

   if not senses.explored or senses.explored ~= senses.exploredStorage[level] then
      senses.exploredStorage[level] = senses.exploredStorage[level] or prism.SparseGrid()
      senses.explored = senses.exploredStorage[level]
   end

   if not senses.remembered or senses.remembered ~= senses.exploredStorage[level] then
      senses.rememberedStorage[level] = senses.rememberedStorage[level] or prism.SparseGrid()
      senses.remembered = senses.rememberedStorage[level]
   end

   for x, y, cell in senses.cells:each() do
      senses.explored:set(x, y, cell)
   end

   for rememberedActor in
      senses:query(prism.components.Drawable, prism.components.Remembered):iter()
   do
      local x, y = rememberedActor:getPosition():decompose()
      senses.remembered:set(x, y, rememberedActor)
   end
end

return SensesSystem
