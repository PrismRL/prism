--- @class Equipment : Component
--- @field requiredSlots table<string, integer>
--- @field status StatusEffectsInstance 
--- @overload fun(requiredSlots: string[]|string, status: GameStatusInstance?): Equipment
local Equipment = prism.Component:extend "Equipment"

function Equipment:__new(requiredSlots, status)
   if type(requiredSlots) == "string" then requiredSlots = {requiredSlots} end
   self.requiredSlots = {}

   for _, slot in pairs(requiredSlots) do
      self.requiredSlots[slot] = (self.requiredSlots[slot] or 0) + 1
   end

   self.status = status
end

return Equipment