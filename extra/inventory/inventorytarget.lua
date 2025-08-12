--- InventoryTarget is an extension of the Target class injected
--- into the prism namespace by the Inventory module. This overrides
--- the standard range builder function, and treats items in inventory
--- as always being in range.
--- @class InventoryTarget : Target
--- @overload fun(...: Component): InventoryTarget
local InventoryTarget = prism.Target:extend "InventoryTarget"

function InventoryTarget:range(range)
   self.range = range

   --- @param owner Actor
   --- @param target any
   self.validators["range"] = function(level, owner, target)
      local inventory = owner:get(prism.components.Inventory)
      if inventory and inventory:hasItem(target) then return true end

      if not owner:getPosition() then return false end

      if prism.Actor:is(target) then
         if not target:getPosition() then return false end
         --- @cast target Actor
         return owner:getRange(target) <= self.range
      end

      if prism.Vector2:is(target) then
         --- @cast target Vector2
         return owner:getRangeVec(target) <= self.range
      end

      return false
   end

   return self
end

--- Checks if the target is in the owner's inventory.
function InventoryTarget:inInventory()
   self.validators["inventory"] = function(level, owner, target)
      local inventory = owner:get(prism.components.Inventory)
      if inventory and inventory:hasItem(target) then return true end

      return false
   end

   return self
end

--- Checks that the target is not in the owner's inventory.
function InventoryTarget:outsideInventory()
   self.validators["outsideinventory"] = function(level, owner, target)
      local inventory = owner:get(prism.components.Inventory)
      if inventory and inventory:hasItem(target) then return false end

      return true
   end

   return self
end

function InventoryTarget:validate(level, owner, targetObject, previousTargets)
   if not targetObject and not self._optional then return false end
   if not targetObject and self._optional then return true end

   local inventory = owner:get(prism.components.Inventory)
   if
      self.inLevel
      and prism.Actor:is(targetObject)
      and not level:hasActor(targetObject)
      and not (inventory and inventory:hasItem(targetObject))
   then
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

return InventoryTarget

