require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local function wall()
   return prism.Cell.fromComponents({ prism.components.Collider(), prism.components.Opaque() })
end

local function floor()
   return prism.Cell.fromComponents({ prism.components.Collider() })
end

local function buildLevel()
   return prism
      .LevelBuilder()
      :addActor(prism.Actor())
      :rectangle("fill", 1, 1, 9, 9, floor)
      :pad(1, wall)
end

describe("FOV", function()
   it("empty room", function()
      local level = buildLevel():build(wall)
      local map = level.map.data

      local fov = prism.Grid(11, 11)
      prism.computeFOV(level, prism.Vector2(5, 5), 10, function(x, y, cell)
         fov:set(x, y, cell)
      end)

      expect.equal(map, fov.data)
   end)

   it("zero range", function()
      local level = buildLevel():build(wall)

      local origin = prism.Grid(11, 11)
      origin:set(5, 5, level:getCell(5, 5))
      local fov = prism.Grid(11, 11)
      prism.computeFOV(level, prism.Vector2(5, 5), 0, function(x, y, cell)
         fov:set(x, y, cell)
      end)

      expect.equal(origin.data, fov.data)
   end)

   it("normal range", function()
      local level = buildLevel():build(wall)
      local origin = prism.Grid(11, 11)
      for x = 3, 7 do
         for y = 3, 7 do
            origin:set(x, y, level:getCell(x, y))
         end
      end

      local fov = prism.Grid(11, 11)
      prism.computeFOV(level, prism.Vector2(5, 5), 2, function(x, y, cell)
         fov:set(x, y, cell)
      end)

      expect.equal(origin.data, fov.data)
   end)

   it("one pillar", function()
      local level = buildLevel():set(5, 3, wall()):build(wall)

      local origin = prism.Grid(11, 11)
      for x, y, cell in level:eachCell() do
         origin:set(x, y, cell)
      end
      origin:set(6, 3, nil)
      origin:set(6, 2, nil)
      origin:set(6, 1, nil)

      local fov = prism.Grid(11, 11)
      prism.computeFOV(level, prism.Vector2(6, 6), 10, function(x, y, cell)
         fov:set(x, y, cell)
      end)

      expect.equal(origin.data, fov.data)
   end)
end)
