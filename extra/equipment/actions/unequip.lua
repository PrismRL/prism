local Log = prism.components.Log
local Name = prism.components.Name

local UnequipTarget = 
   prism.Target()
   :outsideLevel()
   :with(prism.components.Equipment)
   :filter(function(_, owner, target)
      local equipper = owner:expect(prism.components.Equipper)
      return equipper:isEquipped(target)
   end)

--- @class Unequip : Action
local Unequip = prism.Action:extend "Unequip"
Unequip.targets = { UnequipTarget }
Unequip.requiredComponents = {
   prism.components.Equipper,
   prism.components.Inventory
}

--- @param level Level
--- @param actor Actor -- the item being unequipped
function Unequip:perform(level, actor)
   local equipper = self.owner:expect(prism.components.Equipper)

   for i, a in pairs(equipper.equipped) do
      if a == actor then
         equipper.equipped[i] = nil
      end
   end

   local inventory = self.owner:expect(prism.components.Inventory)
   inventory:addItem(actor)

   local status = self.owner:get(prism.components.StatusEffects)
   if status and equipper.statusMap[actor] then
      status:remove(equipper.statusMap[actor])
   end

   if Log then
      Log.addMessage(self.owner, "You unequip the %s.", Name.get(actor))
      Log.addMessageSensed(level, self, "The %s unequips the %s.", Name.get(self.owner), Name.get(actor))
   end
end

return Unequip
