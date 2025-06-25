local DropTarget = prism.InventoryTarget()
   :inInventory()

local QuantityParameter = prism.Target()
   :isType("number")
   :optional()
   :filter(function (level, owner, targetObject, previousTargets)
      local inventory = owner:expect(prism.components.Inventory)
      return inventory:canRemoveQuantity(previousTargets[1], targetObject)
   end)

---@class DropAction : Action
---@field name string
---@field targets Target[]
local Drop = prism.Action:extend("DropAction")
Drop.name = "drop"
Drop.targets = { DropTarget, QuantityParameter }
Drop.requiredComponents = {
   prism.components.Controller,
   prism.components.Inventory,
}

--- @param actor Actor
function Drop:perform(level, actor, quantity)
   local item = actor:expect(prism.components.Item)
   local inventory = self.owner:expect(prism.components.Inventory)

   local actor = inventory:removeQuantity(actor, quantity or item.stackCount or 1)
   actor:give(prism.components.Position(self.owner:getPosition()))
   level:addActor(actor)
end

return Drop