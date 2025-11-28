require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local BitmaskBuffer = prism.BitmaskBuffer

describe("BitmaskBuffer", function()
   it("sets and gets bits correctly", function()
      local buf = BitmaskBuffer(2, 2)
      buf:setBit(1, 1, 3, true)
      expect.truthy(buf:getBit(1, 1, 3))
      buf:setBit(1, 1, 3, false)
      expect.falsy(buf:getBit(1, 1, 3))
   end)

   it("sets and gets mask values", function()
      local buf = BitmaskBuffer(2, 2)
      buf:setMask(2, 2, 0xFFFF)
      expect.equal(buf:getMask(2, 2), 0xFFFF)
      buf:setMask(2, 2, 0x1234)
      expect.equal(buf:getMask(2, 2), 0x1234)
   end)

   it("clears the buffer", function()
      local buf = BitmaskBuffer(2, 2)
      buf:setMask(1, 1, 0xFFFF)
      buf:setMask(2, 2, 0xFFFF)
      buf:clear()
      expect.equal(buf:getMask(1, 1), 0)
      expect.equal(buf:getMask(2, 2), 0)
   end)

   it("throws on out-of-bounds access", function()
      local buf = BitmaskBuffer(2, 2)
      local ok, err = pcall(function()
         buf:getBit(3, 1, 0)
      end)
      expect.falsy(ok)
      --- @diagnostic disable-next-line
      expect.truthy(err:match("Index out of bounds"))
   end)

   local req = require
   require = function(pkg)
      if pkg == "ffi" then return nil end
      return req(pkg)
   end

   package.loaded["engine.structures.bitmaskbuffer"] = nil
   package.loaded["bit"] = require("engine.lib.bit")
   prism._OBJECTREGISTRY["BitmaskBuffer"] = nil
   BitmaskBuffer = require "engine.structures.bitmaskbuffer"
   require = req

   it("sets and gets bits correctly (5.1 compat)", function()
      local buf = BitmaskBuffer(2, 2)
      buf:setBit(1, 1, 3, true)
      expect.truthy(buf:getBit(1, 1, 3))
      buf:setBit(1, 1, 3, false)
      expect.falsy(buf:getBit(1, 1, 3))
   end)

   it("sets and gets mask values (5.1 compat)", function()
      local buf = BitmaskBuffer(2, 2)
      buf:setMask(2, 2, 0xFFFF)
      expect.equal(buf:getMask(2, 2), 0xFFFF)
      buf:setMask(2, 2, 0x1234)
      expect.equal(buf:getMask(2, 2), 0x1234)
   end)

   it("clears the buffer (5.1 compat)", function()
      local buf = BitmaskBuffer(2, 2)
      buf:setMask(1, 1, 0xFFFF)
      buf:setMask(2, 2, 0xFFFF)
      buf:clear()
      expect.equal(buf:getMask(1, 1), 0)
      expect.equal(buf:getMask(2, 2), 0)
   end)

   it("throws on out-of-bounds access (5.1 compat)", function()
      local buf = BitmaskBuffer(2, 2)
      local ok, err = pcall(function()
         buf:getBit(3, 1, 0)
      end)
      expect.falsy(ok)
      --- @diagnostic disable-next-line
      expect.truthy(err:match("Index out of bounds"))
   end)
end)
