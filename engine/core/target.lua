--- @alias TargetFactory fun(...): Target

--- Targets represent what actions are able to act on. The builder pattern is used to
--- narrow down various requirements for actions.
--- @class Target : Object
--- @field hint any
--- @field _optional boolean
--- @field inLevel boolean
--- @field type? Object An object prototype for the targeted to adhere to.
--- @field rangeValue integer
--- @field validators table<string, (fun(level: Level, owner: Actor, targetObject: any, previousTargets: any[]): boolean)>
--- @field requiredComponents table<Component, boolean>
--- @field excludedComponents table<Component, boolean>
--- @overload fun(...: Component): Target
local Target = prism.Object:extend("Target")

--- Creates a new Target and accepts components and sends them to with().
function Target:__new(...)
   self.validators = {}
   self.requiredComponents = {}
   self.excludedComponents = {}
   self.inLevel = true
   self.hint = nil -- A hint that can be set to let the UI know how to handle the target.
   self._optional = false

   self:with(...)
end

--- @param level Level
--- @param owner Actor The actor performing the action.
--- @param targetObject any
--- @param previousTargets any[]? A list of the previous target objects.
function Target:validate(level, owner, targetObject, previousTargets)
   if not targetObject and not self._optional then return false end
   if not targetObject and self._optional then return true end

   if self.inLevel and prism.Actor:is(targetObject) and not level:hasActor(targetObject) then
      return false
   end

   for k, validator in pairs(self.validators) do
      if type(k) == "string" then
         if not validator(level, owner, targetObject, previousTargets) then return false end
      end
   end

   for _, validator in ipairs(self.validators) do
      if not validator(level, owner, targetObject, previousTargets) then return false end
   end

   return true
end

--- Adds a custom filter to the target, for any cases not covered by the built-in methods.
--- Examples might include targetting enemies with low health, or carrying a certain item.
--- The order of filter application is not guaranteed!
--- @param filter fun(level: Level, owner: Actor, targetObject: any, previousTargets: any[]): boolean
function Target:filter(filter)
   table.insert(self.validators, filter)
   return self
end

--- Adds a list of components that the target object must have.
--- @param ... Component
function Target:with(...)
   for _, comp in pairs({ ... }) do
      self.requiredComponents[comp] = true
   end

   --- @param target Entity
   self.validators["with"] = function(level, owner, target)
      if not next(self.requiredComponents) then return true end

      if not prism.Entity:is(target) then return false end

      for comp, _ in pairs(self.requiredComponents) do
         if not target:has(comp) then return false end
      end

      return true
   end

   return self
end

--- Adds a list of components that the target object must not have.
--- @param ... Component
function Target:without(...)
   for _, comp in pairs({ ... }) do
      self.excludedComponents[comp] = true
   end

   --- @param target Entity
   self.validators["with"] = function(level, owner, target)
      if not next(self.excludedComponents) then return true end

      if not prism.Entity:is(target) then return false end

      for comp, _ in pairs(self.excludedComponents) do
         if target:has(comp) then return false end
      end

      return true
   end

   return self
end

--- Disables checking if the target is inside the level. Useful if the target lies outside the level,
--- such as in an inventory.
function Target:outsideLevel()
   self.inLevel = false
   return self
end

--- Checks if the target is within the specified range, and if it's an Actor or Vector2.
--- @param range integer The maximum range to the target.
--- @param distanceType? DistanceType Optional distance type.
function Target:range(range, distanceType)
   self.rangeValue = range

   --- @param owner Actor
   --- @param target any
   self.validators["range"] = function(level, owner, target)
      if not owner:getPosition() then return false end

      if prism.Actor:is(target) then
         if not target:getPosition() then return false end
         --- @cast target Actor
         return owner:getRange(target, distanceType) <= self.rangeValue
      end

      if prism.Vector2:is(target) then
         --- @cast target Vector2
         return owner:getRangeVec(target, distanceType) <= self.rangeValue
      end

      return false
   end

   return self
end

--- Checks if the target is the same type as the given prototype.
--- @param type Object The prototype to check.
function Target:isPrototype(type)
   assert(prism.Object:is(type), "Prototype must be a prism.Object!")

   self.type = type

   self.validators["type"] = function(level, owner, target)
      return self.type:is(target)
   end

   return self
end

--- Shorthand for isPrototype(prism.Actor).
function Target:isActor()
   return self:isPrototype(prism.Actor)
end

--- Shorthand for isPrototype(prism.Cell).
function Target:isCell()
   return self:isPrototype(prism.Cell)
end

--- Shorthand for isPrototype(prism.Vector2).
function Target:isVector2()
   return self:isPrototype(prism.Vector2)
end

--- Checks if the target is specific Lua type.
--- @param luaType type
function Target:isType(luaType)
   self.validators["luatype"] = function(_, _, target)
      return type(target) == luaType
   end

   return self
end

--- Checks if the target is an Actor or Vector2 and if the owner can sense that target.
function Target:sensed()
   self.validators["sensed"] = function(level, owner, target)
      local senses = owner:get(prism.components.Senses)

      if not senses then return false end

      if prism.Actor:is(target) then
         --- @cast target Actor
         return owner:hasRelation(prism.relations.SensesRelation, target)
      end

      if prism.Vector2:is(target) then
         --- @cast target Vector2
         return senses.cells:get(target.x, target.y) ~= nil
      end

      -- TODO: add cell handling by giving cells a position

      return false
   end

   return self
end

-- TODO: UNTESTED
--- Walks a bresenham line between the owner and the target and checks if each tile
--- is passable by the given mask. Fails if it can't reach the target.
--- @param mask Bitmask
function Target:los(mask)
   self.validators["los"] = function(level, owner, target)
      if not prism.Actor:is(target) and not prism.Vector2:is(target) then return false end
      if not owner:getPosition() then return false end

      if prism.Actor:is(target) and not target:getPosition() then return false end

      --- @type Vector2
      local targetPosition = target
      if prism.Actor:is(target) then
         --- @cast target Actor
         targetPosition = target:expectPosition()
      end

      local ownerX, ownerY = owner:expectPosition():decompose()
      local path = prism.Bresenham(ownerX, ownerY, targetPosition:decompose())

      for _, point in ipairs(path) do
         if point.x ~= ownerX and point.y ~= ownerY then
            if not level:getCellPassable(point.x, point.y, mask) then return false end
         end
      end

      return true
   end

   return self
end

--- Ensures the target is not the same as any previous target.
function Target:unique()
   self.validators["unique"] = function(_, _, target, previousTargets)
      if not previousTargets then return true end
      for _, prev in ipairs(previousTargets) do
         if prev == target then return false end
      end
      return true
   end

   return self
end

--- Requires that the target is related to the action owner via a specific relation type.
--- @param relationType Relation
function Target:related(relationType)
   assert(relationType, "Missing relation type")

   --- @param owner Actor
   self.validators["related"] = function(_, owner, target)
      if not prism.Entity:is(target) then return false end
      return owner:hasRelation(relationType, target)
   end

   return self
end

--- Excludes the owner from being a valid target.
function Target:excludeOwner()
   self.validators["excludeOwner"] = function(_, owner, target)
      return owner ~= target
   end

   return self
end

--- Sets a string hint for the target, useful for UI handling.
--- @param hint any
function Target:setHint(hint)
   self.hint = hint
   return self
end

--- Makes the target optional, matching with nil as well as whatever other validators
--- are specified.
function Target:optional()
   self._optional = true
   return self
end

return Target
