prism._OBJECTREGISTRY = {}
prism._ISCLASS = {}

--- A simple class system for Lua. This is the base class for all other classes in PRISM.
--- @class Object
--- @field protected super any The superclass of the object.
--- @field private __index any
--- @field private __call any
--- @field className string (static) A unique name for this class. By convention this should match the annotation name you use.
--- @field private _isInstance boolean
--- @field serializationBlacklist table<string, boolean>
local Object = {}
Object.className = "Object"
Object._isInstance = false
Object._serializationBlacklist = {
   className = true,
   _isInstance = true,
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
   o._isInstance = false
   o.className = className
   o.super = self

   --print(className, not ignoreclassName, not prism._OBJECTREGISTRY[className])
   assert(
      ignoreclassName or not prism._OBJECTREGISTRY[className],
      className .. " is already in use by another prototype!"
   )

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

--- Adopts a table into this class.
--- @return self o
function Object:adopt(o)
   o._isInstance = true

   -- we hard cast self to a table
   --- @diagnostic disable-next-line
   --- @cast self Object
   setmetatable(o, self)
   self.__index = self
   self.__call = self.__call or Object.__call

   return o
end

function Object:isInstance()
   return self._isInstance
end

--- The default constructor for the class. Subclasses should override this.
--- @param ... any
function Object:__new(...) end

--- Checks if o is in the inheritance chain of self.
--- @param o any The class to check.
--- @return boolean is True if o is in the inheritance chain of self, false otherwise.
function Object:is(o)
   if not o then return false end

   if self == o then return true end

   local parent = getmetatable(o)
   while parent do
      if parent == self then return true end

      parent = getmetatable(parent)
   end

   return false
end

local errorString = "%s expected. Got: %s"
--- Asserts the type of an object, erroring if the given prototype isn't in the inheritance chain of the object.
---@param o any
---@param prototype any
function Object.assertType(o, prototype)
   if not prototype:is(o) then error(errorString:format(prototype.className, tostring(o))) end
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
--- This does not deep copy or merge tables, currently. It's a shallow mixin.
--- @param mixin table The table containing methods and properties to mix in.
--- @return self
function Object:mixin(mixin)
   for k, v in pairs(mixin) do
      if not unmixed[k] then self[k] = v end
   end

   return self
end

function Object.serialize(object)
   assert(object, "Object cannot be nil.")
   local visited = {}
   local stack = { object }
   local nextId = 1
   local objectToId = {}

   local result = {
      references = {},
      rootId = nil,
   }

   local function getObjectId(obj)
      if not objectToId[obj] then
         objectToId[obj] = nextId
         nextId = nextId + 1
      end
      return objectToId[obj]
   end

   local function isSerializableObject(value)
      return type(value) == "table" and getmetatable(value) and Object:is(value)
   end

   local function shouldSerialize(obj, key, value)
      local serializable = value ~= nil and type(value) ~= "function"
      if obj.serializationBlacklist and obj.serializationBlacklist[key] then return false end

      if Object._serializationBlacklist[key] then return false end
      return serializable
   end

   local function serializeValue(v)
      if prism._ISCLASS[v] then return { p = prism._ISCLASS[v] } end
      if type(v) == "table" then
         return { r = getObjectId(v) }
      else
         return v
      end
   end

   local ctx = {
      getObjectId = getObjectId,
      serializeValue = serializeValue,
      isSerializableObject = isSerializableObject,
      queue = function(v)
         if type(v) == "table" and not visited[v] and not prism._ISCLASS[v] then
            table.insert(stack, v)
         end
      end,
   }

   result.rootId = getObjectId(object)

   while #stack > 0 do
      local obj = table.remove(stack)
      if not visited[obj] then
         visited[obj] = true

         local sourceTable = obj
         local className

         if isSerializableObject(obj) then
            className = obj.className
            if className == "Level" then print "SERIALIZING LEVEL" end
            if obj.__serialize then
               sourceTable = obj:__serialize(ctx)
            end
         end

         local objData = {
            id = getObjectId(obj),
            c = className,
            e = {},
         }

         for k, v in pairs(sourceTable) do
            if shouldSerialize(obj, k, v) then
               table.insert(objData.e, {
                  k = serializeValue(k),
                  v = serializeValue(v),
               })

               if type(v) == "table" and not visited[v] and not prism._ISCLASS[v] then
                  table.insert(stack, v)
               end
               if type(k) == "table" and not visited[k] and not prism._ISCLASS[k] then
                  table.insert(stack, k)
               end
            end
         end

         result.references[objData.id] = objData
      end
   end

   for i = 1, nextId - 1 do
      assert(result.references[i], "Missing reference for ID: " .. i)
   end

   return result
end

function Object.deserialize(data)
   assert(type(data) == "table", "Deserialization data must be a table")
   assert(data.rootId, "Deserialization data must have a rootId")
   assert(data.references, "Deserialization data must have a references table")

   local refs = data.references
   local idToObject = {}

   -- 1) Allocate plain shells for all ids 
   for id, _ in ipairs(refs) do
      idToObject[id] = {}
   end

   local function resolveValue(value)
      if type(value) ~= "table" then return value end
      if value.p then
         local proto = prism._OBJECTREGISTRY[value.p]
         assert(proto, "Unknown prototype tag: " .. tostring(value.p))
         return proto
      end
      if value.r then
         local resolved = idToObject[value.r]
         assert(resolved, "Could not resolve reference: " .. tostring(value.r))
         return resolved
      end
      return value
   end

   -- 2) Adopt class metatables for typed objects
   for id, objData in ipairs(refs) do
      local className = objData.c
      if className then
         local class = prism._OBJECTREGISTRY[className]
         assert(class, "Could not find class " .. tostring(className) .. " in registry")
         Object.adopt(class, idToObject[id])
      end
   end

   -- Hook context
   local ctx = {
      revive = resolveValue,
      getById = function(i) return idToObject[i] end,
   }

   -- 3) Fill fields (use __deserialize if provided; otherwise assign directly)
   for id, objData in ipairs(refs) do
      local obj = idToObject[id]

      -- Build revived view
      local view = {}
      for _, entry in ipairs(objData.e or {}) do
         local k = resolveValue(entry.k)
         local v = resolveValue(entry.v)
         view[k] = v
      end

      for k, v in pairs(view) do
         obj[k] = v
      end
   end
   

   for _, obj in ipairs(idToObject) do
      if obj.__deserialize then obj:__deserialize(ctx) end
   end

   -- 4) Post-deserialize hook (optional)
   for _, obj in ipairs(idToObject) do
      if obj.__wire then obj:__wire() end
   end

   for _, obj in ipairs(idToObject) do
      if obj.__finalize then obj:__finalize() end
   end

   return idToObject[data.rootId]
