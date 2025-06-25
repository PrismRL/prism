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
      if inventory and inventory:hasItem(target) then
         return true
      end

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

function InventoryTarget:inInventory()
   self.validators["inventory"] = function (level, owner, target)
      local inventory = owner:get(prism.components.Inventory)
      if inventory and inventory:hasItem(target) then
         return true
      end

      return false
   end

   return self
end

function InventoryTarget:outsideInventory()
   self.validators["outsideinventory"] = function (level, owner, target)
      local inventory = owner:get(prism.components.Inventory)
      if inventory and inventory:hasItem(target) then
         return false
      end

      return true
   end

   return self
end

function InventoryTarget:validate(level, owner, targetObject, previousTargets)
   if not targetObject and not self.opt then return false end
   if not targetObject and self.opt then return true end

   local inventory = owner:get(prism.components.Inventory)
   if 
      self.inLevel and prism.Actor:is(targetObject) and
      not level:hasActor(targetObject) and
      not (inventory and inventory:hasItem(targetObject))
   then
      return false
   end

   for _, validator in pairs(self.validators) do
      if not validator(level, owner, targetObject, previousTargets) then return false end
   end

   return true
end

return InventoryTarget