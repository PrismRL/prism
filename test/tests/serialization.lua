require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local Object = prism.Object
local Serializer = prism.Serializer
local Relation = prism.Relation:extend("SerializationRelation")

local function roundtrip(value, codec)
   local data = Serializer.serialize(value)
   if codec == "json" then data = prism.json.decode(prism.json.encode(data)) end
   if codec == "messagepack" then data = prism.messagepack.unpack(prism.messagepack.pack(data)) end
   return Serializer.deserialize(data)
end

local function cell()
   return prism.Cell.fromComponents({ prism.components.Collider() })
end

local function actor()
   return prism.Actor.fromComponents({ prism.components.Position(prism.Vector2(1, 1)) })
end

local factoryCalls = 0
local Data = prism.Component:extend("SerializationFactoryData")

function Data:__new()
   self.health = 10
   self.settings = { enabled = true }
   self.obsolete = "remove me"
end

local Symmetric = prism.Relation:extend("SerializationSymmetric")

function Symmetric:generateSymmetric()
   return Symmetric()
end

prism.registerActor("SerializationFactoryActor", function()
   factoryCalls = factoryCalls + 1
   local a = prism.Actor.fromComponents({ Data(), prism.components.Position() })
   a.label = "baseline"
   return a
end)
prism.registerCell("SerializationFactoryCell", cell)

local function factoryActor()
   return prism.actors.SerializationFactoryActor()
end

