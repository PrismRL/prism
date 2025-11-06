--- @alias ConditionHandle integer

--- A container for :lua:class:`Condition` objects.
--- @class ConditionHolder : Component
--- @field conditions SparseArray The list of conditions.
--- @field modifierMap table<ConditionModifier, ConditionModifier[]>
--- @overload fun(): ConditionHolder
local ConditionHolder = prism.Component:extend "ConditionHolder"

function ConditionHolder:__new()
   self.conditions = prism.SparseArray()
   self.modifierMap = {}
end

--- Adds a condition and its modifiers. Will remove other conditions of the same type if marked as a singleton.
--- @param condition Condition
--- @return ConditionHandle handle
function ConditionHolder:add(condition)
   -- remove existing instances of the same subclass if set to singleton
   if condition.singleton then
      self:removeIf(function(other)
         if getmetatable(condition) == prism.condition.Condition then
            prism.logger.warn(
               "Status effect set to singleton, but not subclassed! This will remove all anonymous instances!"
            )
         end
         return getmetatable(condition):is(other)
      end)
   end

   local handle = self.conditions:add(condition)

   for _, modifier in ipairs(condition.modifiers) do
      local meta = getmetatable(modifier)

      if not self.modifierMap[meta] then self.modifierMap[meta] = {} end

      table.insert(self.modifierMap[meta], modifier)
   end

   return handle
end

--- Removes a condition using its handle.
--- @param handle ConditionHandle
function ConditionHolder:remove(handle)
   local instance = self.conditions:get(handle)
   --- @cast instance Condition

   -- Remove modifiers from global map/set
   for _, modifier in ipairs(instance.modifiers) do
      local meta = getmetatable(modifier)
      local list = self.modifierMap[meta]

      if list then
         for i = #list, 1, -1 do
            if list[i] == modifier then
               table.remove(list, i)
               break
            end
         end
         if #list == 0 then self.modifierMap[meta] = nil end
      end
   end

   self.conditions:remove(handle)
end

--- Removes conditions based on a filter.
--- @param filter fun(condition: Condition): boolean Any conditions that return true will be removed.
--- @return ConditionHolder self
function ConditionHolder:removeIf(filter)
   local toRemove = {}
   for handle, condition in self:pairs() do
      if filter(condition) then table.insert(toRemove, handle) end
   end

   for _, handle in ipairs(toRemove) do
      self:remove(handle)
   end

   return self
end

--- Runs a function on each condition.
--- @param func fun(condition: Condition) A function to apply to each condition.
--- @return ConditionHolder self
function ConditionHolder:each(func)
   for _, condition in self:pairs() do
      func(condition)
   end
   return self
end

--- Returns a list of modifiers of a given type.
--- @generic T
--- @param prototype T
--- @return T[]
function ConditionHolder:getModifiers(prototype)
   return self.modifierMap[prototype] or {}
end

--- Returns a condition given a handle.
--- @param handle ConditionHandle
--- @return Condition?
function ConditionHolder:get(handle)
   return self.conditions:get(handle)
end

local ignore = { owner = true }
function ConditionHolder:clone()
   return self:deepcopy(ignore)
end

local dummy = {}

--- Helper method to retrieve an actor's modifier of a given type.
--- @generic T
--- @param actor Entity
--- @param prototype T
--- @return T[] -- A list of modifiers. Treat this as immutable.
function ConditionHolder.getActorModifiers(actor, prototype)
   local conditions = actor:get(prism.components.ConditionHolder)
   if not conditions then return dummy end

   local modifiers = conditions:getModifiers(prototype)
   return modifiers
end

--- Iterator on each condition.
--- @return fun():(ConditionHandle, Condition)
function ConditionHolder:pairs()
   return self.conditions:pairs()
end

return ConditionHolder
