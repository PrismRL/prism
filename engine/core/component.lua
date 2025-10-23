--- The `Component` class represents a component that can be attached to actors or cells.
--- Components are used to add functionality to actors. For instance, the `Moveable` component
--- allows an actor to move around the map. Components are essentially data storage that can
--- also grant actions.
--- @class Component : Object
--- @field requirements Component[] (static) A list of components (prototypes) the entity must have before this one can be applied.
--- @field owner Entity The entity this component is composing. This is set by Entity when a component is added or removed.
--- @overload fun(): Component
local Component = prism.Object:extend("Component")
Component.requirements = {}

--- Returns a list of components (prototypes) the entity must have before this one can be applied.
--- Override this to provide requirements, and it will get called to populate the list.
--- @return Component ...
function Component:getRequirements() end

--- Checks whether an actor has the required components to attach this component.
--- @param entity Entity The actor to check the requirements against.
--- @return boolean meetsRequirements True if the entity meets all requirements, false otherwise.
--- @return Component? -- The first component found missing from the entity if requirements aren't met.
function Component:checkRequirements(entity)
   for _, component in ipairs(self.requirements) do
      if not entity:has(component) then return false, component end
   end

   return true
end

function Component:getBase()
   local proto = self:isInstance() and getmetatable(self) or self
   while proto and proto ~= prism.Component do
      proto = getmetatable(proto)
   end
   
   return proto
end

-- Fields that should not be cloned (transient/runtime-only)
local TRANSIENT_FIELDS = {
   owner = true,
}

--- Creates a shallow copy of this component. If your component needs a deep
--- copy or other considerations make sure to override this method on that component!
--- @return Component clone A new component instance with copied fields.
function Component:clone()
   local copy = {}

   for k, v in pairs(self) do
      if not TRANSIENT_FIELDS[k] then
         copy[k] = v
      end
   end

   return setmetatable(copy, getmetatable(self))
end

return Component
