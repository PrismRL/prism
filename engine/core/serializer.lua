--- Converts objects into plain tables that can be encoded as JSON or messagepack,
--- and back again. See the serialization how-to for how classes take part in this.
--- @class Serializer
local Serializer = {}

local Object = prism.Object

local classAliases = {}

--- Registers an old name for a class, so data serialized before the class was
--- renamed can still be loaded.
--- @param oldName string
--- @param class Object
function Serializer.registerClassAlias(oldName, class)
   assert(prism._ISCLASS[class], "Class alias target must be a registered prototype")
   classAliases[oldName] = class
end

local function resolveClass(name)
   return prism._OBJECTREGISTRY[name]
      or classAliases[name]
      or error("Unknown serialized class: " .. tostring(name))
end

-- Returns a lookup that caches each class's blacklist. Make a new one per
-- serialize or deserialize call, so blacklists changed in between are picked up.
local function serializationBlacklists()
   local blacklists, emptyBlacklist = {}, {}
   return function(obj)
      local key = getmetatable(obj)
      if rawget(obj, "_serializationBlacklist") or rawget(obj, "serializationBlacklist") then
         key = obj
      elseif not key then
         return emptyBlacklist
      end
      local blacklist = blacklists[key]
      if not blacklist then
         blacklist = Object.getSerializationBlacklist(obj)
         blacklists[key] = blacklist
      end
      return blacklist
   end
end

-- Whether two values would serialize the same. Classes and entities only equal
-- themselves, and a table referenced from more than one place equals nothing,
-- since it has to be saved as itself.
local function deepEqual(a, b, seen, counts, getBlacklist)
   if type(b) == "table" and not prism._ISCLASS[b] and (counts[b] or 0) > 1 then return false end
   if rawequal(a, b) and (type(a) ~= "table" or prism._ISCLASS[a]) then return true end
   if type(a) ~= type(b) then return false end
   if type(a) ~= "table" then return a == b end

   if prism._ISCLASS[a] or prism._ISCLASS[b] then return false end
   local mt = getmetatable(a)
   if mt ~= getmetatable(b) then return false end
   if mt and (prism.Entity:is(a) or prism.Entity:is(b)) then return false end
   if next(a) == nil and next(b) == nil then return true end
   seen = seen or {}
   if seen[a] then return rawequal(seen[a], b) end
   seen[a] = b
   local blacklist = getBlacklist(a)

   for k, v in pairs(a) do
      if not blacklist[k] and not deepEqual(v, b[k], seen, counts, getBlacklist) then
         return false
      end
   end
   for k, _ in pairs(b) do
      if not blacklist[k] and a[k] == nil then return false end
   end

   return true
end

-- Returns the field changes that turn base into object as { set, unset }, or
-- nil if there are none.
local function diffFields(base, object, counts, getBlacklist, ignored)
   local blacklist = getBlacklist(base)
   local set, unset

   for k, v in pairs(base) do
      if not blacklist[k] and not (ignored and ignored[k]) and type(v) ~= "function" then
         local ov = object[k]
         if ov == nil then
            unset = unset or {}
            unset[k] = true
         elseif not deepEqual(v, ov, nil, counts, getBlacklist) then
            set = set or {}
            set[k] = ov
         end
      end
   end

   for k, ov in pairs(object) do
      if
         not blacklist[k]
         and not (ignored and ignored[k])
         and type(ov) ~= "function"
         and rawget(base, k) == nil
      then
         set = set or {}
         set[k] = ov
      end
   end

   if not (set or unset) then return nil end

   return { set = set, unset = unset }
end

-- Applies a patch from diffFields. Values are assigned as they are, not copied,
-- so references to other deserialized objects stay intact.
local function applyPatch(object, patch, blacklist)
   if patch.unset then
      for k in pairs(patch.unset) do
         if not blacklist[k] then rawset(object, k, nil) end
      end
   end

   if patch.set then
      for k, v in pairs(patch.set) do
         if not blacklist[k] then rawset(object, k, v) end
      end
   end
end

