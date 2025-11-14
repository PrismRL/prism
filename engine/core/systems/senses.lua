--- @class SensesSystem : System
local SensesSystem = prism.System:extend("SensesSystem")

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
   if not prism.Decision:is(event) then return end

   for actor in level:query(prism.components.Senses):iter() do
      if actor:get(prism.components.PlayerController) then self:triggerRebuild(level, actor) end
   end
end

--- @param level Level
--- @param actor Actor
function SensesSystem:triggerRebuild(level, actor)
   --- @type Senses
   local senses = actor:get(prism.components.Senses)
   if not senses then return end

   senses.cells = prism.SparseGrid()
   actor:removeAllRelations(prism.relations.SensesRelation)

   level:trigger("onSenses", level, actor)

   if not senses.explored or senses.explored ~= senses.exploredStorage[level] then
      senses.exploredStorage[level] = senses.exploredStorage[level] or prism.SparseGrid()
      senses.explored = senses.exploredStorage[level]
   end

   if not senses.remembered or senses.remembered ~= senses.exploredStorage[level] then
      senses.rememberedStorage[level] = senses.rememberedStorage[level] or prism.SparseGrid()
      senses.remembered = senses.rememberedStorage[level]
   end

   local temp = prism.Vector2(-1, -1)
   for x, y, cell in senses.cells:each() do
      senses.explored:set(x, y, cell)

      --- @type Actor?
      local remembered = senses.remembered:get(x, y)
      if remembered then
         remembered:getPosition(temp)
         if remembered.level ~= level or not temp:equals(x, y) then
            senses.remembered:set(x, y, nil)
         end
      end
   end

   for rememberedActor in
      level
         :query(prism.components.Drawable, prism.components.Remembered)
         :relation(actor, prism.relations.SensesRelation)
         :iter()
   do
      local x, y = rememberedActor:getPosition():decompose()
      senses.remembered:set(x, y, rememberedActor)
   end
end

return SensesSystem
