local PickupTarget = prism
   .InventoryTarget()
   :outsideInventory()
   :with(prism.components.Item)
   :range(0)
   :filter(function(level, owner, target)
      --- @cast owner Actor
      local inventory = owner:expect(prism.components.Inventory)
      return inventory:canAddItem(target)
   end)

---@class Pickup : Action
local Pickup = prism.Action:extend("Pickup")
Pickup.targets = { PickupTarget }
Pickup.requiredComponents = {
   prism.components.Controller,
   prism.components.Inventory,
}

--- @param item Actor
function Pickup:perform(level, item)
   local inventory = self.owner:expect(prism.components.Inventory)
   inventory:addItem(item)
   level:removeActor(item)
   item:remove(prism.components.Position)
end

return Pickup
