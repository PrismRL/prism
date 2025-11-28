require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local SparseGrid = prism.SparseGrid
local Vector2 = prism.Vector2

describe("SparseGrid", function()
   it("should set and get values at coordinates", function()
      local grid = SparseGrid()
      grid:set(1, 2, "foo")
      expect.equal(grid:get(1, 2), "foo")
   end)

   it("should return nil for unset coordinates", function()
      local grid = SparseGrid()
      expect.falsy(grid:get(10, 20))
   end)

   it("should overwrite values at the same coordinate", function()
      local grid = SparseGrid()
      grid:set(3, 4, "bar")
      grid:set(3, 4, "baz")
      expect.equal(grid:get(3, 4), "baz")
   end)

   it("should clear all values", function()
      local grid = SparseGrid()
      grid:set(5, 6, "val")
      grid:clear()
      expect.falsy(grid:get(5, 6))
   end)

   it("should iterate over all entries", function()
      local grid = SparseGrid()
      grid:set(7, 8, "a")
      grid:set(9, 10, "b")
      local found = {}
      for x, y, v in grid:each() do
         found[Vector2._hash(x, y)] = v
      end
      expect.truthy(found[Vector2._hash(7, 8)])
      expect.truthy(found[Vector2._hash(9, 10)])
      expect.equal(found[Vector2._hash(7, 8)], "a")
      expect.equal(found[Vector2._hash(9, 10)], "b")
   end)
end)
