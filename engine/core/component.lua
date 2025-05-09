--- The `Component` class represents a component that can be attached to actors.
--- Components are used to add functionality to actors. For instance, the `Moveable` component
--- allows an actor to move around the map. Components are essentially data storage that can
--- also grant actions.
--- @class Component : Object
--- @field requirements string[] A list of components the actor must first have, before this can be applied. References the component class name.
--- @field owner Entity The Actor this component is composing. This is set by Actor when a component is added or removed.
--- @overload fun(): Component
local Component = prism.Object:extend("Component")
Component.requirements = {}

--- Checks whether an actor has the required components to attach this component.
--- @param entity Entity The actor to check the requirements against.
--- @return boolean meetsRequirements the actor meets all requirements, false otherwise.
function Component:checkRequirements(entity)
   local foundreqs = {}

   for _, component in pairs(entity.components) do
      for _, requirement in pairs(self.requirements) do
         if component.className == requirement.className then table.insert(foundreqs, component) end
      end
   end

   if #foundreqs == #self.requirements then return true end

   return false
end

return Component
