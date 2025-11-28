require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local CascadingBitmaskBuffer = prism.CascadingBitmaskBuffer

describe("CascadingBitmaskBuffer", function()
   it("initializes cascade buffers with correct dimensions", function()
      local w, h, levels = 4, 4, 3
      local cbb = CascadingBitmaskBuffer(w, h, levels)
      expect.equal(#cbb.cascade, levels)
      for i = 1, levels do
         expect.equal(cbb.cascade[i].w, w)
         expect.equal(cbb.cascade[i].h, h)
      end
   end)

   it("sets and gets mask values at level 1", function()
      local cbb = CascadingBitmaskBuffer(3, 3, 2)
      cbb:setMask(2, 2, 1)
      expect.equal(cbb:getMask(2, 2, 1), 1)
      expect.equal(cbb.cascade[1]:getMask(2, 2), 1)
   end)

   it("cascades mask values to higher levels", function()
      local cbb = CascadingBitmaskBuffer(2, 2, 2)
      cbb:setMask(1, 1, 1)
      cbb:setMask(2, 1, 1)
      cbb:setMask(1, 2, 1)
      cbb:setMask(2, 2, 1)
      expect.equal(cbb:getMask(1, 1, 2), 1)
   end)

   it("throws error for out-of-bounds getMask", function()
      local cbb = CascadingBitmaskBuffer(2, 2, 2)
      local ok, err = pcall(function()
         cbb:getMask(3, 3, 1)
      end)
      expect.falsy(ok)
      --- @diagnostic disable-next-line
      expect.truthy(err:match("Index out of bounds"))
   end)

   it("throws error for invalid cascade level", function()
      local cbb = CascadingBitmaskBuffer(2, 2, 2)
      local ok, err = pcall(function()
         cbb:getCascadeLevel(0)
      end)
      expect.falsy(ok)
      --- @diagnostic disable-next-line
      expect.truthy(err:match("Cascade level out of range"))
   end)

   local req = require
   require = function(pkg)
      if pkg == "ffi" then return nil end
      return req(pkg)
   end

   package.loaded["engine.structures.cascadingbitmaskbuffer"] = nil
   package.loaded["bit"] = require("engine.lib.bit")
   prism._OBJECTREGISTRY["CascadingBitmaskBuffer"] = nil
   BooleanBuffer = require "engine.structures.cascadingbitmaskbuffer"
   require = req

   it("initializes cascade buffers with correct dimensions (5.1 compat)", function()
      local w, h, levels = 4, 4, 3
      local cbb = CascadingBitmaskBuffer(w, h, levels)
      expect.equal(#cbb.cascade, levels)
      for i = 1, levels do
         expect.equal(cbb.cascade[i].w, w)
         expect.equal(cbb.cascade[i].h, h)
      end
   end)

   it("sets and gets mask values at level 1 (5.1 compat)", function()
      local cbb = CascadingBitmaskBuffer(3, 3, 2)
      cbb:setMask(2, 2, 1)
      expect.equal(cbb:getMask(2, 2, 1), 1)
      expect.equal(cbb.cascade[1]:getMask(2, 2), 1)
   end)

   it("cascades mask values to higher levels (5.1 compat)", function()
      local cbb = CascadingBitmaskBuffer(2, 2, 2)
      cbb:setMask(1, 1, 1)
      cbb:setMask(2, 1, 1)
      cbb:setMask(1, 2, 1)
      cbb:setMask(2, 2, 1)
      expect.equal(cbb:getMask(1, 1, 2), 1)
   end)

   it("throws error for out-of-bounds getMask (5.1 compat)", function()
      local cbb = CascadingBitmaskBuffer(2, 2, 2)
      local ok, err = pcall(function()
         cbb:getMask(3, 3, 1)
      end)
      expect.falsy(ok)
      --- @diagnostic disable-next-line
      expect.truthy(err:match("Index out of bounds"))
   end)

   it("throws error for invalid cascade level (5.1 compat)", function()
      local cbb = CascadingBitmaskBuffer(2, 2, 2)
      local ok, err = pcall(function()
         cbb:getCascadeLevel(0)
      end)
      expect.falsy(ok)
      --- @diagnostic disable-next-line
      expect.truthy(err:match("Cascade level out of range"))
   end)
end)