describe("Serialization", function()
   it("keeps Object serialization entry points compatible with Serializer", function()
      local value = Data()
      local data = Serializer.serialize(value)
      expect.equal(Object.serialize(value), data)
      expect.equal(value:serialize(), data)
      for _, copy in ipairs({ Object.deserialize(data), Serializer.deserialize(data) }) do
         expect.truthy(Data:is(copy))
         expect.equal(copy.health, value.health)
         expect.equal(copy.settings, value.settings)
         expect.falsy(rawequal(copy.settings, value.settings))
      end
   end)

   it("saves an unchanged factory entity as just its factory", function()
      local a, b = factoryActor(), factoryActor()
      local calls = factoryCalls
      local data = Serializer.serialize({ a, b })
      expect.equal(factoryCalls - calls, 1)
      local entityData = Serializer.serialize(a)
      expect.equal(entityData.references[entityData.rootId], {
         "f",
         1,
      })
      expect.equal(#entityData.references, 1)
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip(a, codec)
         expect.truthy(copy:has(Data, prism.components.Position))
         expect.truthy(rawequal(copy:expect(Data).owner, copy))
         expect.equal(copy.__factory, a.__factory)
      end
      expect.truthy(Serializer.serialize(actor()).references[1][1] ~= "f")
   end)

   it("saves changed fields and added and removed components of a factory entity", function()
      local a = factoryActor()
      a:expect(Data).health = 4
      a:expect(Data).obsolete = nil
      a:remove(prism.components.Position)
      a:give(prism.components.Collider())
      a.label, a.extra = nil, "added"
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip(a, codec)
         expect.equal(copy:expect(Data).health, 4)
         expect.equal(copy:expect(Data).obsolete, nil)
         expect.falsy(copy:has(prism.components.Position))
         expect.truthy(copy:has(prism.components.Collider))
         expect.truthy(getmetatable(copy.components[1]) == Data)
         expect.truthy(getmetatable(copy.components[2]) == prism.components.Collider)
         expect.equal(copy.label, nil)
         expect.equal(copy.extra, "added")
         expect.equal(Serializer.serialize(copy), Serializer.serialize(a))
      end
      local data = Serializer.serialize(a)
      local record = data.references[data.rootId]
      expect.equal(data.version, 1)
      expect.equal(record[4], { 2 })
      expect.equal(#record[5], 1)
   end)

   it("does not save component order", function()
      local b = factoryActor()
      b.components[1], b.components[2] = b.components[2], b.components[1]
      local data = Serializer.serialize(b)
      expect.equal(data.references[data.rootId], { "f", 1 })
      expect.equal(#data.references, 1)
      local copy = roundtrip(b)
      expect.truthy(getmetatable(copy.components[1]) == Data)
      expect.truthy(getmetatable(copy.components[2]) == prism.components.Position)
   end)

   it("handles an entity with two components of one class", function()
      -- Built by hand so the test does not depend on how give() replaces.
      local c = factoryActor()
      local replacement = Data()
      replacement.health = 2
      replacement.owner = c
      table.insert(c.components, replacement)
      c.componentCache[Data] = replacement
      local data = Serializer.serialize(c)
      local record = data.references[data.rootId]
      expect.truthy(record[4] == false and #record[5] == 1)
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip(c, codec)
         expect.equal(#copy.components, 3)
         expect.equal(copy.components[1].health, 10)
         expect.equal(copy:expect(Data).health, 2)
         expect.truthy(rawequal(copy:expect(Data), copy.components[3]))
         expect.truthy(rawequal(copy:expect(Data).owner, copy))
      end
   end)

   it("loads added components after the factory's own", function()
      local Needs = prism.Component:extend("SerializationNeedsCollider")
      Needs.requirements = { prism.components.Collider }
      local a = factoryActor()
      a:remove(Data)
      a:give(prism.components.Collider())
      a:give(Needs())
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip(a, codec)
         expect.equal(#copy.components, 3)
         expect.truthy(getmetatable(copy.components[1]) == prism.components.Position)
         expect.truthy(getmetatable(copy.components[2]) == prism.components.Collider)
         expect.truthy(getmetatable(copy.components[3]) == Needs)
         expect.falsy(copy:has(Data))
         expect.truthy(
            copy:clone():has(prism.components.Position, prism.components.Collider, Needs)
         )
         expect.equal(Serializer.serialize(copy), Serializer.serialize(a))
      end
   end)

   it("keeps references between factory entities", function()
      local a, b = factoryActor(), factoryActor()
      local shared = { enabled = true }
      a:expect(Data).target = b
      b:expect(Data).target = a
      a:expect(Data).settings, b:expect(Data).settings = shared, shared
      shared.self = shared
      a.extra = shared
      local root = { a, b, a:expect(Data), a.components, a:expect(Data).settings }
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip(root, codec)
         local ca, cb = copy[1]:expect(Data), copy[2]:expect(Data)
         expect.truthy(rawequal(ca.target, copy[2]) and rawequal(cb.target, copy[1]))
         expect.truthy(rawequal(ca, copy[3]) and rawequal(copy[1].components, copy[4]))
         expect.truthy(rawequal(ca.settings, cb.settings) and rawequal(ca.settings, copy[5]))
         expect.truthy(
            rawequal(ca.settings.self, ca.settings) and rawequal(copy[1].extra, ca.settings)
         )
         expect.truthy(rawequal(ca.owner, copy[1]))
      end
   end)

   it("keeps shared tables that match a factory default", function()
      local a, b = factoryActor(), factoryActor()
      local shared = a:expect(Data).settings
      b:expect(Data).settings = shared
      local position = a:expect(prism.components.Position):getVector()
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip({ a, b, shared, position }, codec)
         expect.truthy(rawequal(copy[1]:expect(Data).settings, copy[3]))
         expect.truthy(rawequal(copy[2]:expect(Data).settings, copy[3]))
         expect.truthy(rawequal(copy[1]:expect(prism.components.Position):getVector(), copy[4]))
      end
   end)

   it("restores relations between factory entities", function()
      local a, b = factoryActor(), factoryActor()
      a:addRelation(Relation(), b)
      a:addRelation(Symmetric(), b)
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip({ a, b }, codec)
         expect.truthy(copy[1]:hasRelation(Relation, copy[2]))
         expect.truthy(copy[1]:hasRelation(Symmetric, copy[2]))
         expect.truthy(copy[2]:hasRelation(Symmetric, copy[1]))
         expect.equal(Serializer.serialize(copy), Serializer.serialize({ a, b }))
      end
   end)

   it("errors on a missing factory", function()
      local data = Serializer.serialize(factoryActor())
      data.factories[data.references[data.rootId][2]] = "prism.missing.SerializationFactory"
      expect.fail(function()
         Serializer.deserialize(data)
      end, "Missing factory prism.missing.SerializationFactory at record 1")
      expect.equal(prism.resolveFactory("prism.missing.SerializationFactory"), nil)
   end)

   it("saves a changed component field without listing the entity's components", function()
      local a = factoryActor()
      a:expect(Data).health = 3
      local data = Serializer.serialize(a)
      expect.truthy(data.references[data.rootId][4] == nil)
      local found = false
      for _, record in ipairs(data.references) do
         if record[1] == "d" then found = true end
      end
      expect.truthy(found)
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip(a, codec)
         expect.equal(copy:expect(Data).health, 3)
         expect.truthy(getmetatable(copy.components[1]) == Data)
         expect.truthy(getmetatable(copy.components[2]) == prism.components.Position)
         expect.truthy(copy:clone():has(Data, prism.components.Position))
      end
   end)

   it("picks up blacklist changes between calls", function()
      local Parent = Object:extend("SerializationMutableParent")
      local Child = Parent:extend("SerializationMutableChild")
      local Sibling = Parent:extend("SerializationMutableSibling")
      local a, b = Child(), Child()
      a.first, a.second, b.first, b.second = 1, 2, 3, 4
      expect.equal(roundtrip(a).first, 1)
      Parent._serializationBlacklist = { first = true }
      expect.equal(roundtrip(a).first, nil)
      Child.serializationBlacklist = { second = true }
      expect.equal(roundtrip(a).second, nil)
      Child.serializationBlacklist.second = nil
      expect.equal(roundtrip(a).second, 2)
      Parent._serializationBlacklist.first = nil
      a._serializationBlacklist = { first = true }
      local copy = roundtrip({ a, b })
      expect.equal(copy[1].first, nil)
      expect.equal(copy[2].first, 3)
      expect.falsy(Sibling():getSerializationBlacklist().first)
      expect.equal(roundtrip(b).first, 3)
   end)

   it("saves a value object in full when one of its fields is blacklisted", function()
      local v = prism.Vector2(2, 3)
      v._serializationBlacklist = { x = true, _serializationBlacklist = true }
      v.extra = "keep"
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip(v, codec)
         expect.equal(rawget(copy, "x"), nil)
         expect.equal(copy.y, 3)
         expect.equal(copy.extra, "keep")
      end
   end)

   it("names the field path in errors", function()
      local child = {}
      child.self = child
      child.bad = coroutine.create(function() end)
      expect.fail(function()
         Serializer.serialize({ deep = child })
      end, "root.deep.bad")
   end)

   it("diffs and applies component fields", function()
      local a, b = Data(), Data()
      expect.equal(a:diff(b), nil)
      b.health = 3
      b.obsolete = nil
      local patch = a:diff(b)
      expect.equal(patch, { set = { health = 3 }, unset = { obsolete = true } })
      a:applyDiff(patch)
      expect.equal(a.health, 3)
      expect.equal(a.obsolete, nil)

      patch = { set = { settings = { enabled = false } } }
      a:applyDiff(patch)
      expect.equal(a.settings, patch.set.settings)
      expect.falsy(rawequal(a.settings, patch.set.settings))
   end)

   it("loads a class under its old name", function()
      Serializer.registerClassAlias("OldSerializationVector", prism.Vector2)
      local data = Serializer.serialize(prism.Vector2(7, 8))
      data.classes[1] = "OldSerializationVector"
      expect.equal(Serializer.deserialize(data), prism.Vector2(7, 8))
   end)

   it("errors on unknown classes and versions", function()
      local data = Serializer.serialize(prism.Vector2(7, 8))
      data.classes[1] = "MissingSerializationClass"
      expect.fail(function()
         Serializer.deserialize(data)
      end, "MissingSerializationClass")

      data = Serializer.serialize(prism.Vector2(7, 8))
      data.version = 999
      expect.fail(function()
         Serializer.deserialize(data)
      end, "Unsupported serialization version")

      data.version = nil
      expect.fail(function()
         Serializer.deserialize(data)
      end, "older version of prism")
   end)

   it("errors on userdata and unregistered classes", function()
      for _, value in ipairs({
         coroutine.create(function() end),
         newproxy(true),
         require("ffi").new("int[1]"),
      }) do
         expect.fail(function()
            Serializer.serialize({ nested = { resource = value } })
         end, "root.nested.resource")
      end
      local hidden = Object:extend("HiddenSerializationClass", true)
      expect.fail(function()
         Serializer.serialize(hidden())
      end, "Unregistered class HiddenSerializationClass")
      local copy = roundtrip({ callback = function() end })
      expect.equal(copy.callback, nil)
   end)

   it("round trips infinity and NaN", function()
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip({ math.huge, -math.huge, 0 / 0 }, codec)
         expect.truthy(copy[1] == math.huge and copy[2] == -math.huge and copy[3] ~= copy[3])
      end
   end)

   it("serializes the same data in the same order", function()
      local function make(reverse)
         local t = { [true] = 1, [false] = 2, [7] = 3, text = 4 }
         local a, b = { x = 1 }, { x = 2 }
         if reverse then
            t[b], t[a] = "b", "a"
         else
            t[a], t[b] = "a", "b"
         end
         return t
      end
      expect.equal(Serializer.serialize(make(false)), Serializer.serialize(make(true)))
      roundtrip(make(false), "json")
   end)

   it("keeps actor IDs stable", function()
      local storage = prism.ActorStorage()
      local a, b, c = actor(), actor(), actor()
      storage:addActor(a)
      storage:addActor(b)
      storage:addActor(c)
      storage:removeActor(b)
      local copy = roundtrip(storage, "json")
      local actors = copy:getAllActors()
      expect.equal(copy:getID(actors[1]), storage:getID(a))
      expect.equal(copy:getID(actors[2]), storage:getID(c))
      local d, e = actor(), actor()
      storage:addActor(d)
      copy:addActor(e)
      expect.equal(copy:getID(e), storage:getID(d))
   end)

   it("round trips Vector2 and Color4", function()
      local vector = prism.Vector2(1, 2)
      local color = prism.Color4(0.1, 0.2, 0.3, 0.4)
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip({ vector, vector, color, color }, codec)
         expect.truthy(rawequal(copy[1], copy[2]) and rawequal(copy[3], copy[4]))
         expect.equal(copy[1], vector)
         expect.equal(copy[3], color)
         vector.extra = "preserved"
         expect.equal(roundtrip(vector, codec).extra, "preserved")
         vector.extra = nil
      end
      local o = Object()
      o.initialValue = 5
      expect.equal(roundtrip(o).initialValue, 5)
   end)

   it("rebuilds an IdleAnimation's animation", function()
      local previous = spectrum
      _G.spectrum = {
         animations = {
            SerializationTest = function()
               return { runtime = true }
            end,
         },
      }
      local ok, err = pcall(function()
         local IdleAnimation = require "spectrum.components.idleanimation"
         local animation = IdleAnimation("SerializationTest")
         animation.animation.resource = require("ffi").new("int[1]")
         local copy = roundtrip(animation, "json")
         expect.truthy(copy.animation.runtime and copy.animation.resource == nil)
         expect.truthy(rawget(copy, "revive") == nil)
      end)
      _G.spectrum = previous
      assert(ok, err)
   end)

   it("doesn't add fields to deserialized objects", function()
      local v = roundtrip(prism.Vector2(2, 3))
      expect.equal(v, prism.Vector2(2, 3))
      expect.equal(rawget(v, "revive"), nil)
      expect.equal(rawget(v, "getById"), nil)
   end)

   it("keeps shared references, cycles, table keys and classes", function()
      local key, root = {}, {}
      root.a, root.b, root.self = key, key, root
      root[key] = root
      root.proto = prism.Vector2
      root[prism.Vector2] = key
      for _, codec in ipairs({ "json", "messagepack" }) do
         local copy = roundtrip(root, codec)
         expect.truthy(rawequal(copy.a, copy.b) and rawequal(copy.self, copy))
         expect.truthy(rawequal(copy[copy.a], copy))
         expect.truthy(rawequal(copy.proto, prism.Vector2))
         expect.truthy(rawequal(copy[prism.Vector2], copy.a))
      end
   end)

   it("inherits blacklists without affecting other classes", function()
      local A = Object:extend("SerializationParent")
      A._serializationBlacklist = { a = true }
      local B = A:extend("SerializationChild")
      B._serializationBlacklist = { b = true }
      B.serializationBlacklist = { alias = true }
      local C = A:extend("SerializationSibling")
      local b = B()
      b.a, b.b, b.alias, b.initialValue = 1, 2, 3, 4
      local copy = roundtrip(b)
      expect.truthy(copy.a == nil and copy.b == nil and copy.alias == nil)
      expect.equal(copy.initialValue, 4)
      expect.falsy(C():getSerializationBlacklist().b)
      expect.falsy(Object._serializationBlacklist.initialValue)
   end)

   it("round trips an ActorStorage", function()
      local a, b = actor(), actor()
      a:addRelation(Relation(), b)
      local storage = prism.ActorStorage()
      storage:addActor(a)
      storage:addActor(b)
      local copy = roundtrip(storage)
      local actors = copy:getAllActors()
      expect.truthy(actors[1]:hasRelation(Relation, actors[2]))
      expect.truthy(rawequal(actors[1]:expect(prism.components.Position).owner, actors[1]))
      expect.equal(#copy:query(prism.components.Position):gather(), 2)
      expect.equal(copy:getID(actors[1]), storage:getID(a))
      local data = Serializer.serialize(storage)
      for _, record in ipairs(data.references) do
         if data.classes[record[1]] == "ActorStorage" then
            for _, entry in ipairs(record[2]) do
               expect.truthy(entry[1] ~= "componentCache" and entry[1] ~= "componentCounts")
            end
         end
      end
   end)

   it("round trips a LevelBuilder", function()
      local builder = prism.LevelBuilder()
      builder:set(1, 1, cell())
      builder:addActor(actor())
      local copy = roundtrip(builder, "json")
      expect.truthy(copy:get(1, 1):has(prism.components.Collider))
      expect.equal(#copy:query():gather(), 1)
   end)
   for _, codec in ipairs({ "json", "messagepack" }) do
      for _, registered in ipairs({ false, true }) do
         it(
            "round trips a Level "
               .. (registered and "of factory entities " or "")
               .. "through "
               .. codec,
            function()
               local makeCell = registered and prism.cells.SerializationFactoryCell or cell
               local makeActor = registered and factoryActor or actor
               local builder = prism.LevelBuilder()
               builder:setMaximumActorSize(6)
               builder:rectangle("fill", 1, 1, 3, 3, makeCell)
               builder:addActor(makeActor())
               local copy = roundtrip(builder:build(makeCell), codec)
               expect.equal(copy.map.w, 3)
               expect.equal(copy.maximumActorSize, 6)
               expect.truthy(copy:getCell(1, 1):has(prism.components.Collider))
               local a = copy:query(prism.components.Position):gather()[1]
               expect.truthy(rawequal(a.level, copy))
               copy:moveActor(a, prism.Vector2(2, 2))
               expect.equal(a:getPosition(), prism.Vector2(2, 2))
               expect.equal(#copy:query():at(2, 2):gather(), 1)
               copy:setCell(1, 1, cell())
               copy:removeActor(a)
               expect.equal(#copy:query():gather(), 0)
            end
         )
      end
   end
end)
