local sf = string.format
local Name = prism.components.Name

local DropTarget = prism.targets.InventoryTarget()

local QuantityParameter = prism
   .Target()
   :isType("number")
   :optional()
   :filter(function(level, owner, targetObject, previousTargets)
      local inventory = owner:expect(prism.components.Inventory)
      return inventory:canRemoveQuantity(previousTargets[1], targetObject)
   end)

---@class Drop : Action
local Drop = prism.Action:extend("Drop")
Drop.targets = { DropTarget, QuantityParameter }
Drop.requiredComponents = {
   prism.components.Controller,
   prism.components.Inventory,
}

--- @param actor Actor
function Drop:perform(level, actor, quantity)
   local item = actor:expect(prism.components.Item)
   local inventory = self.owner:expect(prism.components.Inventory)

   local removedActor = inventory:removeQuantity(actor, quantity or item.stackCount or 1)
   removedActor:give(prism.components.Position(self.owner:getPosition()))
   level:addActor(removedActor)

   if prism.components.Log then
      Log = prism.components.Log
      Log.addMessage(self.owner, sf("You drop the %s", Name.get(actor)))
      Log.addMessageSensed(
         level,
         self,
         sf("%s drops the %s", Name.get(self.owner), Name.get(actor))
      )
   end
end

return Drop
