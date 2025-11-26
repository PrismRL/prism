local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local Vector2 = prism.Vector2

describe("Vector2", function()

   it("constructs with defaults", function()
      local v = Vector2()
      expect.equal(v.x, 0)
      expect.equal(v.y, 0)
   end)

   it("constructs with values", function()
      local v = Vector2(3, 5)
      expect.equal(v.x, 3)
      expect.equal(v.y, 5)
   end)

   it("copies correctly", function()
      local a = Vector2(2, 4)
      local b = a:copy()
      expect.equal(b.x, 2)
      expect.equal(b.y, 4)
      expect.truthy(a == b)
   end)

   it("adds vectors", function()
      local a = Vector2(1, 2)
      local b = Vector2(3, 4)
      local c = a + b
      expect.equal(c.x, 4)
      expect.equal(c.y, 6)
   end)

   it("subtracts vectors", function()
      local a = Vector2(5, 5)
      local b = Vector2(2, 3)
      local c = a - b
      expect.equal(c.x, 3)
      expect.equal(c.y, 2)
   end)

   it("multiplies by scalar", function()
      local v = Vector2(2, -3) * 2
      expect.equal(v.x, 4)
      expect.equal(v.y, -6)
   end)

   it("divides by scalar", function()
      local v = Vector2(6, 9) / 3
      expect.equal(v.x, 2)
      expect.equal(v.y, 3)
   end)

   it("negates vector", function()
      local v = -Vector2(3, -5)
      expect.equal(v.x, -3)
      expect.equal(v.y, 5)
   end)

   it("checks equality", function()
      expect.truthy(Vector2(1, 1) == Vector2(1, 1))
      expect.falsy(Vector2(1, 1) == Vector2(2, 1))
   end)

   it("floors correctly", function()
      local v = Vector2(3.8, -1.2):floor()
      expect.equal(v.x, 3)
      expect.equal(v.y, -2)
   end)

   it("rotates clockwise", function()
      local v = Vector2(2, 5):rotateClockwise()
      expect.equal(v.x, 5)
      expect.equal(v.y, -2)
   end)

   it("length returns correct magnitude", function()
      local v = Vector2(3, 4)
      expect.equal(v:length(), 5)
   end)

   it("computes euclidean distance", function()
      expect.equal(Vector2(0, 0):distance(Vector2(3, 4)), 5)
   end)

   it("computes manhattan distance", function()
      expect.equal(Vector2(1, 2):distanceManhattan(Vector2(4, 6)), 7)
   end)

   it("computes chebyshev distance", function()
      expect.equal(Vector2(1, 1):distanceChebyshev(Vector2(4, 3)), 3)
   end)

   it("getRange respects distance type", function()
      local a = Vector2(0, 0)
      local b = Vector2(3, 4)

      expect.equal(a:getRange(b, "euclidean"), 5)
      expect.equal(a:getRange(b, "manhattan"), 7)
      expect.equal(a:getRange(b, "chebyshev"), 4)
      expect.equal(a:getRange(b, "4way"), 7)
      expect.equal(a:getRange(b, "8way"), 4)
   end)

   it("lerps correctly", function()
      local a = Vector2(0, 0)
      local b = Vector2(10, 10)
      local c = a:lerp(b, 0.5)
      expect.equal(c.x, 5)
      expect.equal(c.y, 5)
   end)

   it("hash and unhash are reversible", function()
      for _, coords in ipairs({
         {0, 0},
         {10, -10},
         {-20, 50},
         {-100000, 999999},
      }) do
         local x, y = coords[1], coords[2]
         local h = Vector2._hash(x, y)
         local ux, uy = Vector2._unhash(h)

         expect.equal(ux, x)
         expect.equal(uy, y)
      end
   end)

   it("tostring returns formatted output", function()
      local v = Vector2(3, 7)
      expect.equal(tostring(v), "x: 3 y: 7")
   end)
end)
