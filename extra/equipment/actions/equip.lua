local Log = prism.components.Log
local Name = prism.components.Name

-- Filters inventory items that have an Equipment component
-- and can be equipped by the acting entity.
local EquipTarget =
   prism.InventoryTarget()
   :inInventory()
   :with(prism.components.Equipment)
   :filter(function(level, owner, target)
      local equipper = owner:expect(prism.components.Equipper)
      return equipper:canEquip(target:expect(prism.components.Equipment))
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
   prism.components.Inventory
}

--- Performs the equip action on the target item.
--- Assigns the item to free equipment slots, removes it from inventory,
--- and applies status effects.
--- @param level Level The current level or world state.
--- @param actor Actor The target actor being equipped.
function Equip:perform(level, actor)
   local equipper = self.owner:expect(prism.components.Equipper)
   local equipment = actor:expect(prism.components.Equipment)

   --- Helper to fill the first free slot matching the given slot name.
   --- @param slot string
   local function fillSlot(slot)
      for i, sl in ipairs(equipper.slots) do
         if slot == sl and not equipper.equipped[i] then
            equipper.equipped[i] = actor
            return
         end
      end
   end

   -- Fill all required slots for this equipment.
   for slot, count in pairs(equipment.requiredSlots) do
      for i = 1, count do
         fillSlot(slot)
      end
   end

   -- Remove the equipped item from the inventory.
   local inv = self.owner:expect(prism.components.Inventory)
   inv:removeItem(actor)

   -- Apply status effects from equipment, if applicable.
   local status = self.owner:get(prism.components.StatusEffects)
   if status and equipment.status then
      equipper.statusMap[actor] = status:add(equipment.status)
   end

   -- Log messages for player and sensed observers.
   if Log then
      Log.addMessage(self.owner, "You equip the %s.", Name.get(actor))
      Log.addMessageSensed(level, self, "The %s equips the %s.", Name.get(self.owner), Name.get(actor))
   end
end

return Equip
