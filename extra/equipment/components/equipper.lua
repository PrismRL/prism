--- @class Equipper : Component
--- @field slots string[]
--- @field equipped Actor[]
--- @field statusMap table<Actor, StatusEffectsHandle>
--- @field private capacity table<string, integer>
--- @overload fun(slots: string[]): Equipper
local Equipper = prism.Component:extend "Equipper"

--- @param slots string[]
function Equipper:__new(slots)
   self.slots = slots
   self.equipped = {}
   self.statusMap = {}
end

--- @param equipment Equipment
--- @return boolean
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

--- @param actor Actor
--- @return boolean
function Equipper:isEquipped(actor)
   for _, a in pairs(self.equipped) do
      if a == actor then
         return true
      end
   end
   return false
end

return Equipper