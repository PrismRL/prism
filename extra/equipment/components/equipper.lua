--- @class EquipmentSlot
--- @field name string
--- @field label string
--- @field category string

--- Handles equipping and tracking of Equipment components on an Actor.
--- Maintains available slots, equipped items, and their conditions.
--- @class Equipper : Component
--- @field slots EquipmentSlot[]
--- @field equipped table<string, Actor?> The list of currently equipped actors representing equipment items.
--- @field statusMap table<Actor, ConditionHandle> Maps equipped actors to their applied status handles for easy removal.
--- @overload fun(slots: ({name: string, label?: string, category: string}|string)[]): Equipper
local Equipper = prism.Component:extend "Equipper"

--- @param slots ({name: string, label?: string, category: string}|string)[] List of available slot names.
function Equipper:__new(slots)
   self.slots = slots
   for i, slot in ipairs(self.slots) do
      if type(slot) == "string" then
         slots[i] = { name = slot, label = slot, category = slot }
      else
         slots[i].label = slot.label or slot.name
      end
   end
   self.equipped = {}
   self.statusMap = {}
end

--- Checks if the given equipment can be equipped with current available slots.
--- @param equipment Equipment|Actor The equipment to test.
--- @return boolean -- True if the equipment can be equipped, false otherwise.
function Equipper:canEquip(equipment)
   if prism.Actor:is(equipment) then
      equipment = equipment:get(prism.components.Equipment)
      if not equipment then return false end
   end
   --- @cast equipment Equipment
   local counts = {}

   for i, slot in ipairs(self.slots) do
      if not self.equipped[slot.name] then
         counts[slot.category] = (counts[slot.category] or 0) + 1
      end
   end

   for category, count in pairs(equipment.requiredCategories) do
      if counts[category] and counts[category] < count then return false end
   end

   return true
end

--- Gets the actor equipped in the slot, or nil if it's empty.
--- @param slot string
--- @return Actor?
function Equipper:get(slot)
   return self.equipped[slot]
end

--- Checks whether the given actor is currently equipped.
--- @param actor Actor The equipment actor to check.
--- @return boolean True if equipped, false otherwise.
function Equipper:isEquipped(actor)
   for _, equipped in pairs(self.equipped) do
      if equipped == actor then return true end
   end
   return false
end

return Equipper
