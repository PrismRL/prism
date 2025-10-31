local Log = prism.components.Log
local Name = prism.components.Name

-- Selects equipped items belonging to the actor that can be removed.
local UnequipTarget =
   prism.Target()
   :outsideLevel()
   :with(prism.components.Equipment)
   :filter(function(_, owner, target)
      local equipper = owner:expect(prism.components.Equipper)
      return equipper:isEquipped(target)
   end)

--- @class Unequip : Action
--- Action that removes an equipped item from the actor and returns it to their inventory.
--- Also clears any active status effects granted by the equipment.
--- @field targets table Target filter selecting valid equipped items.
--- @field requiredComponents Component[] Components required for this action (Equipper, Inventory).
local Unequip = prism.Action:extend "Unequip"
Unequip.targets = { UnequipTarget }
Unequip.requiredComponents = {
   prism.components.Equipper,
   prism.components.Inventory
}

--- Performs the unequip action on the given item.
--- Removes it from equipped slots, restores it to inventory,
--- and removes its status effects.
--- @param level Level The current level or world state.
--- @param actor Actor The equipment actor being unequipped.
function Unequip:perform(level, actor)
   local equipper = self.owner:expect(prism.components.Equipper)

   -- Free any slot occupied by this actor.
   for i, a in pairs(equipper.equipped) do
      if a == actor then
         equipper.equipped[i] = nil
      end
   end

   -- Add the item back to the owner's inventory.
   local inventory = self.owner:expect(prism.components.Inventory)
   inventory:addItem(actor)

   -- Remove any associated status effects.
   local status = self.owner:get(prism.components.StatusEffects)
   if status and equipper.statusMap[actor] then
      status:remove(equipper.statusMap[actor])
   end

   -- Log the unequip event for both the actor and observers.
   if Log then
      Log.addMessage(self.owner, "You unequip the %s.", Name.get(actor))
      Log.addMessageSensed(level, self, "The %s unequips the %s.", Name.get(self.owner), Name.get(actor))
   end
end

return Unequip
