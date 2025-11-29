require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local BooleanBuffer = prism.BooleanBuffer

describe("BooleanBuffer", function()
   it("initializes all values to false", function()
      local buf = BooleanBuffer(3, 2)
      for y = 1, 2 do
         for x = 1, 3 do
            expect.equal(buf:get(x, y), false)
         end
      end
   end)

   it("sets and gets values correctly", function()
      local buf = BooleanBuffer(2, 2)
      buf:set(1, 1, true)
      buf:set(2, 2, true)
      expect.equal(buf:get(1, 1), true)
      expect.equal(buf:get(2, 2), true)
      expect.equal(buf:get(1, 2), false)
      expect.equal(buf:get(2, 1), false)
   end)

   it("clears all values to false", function()
      local buf = BooleanBuffer(2, 2)
      buf:set(1, 1, true)
      buf:set(2, 2, true)
      buf:clear()
      for y = 1, 2 do
         for x = 1, 2 do
            expect.equal(buf:get(x, y), false)
         end
      end
   end)

   it("throws on out-of-bounds access", function()
      local buf = BooleanBuffer(2, 2)
      local ok = pcall(function()
         buf:get(0, 1)
      end)
      expect.equal(ok, false)
      ok = pcall(function()
         buf:get(1, 3)
      end)
      expect.equal(ok, false)
   end)

   local req = require
   require = function(pkg)
      if pkg == "ffi" then return nil end
      return req(pkg)
   end

   package.loaded["engine.structures.booleanbuffer"] = nil
   package.loaded["bit"] = require("engine.lib.bit")
   prism._OBJECTREGISTRY["BooleanBuffer"] = nil
   BooleanBuffer = require "engine.structures.booleanbuffer"
   require = req

   it("initializes all values to false (5.1 compat)", function()
      local buf = BooleanBuffer(3, 2)
      for y = 1, 2 do
         for x = 1, 3 do
            expect.equal(buf:get(x, y), false)
         end
      end
   end)

   it("sets and gets values correctly (5.1 compat)", function()
      local buf = BooleanBuffer(2, 2)
      buf:set(1, 1, true)
      buf:set(2, 2, true)
      expect.equal(buf:get(1, 1), true)
      expect.equal(buf:get(2, 2), true)
      expect.equal(buf:get(1, 2), false)
      expect.equal(buf:get(2, 1), false)
   end)

   it("clears all values to false (5.1 compat)", function()
      local buf = BooleanBuffer(2, 2)
      buf:set(1, 1, true)
      buf:set(2, 2, true)
      buf:clear()
      for y = 1, 2 do
         for x = 1, 2 do
            expect.equal(buf:get(x, y), false)
         end
      end
   end)

   it("throws on out-of-bounds access (5.1 compat)", function()
      local buf = BooleanBuffer(2, 2)
      local ok = pcall(function()
         buf:get(0, 1)
      end)
      expect.equal(ok, false)
      ok = pcall(function()
         buf:get(1, 3)
      end)
      expect.equal(ok, false)
   end)
end)
