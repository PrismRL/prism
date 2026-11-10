require "engine"
require "spectrum"
require "extra.lighting.module"
prism.loadModule("extra/sight")

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect
local Light = require "extra.lighting.components.light"
prism.components.Light = Light
prism.relations.LightsRelation = require "extra.lighting.relations.lights"
prism.relations.LitByRelation = require "extra.lighting.relations.litby"
local LightSystem = require "extra.lighting.systems.lightsystem"
prism.systems.LightSystem = LightSystem
local SightLightPass = require "extra.lighting.passes.sightlightpass"
local Flicker = require "extra.lighting.lighteffects.flicker"
local Heartbeat = require "extra.lighting.lighteffects.heartbeat"
local Sine = require "extra.lighting.lighteffects.sin"
local LightSightSystem = require "extra.lighting.systems.lightsightsystem"
local LightSight = require "extra.lighting.components.lightsight"

local function close(a, b)
   assert(math.abs(a - b) < 1e-10, tostring(a) .. " ~= " .. tostring(b))
end

local function colorEqual(a, b)
   assert((a == nil) == (b == nil), "different lit footprints")
   if a then
      for _, channel in ipairs { "r", "g", "b", "a" } do
         close(a[channel], b[channel])
      end
   end
end

local function floor()
   return prism.Cell():give(prism.components.Collider())
end

local function scene(w, h, ...)
   local system = LightSystem()
   local builder = prism.LevelBuilder():addSeed(1)
   builder:rectangle("fill", 1, 1, w or 32, h or 32, floor)
   builder:addActor(prism.Actor())
   builder:addSystems(system, ...)
   return system, builder:build(floor)
end

local function add(system, x, y, effect, radius)
   local actor = prism.Actor()
   actor:give(prism.components.Position(prism.Vector2(x, y)))
   actor:give(Light(prism.Color4(0.7, 0.4, 0.2, 0.6), radius or 5, effect))
   system.owner:addActor(actor)
   return actor
end

-- Independent full recomposition using the original allocating color arithmetic.
local function reference(system, animated)
   local result = prism.Grid(system.owner:getSize())
   for _, buffer in pairs(system.lightBuffers) do
      for x, y, luminance in buffer.grid:each() do
         local color = buffer.color
         if animated and buffer.effect then
            color = buffer.effect:effect(system.time, color, x, y)
         end
         result:set(x, y, (result:get(x, y) or prism.Color4()) + color * luminance)
      end
   end
   return result
end

local function matchesReference(system)
   for _, animated in ipairs { false, true } do
      local expected = reference(system, animated)
      local actual = animated and system.rtBuffer or system.buffer
      for y = 1, actual.h do
         for x = 1, actual.w do
            colorEqual(actual:get(x, y), expected:get(x, y))
         end
      end
   end
end

-- Always restore instrumented functions, including when an assertion fails.
local function instrument(object, key, replacement, run)
   local original = object[key]
   object[key] = replacement(original)
   local ok, err = pcall(run)
   object[key] = original
   assert(ok, err)
end

