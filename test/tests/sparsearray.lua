require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

-- Adjust this require path to wherever your SparseArray module lives.
local SparseArray = prism.SparseArray

describe("SparseArray", function()

   it("starts empty", function()
      local sa = SparseArray()

      --- @diagnostic disable-next-line
      expect.equal(sa.maxIndex, 0)

      local iter = sa:pairs()
      local h, v = iter()
      expect.falsy(h)
      expect.falsy(v)
   end)

   it("adds and retrieves a single item", function()
      local sa = SparseArray()
      local handle = sa:add("hello")
      expect.truthy(handle)

      local v = sa:get(handle)
      expect.equal(v, "hello")
   end)

   it("add returns distinct handles for different items", function()
      local sa = SparseArray()
      local h1 = sa:add("a")
      local h2 = sa:add("b")

      expect.truthy(h1 ~= h2)
      expect.equal(sa:get(h1), "a")
      expect.equal(sa:get(h2), "b")
   end)

   it("removes item and returns it", function()
      local sa = SparseArray()
      local h = sa:add("value")
      local removed = sa:remove(h)

      expect.equal(removed, "value")
      expect.falsy(sa:get(h))
   end)

   it("removing with stale handle does nothing and returns nil", function()
      local sa = SparseArray()
      local h1 = sa:add("first")
      sa:remove(h1) -- increments generation at index
      local removed = sa:remove(h1)
      expect.falsy(removed)
   end)

   it("reuses freed indices and increments generation", function()
      local sa = SparseArray()

      local h1 = sa:add("first")
      local removed = sa:remove(h1)
      expect.equal(removed, "first")

      local h2 = sa:add("second")

      expect.truthy(h1 ~= h2)

      expect.falsy(sa:get(h1))

      expect.equal(sa:get(h2), "second")
   end)

   it("does not push maxIndex slot into freeIndices; instead shrinks maxIndex", function()
      local sa = SparseArray()
      local h1 = sa:add("a") -- index 1
      local h2 = sa:add("b") -- index 2 (maxIndex)

      sa:remove(h2)

      --- @diagnostic disable-next-line
      expect.equal(sa.maxIndex, 1)

      local h3 = sa:add("c")

      expect.truthy(h3 ~= h2)
      expect.equal(sa:get(h3), "c")
      expect.equal(sa:get(h1), "a")
   end)

   it("freeIndices are used when removing non-terminal slots", function()
      local sa = SparseArray()

      sa:add("a") -- index 1
      local h2 = sa:add("b") -- index 2
      sa:add("c") -- index 3

      sa:remove(h2)

      local h4 = sa:add("d")
      local v4 = sa:get(h4)

      expect.equal(v4, "d")
      expect.falsy(sa:get(h2))
   end)

   it("get returns nil for invalid handle", function()
      local sa = SparseArray()
      local bogus = 2^32 + 123
      expect.falsy(sa:get(bogus))
   end)

   it("clear resets internal state", function()
      local sa = SparseArray()
      local h1 = sa:add("a")
      local h2 = sa:add("b")

      sa:clear()

      --- @diagnostic disable-next-line
      expect.equal(sa.maxIndex, 0)
      expect.falsy(sa:get(h1))
      expect.falsy(sa:get(h2))

      -- After clear, new items should start from a fresh state
      local h3 = sa:add("c")
      expect.truthy(h3)
      expect.equal(sa:get(h3), "c")
   end)

   it("pairs iterates over live items only", function()
      local sa = SparseArray()
      sa:add("a") -- 1
      local h2 = sa:add("b") -- 2
      sa:add("c") -- 3

      -- Remove middle
      sa:remove(h2)

      local seen = {}
      for handle, value in sa:pairs() do
         table.insert(seen, { handle = handle, value = value })
      end

      -- Should only see "a" and "c"
      local values = {}
      for _, entry in ipairs(seen) do
         table.insert(values, entry.value)
      end

      table.sort(values)
      expect.equal(#values, 2)
      expect.equal(values[1], "a")
      expect.equal(values[2], "c")
   end)
end)