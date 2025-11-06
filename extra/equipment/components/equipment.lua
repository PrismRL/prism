--- Represents an equippable item that occupies one or more equipment slots
--- and may apply a condition while equipped.
--- @class Equipment : Component
--- @field requiredCategories table<string, integer> Table of required slot categories and their quantities (e.g. { hand = 2 } for a two-handed weapon)
--- @field condition Condition|nil Optional condition applied when equipped
--- @overload fun(requiredSlots: string[]|string, status: Condition?): Equipment
local Equipment = prism.Component:extend "Equipment"

--- Constructor for the Equipment component.
--- @param requiredCategories string[]|string The slot or slots this equipment occupies.
--- @param status Condition? Optional condition applied while equipped.
function Equipment:__new(requiredCategories, status)
   if type(requiredCategories) == "string" then requiredCategories = { requiredCategories } end
   self.requiredCategories = {}

   for _, slot in pairs(requiredCategories) do
      self.requiredCategories[slot] = (self.requiredCategories[slot] or 0) + 1
   end

   self.condition = status
end

return Equipment