describe("Lighting", function()
   it("reuses buffers without retaining footprints, effects or source colors", function()
      local pool = prism.lighting.LightBufferPool()
      local color, sine = prism.Color4(0.2, 0.4, 0.6), Sine()
      local buffer = pool:acquire(color, sine)
      buffer:set(3, 4, 0.5)
      buffer.blockers:set(5, 4, true)
      buffer:getColorAt(1, 3, 4, prism.Color4())
      pool:release(buffer)
      assert(buffer.color == nil and buffer.effect == nil)
      assert(buffer:getBounds() == nil)
      assert(not buffer:get(3, 4) and not buffer.blockers:get(5, 4))
      local nextColor, heartbeat = prism.Color4(0.8, 0.6, 0.4), Heartbeat()
      local reused = pool:acquire(nextColor, heartbeat)
      assert(rawequal(reused, buffer))
      reused:update(2)
      colorEqual(reused:getColorAt(2, 3, 4), heartbeat:effect(2, nextColor))
      pool:release(reused)
      reused = pool:acquire(color)
      assert(rawequal(reused:getColorAt(3, 3, 4), color))
   end)

   it("reuses a moving light's buffer after unregistering its old coverage", function()
      local system = scene()
      local actor = add(system, 5, 5, Sine())
      system:update()
      local original = system.lightBuffers[actor]
      system.owner:moveActor(actor, prism.Vector2(20, 20))
      system:update()
      assert(rawequal(system.lightBuffers[actor], original))
      assert(not system:getValue(5, 5))
      assert(system:getValue(20, 20))
      matchesReference(system)
   end)

   it("evaluates attenuation once per distance and resets the cache between casts", function()
      local system = scene()
      local light = Light(prism.Color4.WHITE, 8)
      local calls = {}
      instrument(light, "attenuate", function(original)
         return function(self, depth)
            calls[depth] = (calls[depth] or 0) + 1
            return original(self, depth)
         end
      end, function()
         local buffer = system:cast(16, 16, light)
         for _, count in pairs(calls) do
            expect.equal(count, 1)
         end
         close(buffer:get(17, 16), (7 / 8) ^ 2)
         light.radius, calls = 1, {}
         buffer = system:cast(16, 16, light)
         expect.equal(calls[1], 1)
         expect.equal(buffer:get(17, 16), 0)
      end)
   end)

   it("averages perceived nonopaque neighbors into an optional owned color", function()
      local system, level = scene()
      system.needsRebuild = false
      local senses = prism.components.Senses()
      local viewer = prism.Actor():give(senses)
      senses.cells:set(10, 10, true)
      senses.cells:set(9, 10, true)
      senses.cells:set(11, 10, true)
      senses.cells:set(10, 9, true)
      level:setCell(10, 9, floor():give(prism.components.Opaque()))
      for _, grid in ipairs { system.buffer, system.rtBuffer } do
         grid:set(9, 10, prism.Color4(0.4, 0.2, 0.8, 0.5))
         grid:set(11, 10, prism.Color4(0.6, 0.8, 0.2, 0.7))
         grid:set(10, 9, prism.Color4(1, 1, 1)) -- opaque
         grid:set(10, 11, prism.Color4(1, 1, 1)) -- unseen
      end
      local expected = prism.Color4(0.5, 0.5, 0.5, 1.1)
      local out, allocations = prism.Color4(), 0
      for _, get in ipairs { LightSystem.getValuePerspective, LightSystem.getRTValuePerspective } do
         colorEqual(get(system, 10, 10, viewer), expected)
         instrument(prism.Color4, "__new", function(original)
            return function(...)
               allocations = allocations + 1
               return original(...)
            end
         end, function()
            for _ = 1, 3 do
               assert(rawequal(get(system, 10, 10, viewer, out), out))
               colorEqual(out, expected)
            end
         end)
         colorEqual(system.buffer:get(9, 10), prism.Color4(0.4, 0.2, 0.8, 0.5))
      end
      expect.equal(allocations, 0)
   end)

   it("preserves direct, dark and unseen sampling behavior with optional outputs", function()
      local system = scene()
      system.needsRebuild = false
      local senses = prism.components.Senses()
      local viewer = prism.Actor():give(senses)
      senses.cells:set(8, 8, true)
      senses.cells:set(16, 16, true)
      local source = prism.Color4(0.2, 0.4, 0.8, 0.6)
      system.buffer:set(8, 8, source)
      system.rtBuffer:set(8, 8, source)
      local out = prism.Color4()
      for _, get in ipairs { LightSystem.getValuePerspective, LightSystem.getRTValuePerspective } do
         assert(rawequal(get(system, 8, 8, viewer), source))
         assert(rawequal(get(system, 8, 8, viewer, out), out))
         colorEqual(out, source)
         out:compose(1, 1, 1, 1)
         colorEqual(source, prism.Color4(0.2, 0.4, 0.8, 0.6))
         assert(get(system, 20, 20, viewer, out) == nil)
         colorEqual(out, prism.Color4(1, 1, 1, 1))
         assert(get(system, 8, 8, prism.Actor(), out) == nil)
         assert(rawequal(get(system, 16, 16, viewer, out), out))
         colorEqual(out, prism.Color4())
         colorEqual(get(system, 16, 16, viewer), prism.Color4())
      end
   end)

   it("ignores unrelated components while position changes invalidate carried lights", function()
      local system = scene()
      local carrier = add(system, 8, 8)
      local carried = add(system, 9, 8)
      carried:remove(prism.components.Position)
      carried:addRelation(prism.relations.LightsRelation(), carrier)
      system:update()
      local cached = system.lightBuffers[carried]
      carrier:give(prism.components.Name("torch"))
      carrier:remove(prism.components.Name)
      assert(not system.needsRebuild)
      assert(rawequal(system.lightBuffers[carried], cached))
      carrier:remove(prism.components.Position)
      assert(system.needsRebuild)
      assert(system.lightBuffers[carried] == nil)
      system:update()
      assert(not next(system.buffer.data))
      carrier:give(prism.components.Position(prism.Vector2(20, 8)))
      system:update()
      assert(system:getValue(20, 8))
      matchesReference(system)
   end)

   it("matches full RGBA recomposition for overlapping static and animated lights", function()
      local system = scene()
      local source = add(system, 8, 8)
      add(system, 9, 8, Flicker())
      add(system, 8, 9, Heartbeat())
      add(system, 10, 9, Sine())
      system:update()
      matchesReference(system)
      local color = source:expect(Light):getColor()
      colorEqual(color, prism.Color4(0.7, 0.4, 0.2, 0.6))
      local gameplay = prism.Color4.copy(system:getValue(8, 8))
      system:update()
      matchesReference(system)
      colorEqual(system:getValue(8, 8), gameplay)
      assert(not rawequal(system:getValue(8, 8), system:getRTValue(8, 8)))
   end)

   it("does no compositing or color allocation on unchanged static frames", function()
      local system = scene()
      add(system, 8, 8)
      system:update()
      local color = system:getRTValue(8, 8)
      local tiles, allocations = 0, 0
      instrument(system, "updateTile", function(original)
         return function(...)
            tiles = tiles + 1
            return original(...)
         end
      end, function()
         instrument(prism.Color4, "__new", function(original)
            return function(...)
               allocations = allocations + 1
               return original(...)
            end
         end, function()
            system:update()
         end)
      end)
      expect.equal(tiles, 0)
      expect.equal(allocations, 0)
      assert(rawequal(color, system:getRTValue(8, 8)))
   end)

   it("rebuilds only old/new coverage and retains unrelated light caches", function()
      local system = scene()
      local moving = add(system, 5, 5)
      local distant = add(system, 26, 26)
      system:update()
      local cast = system.lightBuffers[distant]
      local distantColor = system:getValue(26, 26)
      local untouched = prism.Color4.copy(distantColor)
      system.owner:moveActor(moving, prism.Vector2(14, 5))
      local recomposed = {}
      instrument(system, "updateTile", function(original)
         return function(self, index, ...)
            recomposed[index] = true
            return original(self, index, ...)
         end
      end, function()
         system:update()
      end)
      assert(system:getValue(5, 5) == nil)
      assert(rawequal(system.lightBuffers[distant], cast))
      assert(rawequal(system:getValue(26, 26), distantColor))
      assert(not recomposed[system.buffer:getIndex(26, 26)])
      colorEqual(distantColor, untouched)
      matchesReference(system)
   end)

   it("handles gameplay rebuilds before rendering and multiple moves before a frame", function()
      local system = scene()
      local actor = add(system, 5, 5, Heartbeat())
      system:update()
      system.owner:moveActor(actor, prism.Vector2(14, 5))
      assert(system:getValue(14, 5))
      system.owner:moveActor(actor, prism.Vector2(24, 5))
      assert(system:getValue(24, 5))
      system:update()
      assert(system:getRTValue(5, 5) == nil)
      assert(system:getRTValue(14, 5) == nil)
      matchesReference(system)
   end)

   it("removes stale animated influence after component changes and actor removal", function()
      local system = scene()
      local actor = add(system, 8, 8, Heartbeat())
      add(system, 9, 8)
      system:update()
      actor:remove(Light)
      system:update()
      assert(not next(system.animatedInfluence.data))
      matchesReference(system)
      actor:give(Light(prism.Color4(1, 0, 0), 4))
      system:update()
      matchesReference(system)
      system.owner:removeActor(actor)
      system:update()
      assert(system.lightBuffers[actor] == nil)
      matchesReference(system)
   end)

   it("invalidates all lights at a closed door when it opens and closes", function()
      local system, level = scene(16, 1)
      level:setCell(6, 1, floor():give(prism.components.Opaque()))
      local a = add(system, 3, 1, nil, 12)
      local b = add(system, 4, 1, Heartbeat(), 12)
      system:update()
      assert(not system:getValue(6, 1))
      assert(not system:getValue(7, 1))
      level:setCell(6, 1, floor())
      assert(not system.lightBuffers[a] and not system.lightBuffers[b])
      system:update()
      assert(system:getValue(7, 1))
      matchesReference(system)
      level:setCell(6, 1, floor():give(prism.components.Opaque()))
      system:update()
      assert(not system:getValue(7, 1))
      assert(not system:getRTValue(7, 1))
      matchesReference(system)
   end)

   it("evaluates uniform effects once per light and legacy spatial effects per tile", function()
      local uniformCalls, spatialCalls = 0, 0
      local uniform = {
         spatiallyUniform = true,
         effect = function(_, time, color)
            uniformCalls = uniformCalls + 1
            return color
         end,
      }
      local spatial = {
         effect = function(_, time, color, x, y)
            spatialCalls = spatialCalls + 1
            return color * (x / 32 + y / 32)
         end,
      }
      local system = scene()
      add(system, 8, 8, uniform)
      local actor = add(system, 9, 8, spatial)
      system:update()
      local count = 0
      for _ in pairs(system.lightBuffers[actor].grid.data) do
         count = count + 1
      end
      expect.equal(uniformCalls, 1)
      expect.equal(spatialCalls, count)
      matchesReference(system)
   end)

   it("reuses colors on animated frames without mutating gameplay colors", function()
      local system = scene()
      add(system, 8, 8, Heartbeat())
      add(system, 9, 8, Flicker())
      add(system, 10, 8, Sine())
      system:update()
      local allocations = 0
      instrument(prism.Color4, "__new", function(original)
         return function(...)
            allocations = allocations + 1
            return original(...)
         end
      end, function()
         system:update()
      end)
      expect.equal(allocations, 0)
      matchesReference(system)
   end)

   it("caches sine noise per light and refreshes when spatial scale or position changes", function()
      local system = scene()
      local effect = Sine()
      local actor = add(system, 8, 8, effect)
      local calls = 0
      instrument(love.math, "noise", function(original)
         return function(...)
            calls = calls + 1
            return original(...)
         end
      end, function()
         system:update()
         local first = calls
         assert(first > 0)
         system:update()
         expect.equal(calls, first)
         effect.spatialScale = 0.4
         system:update()
         expect.equal(calls, first * 2)
         system.owner:moveActor(actor, prism.Vector2(9, 8))
         system:update()
         expect.equal(calls, first * 3)
      end)
      matchesReference(system)
      for _, time in ipairs { 0, 1, 3.5 } do
         local out, cache = prism.Color4(), {}
         colorEqual(
            effect:effect(time, prism.Color4.WHITE, 3, 4, out, cache),
            effect:effect(time, prism.Color4.WHITE, 3, 4)
         )
      end
   end)

   it("matches fresh casts after movement, opacity changes and light replacements", function()
      local system, level = scene(16, 16)
      local actors = {}
      for i = 1, 5 do
         actors[i] = add(system, i * 2, i * 2, i % 2 == 0 and Heartbeat() or nil)
      end
      system:update()
      local seed = 37
      local function random(limit)
         seed = (seed * 16807) % 2147483647
         return seed % limit + 1
      end
      instrument(love.timer, "getTime", function()
         return function()
            return 1.25
         end
      end, function()
         for step = 1, 40 do
            local actor = actors[random(#actors)]
            if step % 3 == 0 then
               local x, y = random(16), random(16)
               local cell = floor()
               if not level:getCellOpaque(x, y) then cell:give(prism.components.Opaque()) end
               level:setCell(x, y, cell)
            elseif step % 3 == 1 then
               system.owner:moveActor(actor, prism.Vector2(random(16), random(16)))
            else
               actor:give(
                  Light(
                     prism.Color4(0.3, 0.6, 0.9, 0.5),
                     random(5) + 1,
                     step % 2 == 0 and Sine() or nil
                  )
               )
            end
            if step % 2 == 0 then system:getValue(8, 8) end
            system:update()
            local fresh = LightSystem()
            fresh.owner = level
            fresh:initialize(level)
            fresh:update()
            for index = 1, 16 * 16 do
               colorEqual(system.buffer.data[index], fresh.buffer.data[index])
               colorEqual(system.rtBuffer.data[index], fresh.rtBuffer.data[index])
            end
         end
      end)
   end)

   it("invalidates opacity components and clears all indices on actor removal", function()
      local system, level = scene()
      local actor = add(system, 8, 8)
      system:update()
      actor:give(prism.components.Opaque())
      assert(system.needsRebuild)
      system:update()
      actor:remove(prism.components.Opaque)
      assert(system.needsRebuild)
      system:update()
      level:removeActor(actor)
      system:update()
      assert(not next(system.buffer.data))
      assert(not next(system.rtBuffer.data))
      assert(not next(system.opacityInfluence.data))
   end)

   it("propagates dirtiness through carried lights and tolerates relation cycles", function()
      local system = scene()
      local carrier = add(system, 8, 8)
      local carried = add(system, 9, 8)
      carried:remove(prism.components.Position)
      carried:addRelation(prism.relations.LightsRelation(), carrier)
      system:update()
      system.owner:moveActor(carrier, prism.Vector2(20, 8))
      system:update()
      assert(not system:getValue(8, 8))
      assert(system:getValue(20, 8))
      matchesReference(system)
      carrier:addRelation(prism.relations.LightsRelation(), carried)
      system:setDirty(carrier)
      system:update()
      matchesReference(system)
   end)
end)

describe("LightSightSystem", function()
   it("reuses scratch objects and defers visibility changes until sampling finishes", function()
      local sight = LightSightSystem()
      local lighting, level = scene(32, 32, prism.systems.SensesSystem(), sight)
      lighting:update()
      local senses = prism.components.Senses()
      local actor = prism
         .Actor()
         :give(prism.components.Position(prism.Vector2(8, 8)))
         :give(senses)
         :give(LightSight { range = 2, fov = false, darkvision = 0.125 })
      level:addActor(actor)
      local function cells()
         local count = 0
         for _ in pairs(senses.cells.data) do
            count = count + 1
         end
         return count
      end
      local function sample()
         instrument(lighting, "getValuePerspective", function(original)
            return function(self, x, y, viewer, out)
               assert(out)
               expect.equal(cells(), 25)
               return original(self, x, y, viewer, out)
            end
         end, function()
            level:trigger("onSenses", level, actor)
         end)
         assert(actor:hasRelation(prism.relations.SeesRelation, actor))
      end
      sample()
      expect.equal(cells(), 9)
      local allocations = 0
      local function count(original)
         return function(...)
            allocations = allocations + 1
            return original(...)
         end
      end
      instrument(prism.Color4, "__new", count, function()
         instrument(prism.Vector2, "__new", count, sample)
      end)
      expect.equal(allocations, 0)
      expect.equal(cells(), 9)
      -- A shorter rejection list must not remove entries retained from last time.
      for x = 6, 10 do
         for y = 6, 10 do
            lighting.buffer:set(x, y, prism.Color4.WHITE)
         end
      end
      sample()
      expect.equal(cells(), 25)
      lighting.buffer:clear()
      sample()
      expect.equal(cells(), 9)
   end)
end)

-- Preserve the original allocating display pass as a differential oracle.
local function referencePass(entity, drawable, light, darkvision)
   local base, background = drawable.color:copy(), drawable.background:copy()
   if prism.Actor:is(entity) then
      local value = math.min(light:average(), 1)
      drawable.color = drawable.color * value
      drawable.background = drawable.background * value
   else
      drawable.color.r = drawable.color.r * light.r
      drawable.color.g = drawable.color.g * light.g
      drawable.color.b = drawable.color.b * light.b
      drawable.background.r = drawable.background.r * light.r
      drawable.background.g = drawable.background.g * light.g
      drawable.background.b = drawable.background.b * light.b
   end
   local darkness = math.max(math.min(math.max(1 - drawable.color:average(), 0), 1) - darkvision, 0)
   darkness = darkness <= 0.6 and 0 or (darkness - 0.6) / 0.4
   drawable.color = drawable.color:lerp(base, darkness ^ 1.5)
   drawable.background = drawable.background:lerp(background, darkness ^ 1.5)
   drawable.color.a = base.a * (1 - darkness * 0.70)
end

describe("SightLightPass", function()
   it("matches the original display pass without allocating", function()
      local system, level = scene()
      system:update()
      local sight = LightSight { range = 1, fov = false, darkvision = 0 }
      local senses = prism.components.Senses()
      local player = prism.Actor():give(senses):give(sight)
      level:addActor(player)
      senses.cells:set(1, 1, level:getCell(1, 1))
      local pass = SightLightPass(system)
      pass:setPlayer(player)
      local allocations = 0
      for _, entity in ipairs { prism.Actor(), prism.Cell() } do
         for _, value in ipairs { 0, 0.1, 0.4, 0.8, 2 } do
            for _, vision in ipairs { 0, 0.125, 0.5 } do
               sight.darkvision = vision
               local light = prism.Color4(value, value * 0.7, value * 0.3)
               system.rtBuffer:set(1, 1, light)
               local actual = {
                  color = prism.Color4(0.9, 0.3, 0.6, 0.8),
                  background = prism.Color4(0.2, 0.6, 0.7, 0.4),
               }
               local expected =
                  { color = actual.color:copy(), background = actual.background:copy() }
               referencePass(entity, expected, light, vision)
               instrument(prism.Color4, "__new", function(original)
                  return function(...)
                     allocations = allocations + 1
                     return original(...)
                  end
               end, function()
                  pass:run(entity, 1, 1, actual)
               end)
               colorEqual(actual.color, expected.color)
               colorEqual(actual.background, expected.background)
            end
         end
      end
      expect.equal(allocations, 0)
   end)
end)
