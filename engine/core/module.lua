prism.registerRegistry("components", prism.Component)
prism.registerRegistry("relations", prism.Relation)
prism.registerRegistry("targets", prism.Target, true)
prism.registerRegistry("cells", prism.Cell, true)
prism.registerRegistry("actions", prism.Action)
prism.registerRegistry("actors", prism.Actor, true)
prism.registerRegistry("messages", prism.Message)
prism.registerRegistry("decisions", prism.Decision)
prism.registerRegistry("systems", prism.System)

--- @param component string|Component
--- @param fields table<string, string>
function prism.registerComponent(component, fields, skipDefinitions)
   if type(component) == "string" then
      component = prism.Component:extend(component)
      if fields then
         function component:__new(options)
            for k, _ in pairs(fields) do
               self[k] = options[k]
            end
         end
      end
   end
   --- @cast component Component

   local name = component.className

   assert(
      prism.components[name] == nil,
      string.format("A component with name %s is already registered!", name)
   )

   prism.components[name] = component

   if skipDefinitions then return end

   local class = "--- @class " .. component.className .. " : Component"
   local constructor = "--- @overload fun("
   if fields then
      local options = component.className .. "Options"
      prism.writeDefinitions("--- @class " .. options)
      constructor = constructor .. "options: " .. options
      for field, type in pairs(fields) do
         prism.writeDefinitions("--- @field " .. field .. " " .. type)
      end
      prism.writeDefinitions(class .. ", " .. options)
   end

   prism.writeDefinitions(
      constructor .. "): " .. component.className,
      "local " .. component.className .. " = nil",
      "prism." .. "components" .. "." .. name .. " = " .. component.className
   )
end
