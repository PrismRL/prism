--- @class Equipment : Component
--- Represents an equippable item that occupies one or more equipment slots
--- and may apply status effects while equipped.
--- @field requiredSlots table<string, integer> Table of required slot names and their quantities (e.g. { hand = 2 } for a two-handed weapon)
--- @field status StatusEffectsInstance|nil Optional status effect instance applied when equipped
--- @overload fun(requiredSlots: string[]|string, status: GameStatusInstance?): Equipment
local Equipment = prism.Component:extend "Equipment"

--- Constructor for the Equipment component.
--- @param requiredSlots string[]|string The slot or slots this equipment occupies.
--- @param status GameStatusInstance? Optional status effect instance applied while equipped.
function Equipment:__new(requiredSlots, status)
   if type(requiredSlots) == "string" then requiredSlots = { requiredSlots } end
   self.requiredSlots = {}

   for _, slot in pairs(requiredSlots) do
      self.requiredSlots[slot] = (self.requiredSlots[slot] or 0) + 1
   end

   self.status = status
end

return Equipment