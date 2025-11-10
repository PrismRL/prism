--- @class InventorySystem : System
local InventorySystem = prism.System:extend "InventorySystem"

function InventorySystem:onActorAdded(level, actor)
   for _, component in ipairs(actor.components) do
      if component.initialize then component:initialize(actor) end
   end
end

return InventorySystem
