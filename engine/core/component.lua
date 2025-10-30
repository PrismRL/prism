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

--- Creates a shallow copy of this component. If your component needs a deep
--- copy or other considerations make sure to override this method on that component!
--- @return Component clone A new component instance with copied fields.
function Component:clone()
   local copy = {}

   for k, v in pairs(self) do
      if not self._serializationBlacklist[k] then
         copy[k] = v
      end
   end

   return getmetatable(self):adopt(copy)
end

--- Compute a deep diff from this component to another of the same class.
--- Ignores only transient/runtime-only fields.
--- Returns a compact patch with fields to set or unset to make `self` match `other`.
--- @param other Component
--- @return { set?: table<string, any>, unset?: table<string, boolean> }|nil diff
function Component:diff(other)
   local function deepEqual(a, b, seen)
      if a == b then return true end
      if type(a) ~= type(b) then return false end
      if type(a) ~= "table" then return a == b end

      seen = seen or {}
      if seen[a] and seen[a] == b then return true end
      seen[a] = b

      for k, v in pairs(a) do
         if not deepEqual(v, b[k], seen) then return false end
      end
      for k, _ in pairs(b) do
         if a[k] == nil then return false end
      end

      return true
   end

   local function isIgnoredKey(k, v)
      if self._serializationBlacklist[k] then return true end
      local t = type(v)
      return t == "function" or t == "userdata"
   end

   local set, unset = {}, {}

   -- Fields present on self: detect removals/changes
   for k, v in pairs(self) do
      if not isIgnoredKey(k, v) then
         local ov = other[k]
         if ov == nil then
            unset[k] = true
         elseif not deepEqual(v, ov) then
            set[k] = ov
         end
      end
   end

   -- Fields present only on other: detect additions
   for k, ov in pairs(other) do
      if not isIgnoredKey(k, ov) and self[k] == nil then
         set[k] = ov
      end
   end

   -- Nil out empty subtables; return nil if no diffs
   if next(set) == nil then set = nil end
   if next(unset) == nil then unset = nil end
   if not (set or unset) then
      return nil
   end

   return { set = set, unset = unset }
end

--- Apply a diff (as produced by :diff) to this component.
--- Safely ignores transient/runtime-only fields and unknown shapes.
--- Overwrites whole-table fields when setting (since :diff is shallow).
--- @param patch { set?: table<string, any>, unset?: table<string, boolean> }
--- @return Component self
function Component:applyDiff(patch)
   assert(type(patch) == "table", "Component:applyDiff expected a table patch")

   local function isIgnoredKey(k)
      return self._serializationBlacklist[k] == true
   end

   local function deepCopy(val, seen)
      local t = type(val)
      if t ~= "table" then return val end

      seen = seen or {}
      if seen[val] then return seen[val] end

      -- Prefer object-provided clone when available
      if type(val.clone) == "function" then
         local ok, cloned = pcall(function() return val:clone() end)
         if ok and cloned ~= nil then return cloned end
      end

      local out = {}
      seen[val] = out
      for k, v in pairs(val) do
         out[deepCopy(k, seen)] = deepCopy(v, seen)
      end
      local mt = getmetatable(val)
      if mt then setmetatable(out, mt) end
      return out
   end

   -- Unset fields (skip transient)
   if patch.unset then
      for k, _ in pairs(patch.unset) do
         if not isIgnoredKey(k) then
            rawset(self, k, nil)
         end
      end
   end

   -- Set fields (skip transient)
   if patch.set then
      for k, v in pairs(patch.set) do
         if not isIgnoredKey(k) then
            if type(v) == "table" then
               rawset(self, k, deepCopy(v))
            else
               rawset(self, k, v)
            end
         end
      end
   end

   return self
end


return Component
