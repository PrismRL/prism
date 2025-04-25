prism._OBJECTREGISTRY = {}
prism._ISCLASS = {}

--- A simple class system for Lua. This is the base class for all other classes in PRISM.
---@class Object
---@field className string A unique name for this class. By convention this should match the annotation name you use.
---@field serializationBlacklist table<string, boolean>
local Object = {}
Object.className = "Object"
Object.stripName = true

Object._serializationBlacklist = {
   className = true,
   stripName = true,
}

--- Creates a new class and sets its metatable to the extended class.
--- @generic T
--- @param className string name for the class
--- @param ignoreclassName? boolean if true, skips the uniqueness check in prism's registry
--- @return T prototype The new class prototype extended from this one.
function Object:extend(className, ignoreclassName)
   assert(className, "You must supply a class name when extending Objects!")
   local o = {}
   setmetatable(o, self)
   self.__index = self
   self.__call = self.__call or Object.__call
   o.className = className

   --print(className, not ignoreclassName, not prism._OBJECTREGISTRY[className])
   assert(ignoreclassName or not prism._OBJECTREGISTRY[className], className .. " is already in use by another prototype!")

   -- TODO: Remove ignorclassName hack.
   if not ignoreclassName then
      prism._OBJECTREGISTRY[className] = o
      prism._ISCLASS[o] = className
   end

   return o
end

--- Creates a new instance of the class. Calls the __new method.
--- @generic T
--- @param self T
--- @param ... any
--- @return T newInstance The new instance.
function Object:__call(...)
   local o = {}
   Object.adopt(self, o)
   o:__new(...)
   return o
end

function Object:adopt(o)
   -- we hard cast self to a table
   --- @diagnostic disable-next-line
   --- @cast self Object
   setmetatable(o, self)
   self.__index = self

   return o
end

--- The default constructor for the class. Subclasses should override this.
--- @param ... any
function Object:__new(...) end

--- Checks if o is in the inheritance chain of self.
--- @param self any
--- @param o any The class to check.
--- @return boolean is True if o is in the inheritance chain of self, false otherwise.
function Object:is(o)
   if self == o then return true end

   local parent = getmetatable(self)
   while parent do
      if parent == o then return true end

      parent = getmetatable(parent)
   end

   return false
end

--- Checks if o is the first class in the inheritance chain of self.
--- @param o table The class to check.
--- @return boolean extends True if o is the first class in the inheritance chain of self, false otherwise.
function Object:instanceOf(o)
   if getmetatable(self) == o then return true end

   return false
end

--- List of metamethods to block from mixins
local unmixed = {
   __index = true,
   __newindex = true,
   __call = true,
}

--- Mixes in methods and properties from another table, excluding blacklisted metamethods.
--- THis does not deep copy or merge tables, currently. It's a shallow mixin.
--- @param mixin table The table containing methods and properties to mix in.
--- @return self
function Object:mixin(mixin)
   for k, v in pairs(mixin) do
      if not unmixed[k] then
         self[k] = v
      end
   end

   return self
end