-- Counts how many times each table reachable from root is referenced, and
-- collects the entities that were made by a factory. A table referenced more
-- than once has to be saved as itself, even if it equals a factory default.
local function countReferences(root, getBlacklist)
   local counts, objects = { [root] = 1 }, {}
   local function scan(value)
      if value.__factory and prism.Entity:is(value) then objects[#objects + 1] = value end
      local blacklist = getBlacklist(value)
      for k, v in pairs(value) do
         if not blacklist[k] and type(v) ~= "function" and type(k) ~= "function" then
            if type(k) == "table" and not prism._ISCLASS[k] then
               local count = counts[k]
               counts[k] = (count or 0) + 1
               if not count then scan(k) end
            end
            if type(v) == "table" and not prism._ISCLASS[v] then
               local count = counts[v]
               counts[v] = (count or 0) + 1
               if not count then scan(v) end
            end
         end
      end
   end
   scan(root)

   return counts, objects
end

-- Works out how each factory entity, and each of its components, differs from
-- a fresh instance from the same factory.
local function diffFactoryEntities(objects, counts, getBlacklist)
   local baselines, baselineIndexes, factories, componentDiffs = {}, {}, {}, {}
   local baselineClaims, entitySerial = {}, 0
   local entityIgnored = { components = true, __factory = true }
   for _, entity in ipairs(objects) do
      -- If something else refers to the component list we can't rebuild it
      -- on load, so that entity is saved in full.
      if (counts[entity.components] or 0) <= 1 then
         local path = entity.__factory
         if not baselines[path] then
            -- Factories take no required arguments and build the same thing
            -- each time, so one instance per factory is enough to diff against.
            local factory = assert(prism.resolveFactory(path), "Missing factory: " .. path)
            baselines[path] = factory()
            local indices = {}
            for i, component in ipairs(baselines[path].components) do
               indices[getmetatable(component)] = i
            end
            baselineIndexes[path] = indices
            baselineClaims[path] = {}
         end
         local baseline = baselines[path]
         local patch = diffFields(baseline, entity, counts, getBlacklist, entityIgnored)
         -- Components are matched to the factory's by class. If an entity has
         -- two of one class, the first is matched and the rest count as added.
         local dirty, added
         local matched = 0
         local indices = baselineIndexes[path]
         local claims = baselineClaims[path]
         entitySerial = entitySerial + 1
         for _, component in ipairs(entity.components) do
            local baseIndex = indices[getmetatable(component)]
            if baseIndex and claims[baseIndex] == entitySerial then baseIndex = nil end
            if baseIndex then
               claims[baseIndex] = entitySerial
               matched = matched + 1
               local diff =
                  diffFields(baseline.components[baseIndex], component, counts, getBlacklist)
               if diff or (counts[component] or 0) > 1 then
                  componentDiffs[component] = { entity = entity, index = baseIndex, patch = diff }
                  dirty = dirty or {}
                  dirty[#dirty + 1] = component
               end
            else
               added = added or {}
               added[#added + 1] = component
            end
         end
         local removed
         if matched ~= #baseline.components then
            removed = {}
            for i = 1, #baseline.components do
               if claims[i] ~= entitySerial then removed[#removed + 1] = i end
            end
         end
         factories[entity] = {
            path = path,
            patch = patch,
            removed = removed,
            added = added,
            dirty = dirty,
         }
      end
   end

   return factories, componentDiffs
end

-- Returns a comparison function that puts a table's entries in a stable order.
local function entryComparator(getBlacklist)
   -- Builds a string to sort a table key by, from its contents instead of its
   -- address, so the same data always serializes in the same order.
   local function sortKey(value, seen)
      local kind = type(value)
      if kind ~= "table" then return kind .. ":" .. tostring(value) end
      if prism._ISCLASS[value] then return "prototype:" .. prism._ISCLASS[value] end
      seen = seen or {}
      if seen[value] then return "cycle" end
      seen[value] = true
      local fields = {}
      local blacklist = getBlacklist(value)
      for k, v in pairs(value) do
         if not blacklist[k] and type(v) ~= "function" then
            fields[#fields + 1] = sortKey(k, seen) .. "=" .. sortKey(v, seen)
         end
      end
      table.sort(fields)
      seen[value] = nil
      return "table:" .. (value.className or "") .. "{" .. table.concat(fields, ";") .. "}"
   end
   local function compareEntries(a, b)
      local ak, bk = a[1], b[1]
      local at, bt = type(ak), type(bk)
      if at == "table" and prism._ISCLASS[ak] then at = "prototype" end
      if bt == "table" and prism._ISCLASS[bk] then bt = "prototype" end
      if at ~= bt then return at < bt end
      if at == "string" then return ak < bk end
      if at == "number" then return a[3] < b[3] end
      if at == "boolean" then return not ak and bk end
      a[3], b[3] = a[3] or sortKey(ak), b[3] or sortKey(bk)
      if a[3] ~= b[3] then return a[3] < b[3] end
      a[4], b[4] = a[4] or sortKey(a[2]), b[4] or sortKey(b[2])
      return a[4] < b[4]
   end

   return compareEntries
end

-- The serialized format:
--
--   { version = 1, rootId = id, classes = { className, ... },
--     factories = { factoryPath, ... }, references = { record, ... } }
--
-- A record's index in references is its id. Values inside records are plain,
-- { r = id } for another record, { p = className } for a class, or
-- { n = "inf" | "-inf" | "nan" }. There are four kinds of record:
--
--   { classIndex, { { key, value }, ... } }
--     A table or object. A classIndex of 0 means a plain table.
--   { classIndex, { value, ... }, true }
--     An object whose class lists its fields in _serializationFields.
--   { "f", factoryIndex, patch, removed, added }
--     An entity made by a registered factory. patch refers to a { set, unset }
--     table of field changes, removed lists the indexes of factory components
--     the entity no longer has, and added refers to components the factory
--     didn't create. Trailing fields are left off, and false fills a gap.
--   { "d", entityId, componentIndex, patch }
--     A factory entity's component that was changed, or that something other
--     than its entity refers to.
--
-- Component order isn't saved. A loaded entity has the factory components it
-- kept, in factory order, followed by the added ones.

local FORMAT_VERSION = 1

--- Converts an object, and everything it refers to, into a table that can be
--- encoded as JSON or messagepack. Shared references and cycles are preserved.
--- Functions are skipped, and userdata raises an error.
--- @param object table The object to serialize.
--- @return table data Pass this to :lua:func:`Serializer.deserialize` to get the object back.
function Serializer.serialize(object)
   assert(object, "Object cannot be nil.")
   local visited = {}
   local stack = { object }
   local nextId = 1
   local objectToId = {}
   local paths = { [object] = object.className or "root" }
   local pathParents, pathKeys = {}, {}
   local function pathOf(obj)
      if paths[obj] then return paths[obj] end
      local key = pathKeys[obj]
      return pathOf(pathParents[obj])
         .. "."
         .. (type(key) == "table" and "[table key]" or tostring(key))
   end

   local result = {
      version = FORMAT_VERSION,
      classes = {},
      references = {},
      rootId = nil,
   }

   local classToId, factoryToId, classKinds, numberKeys = {}, {}, {}, {}
   local getBlacklist = serializationBlacklists()

   local function getObjectId(obj)
      if not objectToId[obj] then
         objectToId[obj] = nextId
         nextId = nextId + 1
      end
      return objectToId[obj]
   end

   local function isSerializableObject(value)
      if type(value) ~= "table" then return false end
      local class = getmetatable(value)
      if not class then return false end
      local kind = classKinds[class]
      if kind == nil then
         kind = Object:is(value)
         classKinds[class] = kind
      end
      return kind
   end

   local function serializeValue(v, path, parent, key, isKey)
      local kind = type(v)
      if kind == "userdata" or kind == "cdata" or kind == "thread" then
         local location = path
            or (parent and (pathOf(parent) .. "." .. (type(key) == "table" and "[table key]" or tostring(
               key
            ))))
            or "hook"
         error("Cannot serialize " .. kind .. " at " .. location .. (isKey and "[key]" or ""))
      end
      if kind == "number" then
         if v ~= v then return { n = "nan" } end
         if v == math.huge then return { n = "inf" } end
         if v == -math.huge then return { n = "-inf" } end
      end
      if prism._ISCLASS[v] then return { p = prism._ISCLASS[v] } end
      if type(v) == "table" then
         if not paths[v] and not pathParents[v] then
            if parent then
               pathParents[v], pathKeys[v] = parent, key
            else
               paths[v] = path or "hook"
            end
         end
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
         if type(v) == "table" and not paths[v] and not pathParents[v] then paths[v] = "hook" end
         if type(v) == "table" and not visited[v] and not prism._ISCLASS[v] then
            table.insert(stack, v)
         end
      end,
   }

   local counts, factoryEntities = countReferences(object, getBlacklist)
   local factories, componentDiffs = diffFactoryEntities(factoryEntities, counts, getBlacklist)
   local compareEntries = entryComparator(getBlacklist)

   result.rootId = getObjectId(object)

   while #stack > 0 do
      local obj = table.remove(stack)
      if not visited[obj] then
         visited[obj] = true

         local sourceTable = obj
         local className
         local factory = factories[obj]
         local component = componentDiffs[obj]
         if factory or component then
            local patch = (factory or component).patch
            local patchRef = patch and serializeValue(patch, nil, obj, "diff") or false
            if patch then ctx.queue(patch) end
            if factory then
               if factory.dirty then
                  for _, dirty in ipairs(factory.dirty) do
                     ctx.queue(dirty)
                  end
               end
               local removed = factory.removed or false
               local added = false
               if factory.added then
                  added = {}
                  for i, addedComponent in ipairs(factory.added) do
                     added[i] = serializeValue(addedComponent, nil, obj, "components")
                     ctx.queue(addedComponent)
                  end
               end
               local path = factory.path
               if not factoryToId[path] then
                  result.factories = result.factories or {}
                  result.factories[#result.factories + 1] = path
                  factoryToId[path] = #result.factories
               end
               local record = { "f", factoryToId[path] }
               if patchRef or removed or added then record[3] = patchRef end
               if removed or added then record[4] = removed end
               if added then record[5] = added end
               result.references[getObjectId(obj)] = record
            else
               ctx.queue(component.entity)
               result.references[getObjectId(obj)] = {
                  "d",
                  getObjectId(component.entity),
                  component.index,
                  patchRef,
               }
            end
         else
            if isSerializableObject(obj) then
               className = obj.className
               if prism._OBJECTREGISTRY[className] ~= getmetatable(obj) then
                  error("Unregistered class " .. tostring(className) .. " at " .. pathOf(obj))
               end
               if obj.__serialize then sourceTable = obj:__serialize(ctx) end
            end

            local classId = 0
            if className then
               if not classToId[className] then
                  result.classes[#result.classes + 1] = className
                  classToId[className] = #result.classes
               end
               classId = classToId[className]
            end
            local objData = { classId, {} }

            local fields = className and obj._serializationFields
            local compact = fields ~= nil
            if compact then
               local count = 0
               local blacklist = getBlacklist(obj)
               for k, v in pairs(sourceTable) do
                  if not blacklist[k] and type(v) ~= "function" then count = count + 1 end
               end
               compact = count == #fields
               if compact then
                  for _, name in ipairs(fields) do
                     if
                        sourceTable[name] == nil
                        or blacklist[name]
                        or type(sourceTable[name]) == "function"
                     then
                        compact = false
                        break
                     end
                  end
               end
            end
            if compact then
               for i, name in ipairs(fields) do
                  local v = sourceTable[name]
                  objData[2][i] = serializeValue(v, nil, obj, name)
                  if type(v) == "table" and not visited[v] and not prism._ISCLASS[v] then
                     stack[#stack + 1] = v
                  end
               end
               objData[3] = true
            else
               local entries = objData[2]
               local blacklist = getBlacklist(obj)
               for k, v in pairs(sourceTable) do
                  if not blacklist[k] and type(v) ~= "function" and type(k) ~= "function" then
                     local key
                     if type(k) == "number" then
                        key = numberKeys[k]
                        if not key then
                           key = tostring(k)
                           numberKeys[k] = key
                        end
                     end
                     entries[#entries + 1] = { k, v, key }
                  end
               end
               if #entries > 1 then table.sort(entries, compareEntries) end
               for i, entry in ipairs(entries) do
                  local k, v = entry[1], entry[2]
                  entry[1], entry[2] =
                     serializeValue(k, nil, obj, k, true), serializeValue(v, nil, obj, k)
                  entry[3], entry[4] = nil, nil
                  if type(v) == "table" and not visited[v] and not prism._ISCLASS[v] then
                     stack[#stack + 1] = v
                  end
                  if type(k) == "table" and not visited[k] and not prism._ISCLASS[k] then
                     stack[#stack + 1] = k
                  end
               end

               objData[2] = entries
            end
            result.references[getObjectId(obj)] = objData
         end
      end
   end

   for i = 1, nextId - 1 do
      if not result.references[i] then error("Missing reference for ID: " .. i) end
   end

   return result
end

--- Rebuilds an object from the table returned by :lua:func:`Serializer.serialize`.
--- @param data table
--- @return any object
function Serializer.deserialize(data)
   assert(type(data) == "table", "Deserialization data must be a table")
   assert(
      data.version ~= nil,
      "This data was serialized by an older version of prism and can't be loaded."
   )
   assert(
      data.version == FORMAT_VERSION,
      "Unsupported serialization version: " .. tostring(data.version)
   )
   assert(data.rootId, "Deserialization data must have a rootId")
   assert(data.references, "Deserialization data must have a references table")

   local refs = data.references
   local idToObject, resolvedFactories = {}, {}
   local getBlacklist = serializationBlacklists()

   -- 1) Allocate an empty table for every record
   for id, record in ipairs(refs) do
      if record[1] ~= "f" and record[1] ~= "d" then idToObject[id] = {} end
   end

   -- Factory entities are created by calling their factory, so other records
   -- can refer to the entity and its components right away.
   for id, record in ipairs(refs) do
      if record[1] == "f" then
         local path = data.factories[record[2]]
         local factory = resolvedFactories[record[2]] or prism.resolveFactory(path)
         resolvedFactories[record[2]] = factory
         if not factory then error("Missing factory " .. tostring(path) .. " at record " .. id) end
         local entity = factory()
         if not prism.Entity:is(entity) then
            error("Factory " .. path .. " did not create an entity at record " .. id)
         end
         entity.__factory = path
         idToObject[id] = entity
      end
   end
   for id, record in ipairs(refs) do
      if record[1] == "d" then
         local entity = assert(idToObject[record[2]], "Missing factory entity at record " .. id)
         idToObject[id] =
            assert(entity.components[record[3]], "Missing factory component at record " .. id)
      end
   end

   local function resolveValue(value)
      if type(value) ~= "table" then return value end
      if value.n then
         if value.n == "nan" then return 0 / 0 end
         if value.n == "inf" then return math.huge end
         if value.n == "-inf" then return -math.huge end
         error("Unknown serialized number tag: " .. tostring(value.n))
      end
      if value.p then
         local proto = resolveClass(value.p)
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
      local className = data.classes[objData[1]]
      if className then
         local class = resolveClass(className)
         Object.adopt(class, idToObject[id])
      end
   end

   -- Hook context
   local ctx = {
      revive = resolveValue,
      getById = function(i)
         return idToObject[i]
      end,
   }

   -- 3) Fill in fields
   for id, objData in ipairs(refs) do
      local obj = idToObject[id]
      if objData[1] ~= "f" and objData[1] ~= "d" then
         local entries = objData[2]
         if objData[3] then
            local fields =
               assert(obj._serializationFields, "Missing positional serialization fields")
            for i, name in ipairs(fields) do
               obj[name] = resolveValue(entries[i])
            end
         else
            for _, entry in ipairs(entries) do
               obj[resolveValue(entry[1])] = resolveValue(entry[2])
            end
         end
      end
   end

   -- Patches refer to other records, so apply them once every record is
   -- filled in. Values are assigned as they are, not copied.
   for id, record in ipairs(refs) do
      local kind = record[1]
      if kind == "f" or kind == "d" then
         local obj = idToObject[id]
         local patch = resolveValue(record[kind == "f" and 3 or 4])
         if patch then applyPatch(obj, patch, getBlacklist(obj)) end
         if kind == "f" and (record[4] or record[5]) then
            -- Added components go after the factory's own, so anything
            -- they require is still ahead of them in the list.
            local removed, added = record[4], record[5]
            local components, skip = {}, {}
            if removed then
               for _, index in ipairs(removed) do
                  skip[index] = true
               end
            end
            for index, component in ipairs(obj.components) do
               if not skip[index] then components[#components + 1] = component end
            end
            if added then
               for _, ref in ipairs(added) do
                  components[#components + 1] = resolveValue(ref)
               end
            end
            obj.components = components
         end
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

return Serializer
