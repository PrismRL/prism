local sf = string.format
local Name = prism.components.Name

local PickupTarget = prism
   .Target(prism.components.Item)
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

   if prism.components.Log then
      Log = prism.components.Log
      Log.addMessage(self.owner, sf("You pick up the %s", Name.get(item)))
      Log.addMessageSensed(
         level,
         self,
         sf("%s picks up the %s", Name.get(self.owner), Name.get(item))
      )
   end
end

return Pickup
