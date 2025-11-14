local Log = prism.components.Log
local Name = prism.components.Name

-- Filters inventory items that have an Equipment component
-- and can be equipped by the acting entity.
-- stylua: ignore
local EquipTarget = prism.targets.InventoryTarget(prism.components.Equipment)
   :filter(function(level, owner, target)
      local equipper = owner:expect(prism.components.Equipper)
      return equipper:canEquip(target)
   end)

--- @class Equip : Action
--- Action that equips an item from the actor's inventory into the appropriate slot(s).
--- Applies any associated status effects.
--- @field targets table Target filter selecting valid equipment items.
--- @field requiredComponents Component[] Components required for this action to execute (Equipper, Inventory).
local Equip = prism.Action:extend "Equip"
Equip.targets = { EquipTarget }
Equip.requiredComponents = {
   prism.components.Equipper,
   prism.components.Inventory,
}

--- @param actor Actor
function Equip:perform(level, actor)
   local equipper = self.owner:expect(prism.components.Equipper)
   local equipment = actor:expect(prism.components.Equipment)

   -- Fill all required slots for this equipment.
   for requiredCategory, count in pairs(equipment.requiredCategories) do
      for _ = 1, count do
         for _, slot in ipairs(equipper.slots) do
            if not equipper.equipped[slot.name] and slot.category == requiredCategory then
               equipper.equipped[slot.name] = actor
               break
            end
         end
      end
   end

   self.owner:expect(prism.components.Inventory):removeItem(actor)

   local conditions = self.owner:get(prism.components.ConditionHolder)
   if conditions and equipment.condition then
      equipper.statusMap[actor] = conditions:add(equipment.condition)
   end

   if Log then
      Log.addMessage(self.owner, "You equip the %s.", Name.get(actor))
      Log.addMessageSensed(
         level,
         self,
         "The %s equips the %s.",
         Name.get(self.owner),
         Name.get(actor)
      )
   end
end

return Equip
