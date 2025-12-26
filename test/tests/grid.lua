require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local Grid = prism.Grid

describe("Grid", function()
   it("constructs with correct dimensions and optional initial value", function()
      local g = Grid(3, 2, 0)
      expect.equal(g.w, 3)
      expect.equal(g.h, 2)
      expect.equal(#g.data, 6)
      for i = 1, #g.data do
         expect.equal(g.data[i], 0)
      end

      local g2 = Grid(2, 2)
      expect.equal(g2.w, 2)
      expect.equal(g2.h, 2)
      expect.equal(#g2.data, 0)
   end)

   it("fromData initializes correctly", function()
      local g = Grid(1, 1)
      local data = { 1, 2, 3, 4 }
      g:fromData(2, 2, data)
      expect.equal(g.w, 2)
      expect.equal(g.h, 2)
      expect.equal(g.data, data)
      expect.equal(#g.data, 4)
   end)

   it("fromData asserts on wrong length", function()
      local g = Grid(1, 1)
      local ok, err = pcall(function()
         g:fromData(2, 2, { 1, 2, 3 })
      end)
      expect.falsy(ok)
   end)

   it("getIndex returns correct indices and nil out of bounds", function()
      local g = Grid(3, 2)
      expect.equal(g:getIndex(1, 1), 1)
      expect.equal(g:getIndex(3, 1), 3)
      expect.equal(g:getIndex(1, 2), 4)
      expect.equal(g:getIndex(3, 2), 6)

      expect.falsy(g:getIndex(0, 1))
      expect.falsy(g:getIndex(4, 1))
      expect.falsy(g:getIndex(1, 0))
      expect.falsy(g:getIndex(1, 3))
   end)

   it("set and get within bounds", function()
      local g = Grid(2, 2)
      g.data = { nil, nil, nil, nil }

      g:set(1, 1, "a")
      g:set(2, 1, "b")
      g:set(1, 2, "c")
      g:set(2, 2, "d")

      expect.equal(g:get(1, 1), "a")
      expect.equal(g:get(2, 1), "b")
      expect.equal(g:get(1, 2), "c")
      expect.equal(g:get(2, 2), "d")
   end)

   it("set throws on out of bounds", function()
      local g = Grid(2, 2)
      local ok1 = pcall(function()
         g:set(0, 1, "x")
      end)
      local ok2 = pcall(function()
         g:set(3, 1, "x")
      end)
      local ok3 = pcall(function()
         g:set(1, 0, "x")
      end)
      local ok4 = pcall(function()
         g:set(1, 3, "x")
      end)

      expect.falsy(ok1)
      expect.falsy(ok2)
      expect.falsy(ok3)
      expect.falsy(ok4)
   end)

   it("get returns nil out of bounds", function()
      local g = Grid(2, 2, 1)
      expect.falsy(g:get(0, 1))
      expect.falsy(g:get(3, 1))
      expect.falsy(g:get(1, 0))
      expect.falsy(g:get(1, 3))
   end)

   it("fill sets all cells to a value", function()
      local g = Grid(3, 2)
      g.data = { 1, 2, 3, 4, 5, 6 }
      g:fill(9)
      expect.equal(#g.data, 6)
      for i = 1, #g.data do
         expect.equal(g.data[i], 9)
      end
   end)
end)
