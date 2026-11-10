prism._OBJECTREGISTRY = {}
prism._ISCLASS = {}

--- A simple class system for Lua. This is the base class for all other classes in PRISM.
--- @class Object
--- @field protected super any The superclass of the object.
--- @field private __index any
--- @field private __call any
--- @field className string (static) A unique name for this class. By convention this should match the annotation name you use.
--- @field package _isInstance boolean
--- @field _serializationBlacklist table<any, boolean> Fields omitted from serialization (inherited).
--- @field serializationBlacklist table<any, boolean> Deprecated alias for _serializationBlacklist.
--- @field protected _serializationFields string[]? Positional wire fields for small value classes.
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

   if self:isInstance() then
      error("Object:is was called with an instance but should be called with a prototype!")
   end

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

local blacklistFields = { "_serializationBlacklist", "serializationBlacklist" }

--- Returns the fields this object skips when serialized, including those of its superclasses.
--- @return table<any, boolean>
function Object:getSerializationBlacklist()
   local result = {}
   local current = self
   while current do
      for _, name in ipairs(blacklistFields) do
         for key, excluded in pairs(rawget(current, name) or {}) do
            if excluded then result[key] = true end
         end
      end
      current = getmetatable(current)
   end
   return result
end

--- Serializes this object. See :lua:func:`Serializer.serialize`.
--- @param object table
--- @return table data
function Object.serialize(object)
   return prism.Serializer.serialize(object)
end

--- Deserializes an object. See :lua:func:`Serializer.deserialize`.
--- @param data table
--- @return any object
function Object.deserialize(data)
   return prism.Serializer.deserialize(data)
end

--- Called when the object is serialized. Returns the table whose fields get
--- saved, which is the object itself by default. Don't modify self here.
--- @param ctx table
--- @return table
function Object:__serialize(ctx)
   return self
end

--- Called on every deserialized object once all of them have their saved
--- fields back. Rebuild anything that wasn't saved here. Constructors aren't
--- called when deserializing, except for entities made by a factory.
---
--- Two more optional hooks follow: ``__wire()`` is called on every object after
--- all the ``__deserialize`` calls, and ``__finalize()`` after all the ``__wire``
--- calls. The order objects are visited in within each pass isn't defined.
--- @param ctx table
function Object:__deserialize(ctx) end

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
      if not ignore or not ignore[k] then out[_copy(k)] = _copy(v) end
   end

   return setmetatable(out, getmetatable(self))
end

--- @type Object
local ret = Object:__call()
ret._isInstance = false
prism._OBJECTREGISTRY.Object = ret
prism._ISCLASS[ret] = "Object"
return ret
