require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local SparseMap = prism.SparseMap

describe("SparseMap", function()
   it("inserts and retrieves values at coordinates", function()
      local map = SparseMap()
      map:insert(1, 2, "foo")
      expect.truthy(map:has(1, 2, "foo"))
      expect.equal(map:get(1, 2)["foo"], true)
      expect.equal(map:count(), 1)
      expect.equal(map:countCell(1, 2), 1)
   end)

   it("removes values from coordinates", function()
      local map = SparseMap()
      map:insert(3, 4, "bar")
      expect.truthy(map:has(3, 4, "bar"))
      expect.truthy(map:remove(3, 4, "bar"))
      expect.falsy(map:has(3, 4, "bar"))
      expect.equal(map:count(), 0)
      expect.equal(map:countCell(3, 4), 0)
   end)

   it("removes all instances of a value", function()
      local map = SparseMap()
      map:insert(5, 6, "baz")
      map:insert(7, 8, "baz")
      expect.truthy(map:has(5, 6, "baz"))
      expect.truthy(map:has(7, 8, "baz"))
      map:removeAll("baz")
      expect.falsy(map:has(5, 6, "baz"))
      expect.falsy(map:has(7, 8, "baz"))
      expect.equal(map:count(), 0)
   end)

   it("checks containment of values", function()
      local map = SparseMap()
      map:insert(9, 10, "qux")
      expect.truthy(map:contains("qux"))
      map:remove(9, 10, "qux")
      expect.falsy(map:contains("qux"))
   end)
end)
