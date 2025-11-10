local Log = prism.components.Log
local Name = prism.components.Name

-- stylua: ignore
local UnequipTarget = prism.Target()
   :outsideLevel()
   :with(prism.components.Equipment)
   :filter(function(_, owner, target)
      local equipper = owner:expect(prism.components.Equipper)
      return equipper:isEquipped(target)
   end)

--- Action that removes an equipped item from the actor and returns it to their inventory.
--- Also clears any active status effects granted by the equipment.
--- @class Unequip : Action
--- @field targets table Target filter selecting valid equipped items.
--- @field requiredComponents Component[] Components required for this action (Equipper, Inventory).
local Unequip = prism.Action:extend "Unequip"
Unequip.targets = { UnequipTarget }
Unequip.requiredComponents = {
   prism.components.Equipper,
   prism.components.Inventory,
}

--- @param level Level The current level or world state.
--- @param actor Actor The equipment actor being unequipped.
function Unequip:perform(level, actor)
   local equipper = self.owner:expect(prism.components.Equipper)

   for slot, equipped in pairs(equipper.equipped) do
      if equipped == actor then equipper.equipped[slot] = nil end
   end

   local inventory = self.owner:expect(prism.components.Inventory)
   inventory:addItem(actor)

   local status = self.owner:get(prism.components.ConditionHolder)
   if status and equipper.statusMap[actor] then status:remove(equipper.statusMap[actor]) end

   if Log then
      Log.addMessage(self.owner, "You unequip the %s.", Name.get(actor))
      Log.addMessageSensed(
         level,
         self,
         "The %s unequips the %s.",
         Name.get(self.owner),
         Name.get(actor)
      )
   end
end

return Unequip