function Object.serialize(object)
   assert(object, "Object cannot be nil.")
   local visited = {}
   local stack = {object}
   local nextId = 1
   local objectToId = {}

   local result = {
      references = {},
      rootId = nil
   }

   -- Helper function to get or assign ID for any table
   local function getObjectId(obj)
      if not objectToId[obj] then
         objectToId[obj] = nextId
         nextId = nextId + 1
      end
      return objectToId[obj]
   end

   -- Helper function to determine if a value should be serialized
   local function shouldSerialize(obj, key, value)
      local serializable = value ~= nil and type(value) ~= "function"
      if obj.serializationBlacklist and obj.serializationBlacklist[key] then
         return false
      end

      if Object._serializationBlacklist[key] then
         return false
      end

      return serializable
   end

   -- Helper function to determine if a value is a SerializableObject
   local function isSerializableObject(value)
      return type(value) == "table" and
             getmetatable(value) and
             value.is and
             value:is(Object)
   end

   -- Helper function to serialize a single value
   local function serializeValue(v)
      if prism._ISCLASS[v] then
         return {prototype = prism._ISCLASS[v]}
      end
      if type(v) == "table" then
         return {ref = getObjectId(v)}
      else
         return v
      end
   end

   -- Assign ID to root object first
   result.rootId = getObjectId(object)

   while #stack > 0 do
      local obj = table.remove(stack)
      if not visited[obj] then
         visited[obj] = true

         local objData = {
            id = getObjectId(obj),
            entries = {},
         }

         if isSerializableObject(obj) then
            objData.className = obj.className
         else
            objData.className = "table"
         end

         -- Process all pairs uniformly
         for k, v in pairs(obj) do
            if shouldSerialize(obj, k, v) then
               table.insert(objData.entries, {
                  key = serializeValue(k),
                  value = serializeValue(v)
               })

               if type(v) == "table" and not visited[v] and not prism._ISCLASS[v] then
                  --print(obj.className, v.className)
                  table.insert(stack, v)
               end

               if type(k) == "table" and not visited[k] and not prism._ISCLASS[k] then
                  --print(obj.className, k.className)
                  table.insert(stack, k)
               end
            end
         end

         -- Ensure references is a numerically indexed array
         result.references[objData.id] = objData
      end
   end

   -- Validate IDs are sequential
   for i = 1, nextId - 1 do
      assert(result.references[i], "Missing reference for ID: " .. i)
   end

   return result
end

function Object.deserialize(data)
   assert(type(data) == "table", "Deserialization data must be a table")
   assert(data.rootId, "Deserialization data must have a rootId")
   assert(data.references, "Deserialization data must have a references table")

   local idToObject = {}

   -- Forward declare all objects first
   for id, objData in ipairs(data.references) do
      local obj
      if objData.className == "table" then
         obj = {}
      else
         local class = prism._OBJECTREGISTRY[objData.className]
         assert(class, "Could not find class " .. objData.className .. " in registry")
         obj = {} -- Initially, just create a plain table
      end
      idToObject[id] = obj
   end

   -- Helper function to resolve references
   local function resolveValue(value)
      if type(value) == "table" and value.prototype then
         return prism._OBJECTREGISTRY[value.prototype]
      end
      if type(value) == "table" and value.ref then
         local resolved = idToObject[value.ref]
         assert(resolved, "Could not resolve reference: " .. value.ref)
         return resolved
      end
      return value
   end

   -- Now populate all objects with their data
   for id, objData in pairs(data.references) do
      id = tonumber(id)
      local obj = idToObject[id]

      for _, entry in pairs(objData.entries) do
         local key = resolveValue(entry.key)
         local value = resolveValue(entry.value)
         obj[key] = value
      end
   end

   -- Apply metatables using adopt
   for id, objData in pairs(data.references) do
      id = tonumber(id)
      local obj = idToObject[id]
      if objData.className ~= "table" then
         local class = prism._OBJECTREGISTRY[objData.className]
         Object.adopt(class, obj)
      end
   end

   for id, objData in pairs(data.references) do
      id = tonumber(id)
      local obj = idToObject[id]

      if obj.onDeserialize then
         obj:onDeserialize()
      end
   end

   return idToObject[data.rootId]
end


--- Pretty-prints an object for debugging or visualization.
--- @param obj table The object to pretty-print.
--- @param indent string The current indentation level (used for recursion).
--- @param visited table A table of visited objects to prevent circular references.
function Object.prettyprint(obj, indent, visited)
   indent = indent or ""
   visited = visited or {}

   if type(obj) ~= "table" then
      return tostring(obj)
   end

   if visited[obj] then
      return "<circular reference>"
   end

   visited[obj] = true
   local result = "{\n"
   local nextIndent = indent .. "  "

   for k, v in pairs(obj) do
      local keyStr = type(k) == "string" and ('"' .. k .. '"') or "[" .. tostring(k) .. "]"
      local valueStr = Object.prettyprint(v, nextIndent, visited)
      result = result .. nextIndent .. keyStr .. " = " .. valueStr .. ",\n"
   end

   visited[obj] = nil -- Clear the visited flag for this object to allow reuse
   result = result .. indent .. "}"
   return result
end

--- @type Object
local ret = Object:__call()
return ret
