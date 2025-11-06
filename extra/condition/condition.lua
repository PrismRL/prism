--- @class ConditionOptions
--- @field modifiers ConditionModifier[]

--- Represents any kind of condition or status effect on an entity.
--- The burn from a fireball, bonuses from equipment, or passive abilities are all example uses.
--- Conditions are made up of modifiers, for grouping purposes. Extend this and :lua:class:`ConditionModifier` into your
--- own game-specific status effects.
--- @class Condition : Object
--- @field modifiers ConditionModifier[]
--- @field singleton boolean
--- @field modifierMap table<ConditionModifier, ConditionModifier[]>
--- @overload fun(...: ConditionModifier): Condition
local Condition = prism.Object:extend "Condition"
Condition.singleton = false

--- @param ... ConditionModifier
function Condition:__new(...)
   self.modifiers = { ... }
   self.modifierMap = {}

   for _, modifier in ipairs(self.modifiers) do
      local meta = getmetatable(modifier)
      if not self.modifierMap[meta] then self.modifierMap[meta] = {} end

      table.insert(self.modifierMap[meta], modifier)
   end
end

--- Returns all modifiers.
--- @generic T
--- @param prototype T
--- @return T[]
function Condition:getModifiers(prototype)
   return self.modifierMap[prototype] or {}
end

return Condition
