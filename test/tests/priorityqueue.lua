require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local PriorityQueue = prism.PriorityQueue

describe("PriorityQueue", function()
   it("starts empty", function()
      local pq = PriorityQueue()
      expect.truthy(pq:isEmpty())
      expect.equal(pq:size(), 0)
   end)

   it("push adds elements and updates size", function()
      local pq = PriorityQueue()
      pq:push("a", 3)
      expect.falsy(pq:isEmpty())
      expect.equal(pq:size(), 1)

      pq:push("b", 2)
      pq:push("c", 1)
      expect.equal(pq:size(), 3)
   end)

   it("pop returns elements in priority order", function()
      local pq = PriorityQueue()
      pq:push("a", 3)
      pq:push("b", 2)
      pq:push("c", 1)

      local v1 = pq:pop()
      local v2 = pq:pop()
      local v3 = pq:pop()

      expect.equal(v1, "c")
      expect.equal(v2, "b")
      expect.equal(v3, "a")
      expect.truthy(pq:isEmpty())
      expect.equal(pq:pop(), nil)
   end)

   it("handles duplicate priorities", function()
      local pq = PriorityQueue()
      pq:push("a", 2)
      pq:push("b", 1)
      pq:push("c", 2)

      local v1 = pq:pop()
      expect.equal(v1, "b")
      expect.equal(pq:size(), 2)

      local v2 = pq:pop()
      local v3 = pq:pop()

      expect.truthy((v2 == "a" and v3 == "c") or (v2 == "c" and v3 == "a"))
      expect.truthy(pq:isEmpty())
   end)

   it("handles many elements correctly", function()
      local pq = PriorityQueue()
      for i = 1, 1000 do
         pq:push(tostring(i), 1000 - i)
      end

      expect.equal(pq:size(), 1000)

      local first = pq:pop()
      local second = pq:pop()

      expect.equal(first, "1000")
      expect.equal(second, "999")
      expect.equal(pq:size(), 998)
   end)

   it("supports negative priorities", function()
      local pq = PriorityQueue()
      pq:push("a", -1)
      pq:push("b", -2)
      pq:push("c", -3)

      local v1 = pq:pop()
      local v2 = pq:pop()
      local v3 = pq:pop()

      expect.equal(v1, "c")
      expect.equal(v2, "b")
      expect.equal(v3, "a")
      expect.truthy(pq:isEmpty())
   end)

   it("pop on empty returns nil and leaves size zero", function()
      local pq = PriorityQueue()
      expect.truthy(pq:isEmpty())
      expect.equal(pq:size(), 0)
      expect.equal(pq:pop(), nil)
      expect.equal(pq:size(), 0)
   end)
end)
