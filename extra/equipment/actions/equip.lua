local Log = prism.components.Log
local Name = prism.components.Name

local EquipTarget = 
   prism.InventoryTarget()
   :inInventory()
   :with(prism.components.Equipment)
   :filter(function(level, owner, target)
      local equipper = owner:expect(prism.components.Equipper)
      return equipper:canEquip(target:expect(prism.components.Equipment))
   end)

--- @class Equip : Action
local Equip = prism.Action:extend "Equip"
Equip.targets = { EquipTarget }
Equip.requiredComponents = {
   prism.components.Equipper,
   prism.components.Inventory
}

--- @param level Level
function Equip:perform(level, actor)
   local equipper = self.owner:expect(prism.components.Equipper)
   local equipment = actor:expect(prism.components.Equipment)

   local function fillSlot(slot)
      for i, sl in ipairs(equipper.slots) do
         if slot == sl and not equipper.equipped[i] then
            equipper.equipped[i] = actor
            return
         end
      end
   end

   for slot, count in pairs(equipment.requiredSlots) do
      for i = 1, count do
         fillSlot(slot)
      end
   end

   local inv = self.owner:expect(prism.components.Inventory)
   inv:removeItem(actor)

   local status = self.owner:get(prism.components.StatusEffects)
   if status and equipment.status then
      equipper.statusMap[actor] = status:add(equipment.status)
   end

   if Log then
      Log.addMessage(self.owner, "You equip the %s.", Name.get(actor))
      Log.addMessageSensed(level, self, "The %s equips the %s.", Name.get(self.owner), Name.get(actor))
   end
end

return Equip