end

--- @param ctx table
function Object:__serialize(ctx)
   return self
end

---@param view table
---@param ctx table
function Object:__deserialize(view, ctx)
   for k, v in pairs(view) do
      self[k] = v
   end
end

--- Pretty-prints an object for debugging or visualization.
--- @param obj table The object to pretty-print.
--- @param indent string The current indentation level (used for recursion).
--- @param visited table A table of visited objects to prevent circular references.
function Object.prettyprint(obj, indent, visited)
   indent = indent or ""
   visited = visited or {}

   if type(obj) ~= "table" then return tostring(obj) end

   if visited[obj] then return "<circular reference>" end

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

--- Performs a deep copy of this object.
--- @generic T
--- @param self T
--- @param ignore table<string, boolean>?
--- @return T copy
function Object:deepcopy(ignore)
   local seen = {}

   local function _copy(v)
      if type(v) ~= "table" then return v end
      if seen[v] then return seen[v] end
      local t = {}
      seen[v] = t
      for k, val in pairs(v) do
         t[_copy(k)] = _copy(val)
      end
      return setmetatable(t, getmetatable(v))
   end

   local out = {}
   for k, v in pairs(self) do
      if not ignore or not ignore[k] then
         out[_copy(k)] = _copy(v)
      end
   end

   return setmetatable(out, getmetatable(self))
end

--- @type Object
local ret = Object:__call()
return ret
