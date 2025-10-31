--- @class Equipper : Component
--- Handles equipping and tracking of Equipment components on an Actor.
--- Maintains available slots, equipped items, and their associated status effects.
--- @field slots string[] A list of slot names this actor possesses (e.g. { "head", "hand", "hand", "body" }).
--- @field equipped Actor[] The list of currently equipped actors representing equipment items.
--- @field statusMap table<Actor, StatusEffectsHandle> Maps equipped actors to their applied status handles for easy removal.
--- @overload fun(slots: string[]): Equipper
local Equipper = prism.Component:extend "Equipper"

--- @param slots string[] List of available slot names.
function Equipper:__new(slots)
   self.slots = slots
   self.equipped = {}
   self.statusMap = {}
end

--- Checks if the given Equipment can be equipped with current available slots.
--- @param equipment Equipment The equipment to test.
--- @return boolean True if the equipment can be equipped, false otherwise.
function Equipper:canEquip(equipment)
   local counts = {}

   for i, slot in ipairs(self.slots) do
      if not self.equipped[i] then
         counts[slot] = (counts[slot] or 0) + 1
      end
   end

   for slot, count in pairs(equipment.requiredSlots) do
      if counts[slot] and counts[slot] < count then
         return false
      end
   end

   return true
end

--- Checks whether the given actor is currently equipped.
--- @param actor Actor The actor to check.
--- @return boolean True if equipped, false otherwise.
function Equipper:isEquipped(actor)
   for _, a in pairs(self.equipped) do
      if a == actor then
         return true
      end
   end
   return false
end

return Equipper
