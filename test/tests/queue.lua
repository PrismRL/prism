require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local Queue = prism.Queue

describe("Queue", function()

   it("starts empty", function()
      local q = Queue()
      expect.truthy(q:empty())
      expect.equal(q:size(), 0)
      expect.equal(q:peek(), nil)
      expect.equal(q:pop(), nil)
   end)

   it("push makes it non-empty and size updates", function()
      local q = Queue()
      q:push(1)
      expect.falsy(q:empty())
      expect.equal(q:size(), 1)
      expect.equal(q:peek(), 1)
   end)

   it("pop returns pushed value and makes empty again", function()
      local q = Queue()
      q:push(1)
      local v = q:pop()
      expect.equal(v, 1)
      expect.truthy(q:empty())
      expect.equal(q:size(), 0)
   end)

   it("peek does not remove element", function()
      local q = Queue()
      q:push(2)
      q:push(3)
      local v = q:peek()
      expect.equal(v, 2)
      expect.equal(q:size(), 2)
      expect.falsy(q:empty())
   end)

   it("preserves FIFO order", function()
      local q = Queue()
      local testData = { 5, 2, 8, 9, 1, 3, 7, 6, 4 }
      for _, v in ipairs(testData) do
         q:push(v)
      end

      for _, v in ipairs(testData) do
         expect.equal(q:pop(), v)
      end

      expect.truthy(q:empty())
      expect.equal(q:size(), 0)
   end)

   it("handles interleaved pushes and pops", function()
      local q = Queue()
      q:push(1)
      expect.equal(q:pop(), 1)
      expect.truthy(q:empty())

      q:push(2)
      q:push(3)
      expect.equal(q:pop(), 2)
      expect.equal(q:size(), 1)

      q:push(4)
      expect.equal(q:pop(), 3)
      expect.equal(q:pop(), 4)
      expect.truthy(q:empty())
   end)

   it("clear empties queue", function()
      local q = Queue()
      q:push(1)
      q:push(2)
      q:clear()
      expect.truthy(q:empty())
      expect.equal(q:size(), 0)
      expect.equal(q:peek(), nil)
      expect.equal(q:pop(), nil)
   end)

   it("contains checks membership correctly", function()
      local q = Queue()
      q:push(5)
      q:push(10)
      q:push(15)

      expect.truthy(q:contains(10))
      expect.truthy(q:contains(5))
      expect.truthy(q:contains(15))
      expect.falsy(q:contains(20))

      expect.equal(q:size(), 3)
   end)

   it("remove deletes first occurrence and shifts correctly", function()
      local q = Queue()
      q:push(1)
      q:push(2)
      q:push(3)
      q:push(2)

      local removed = q:remove(2)
      expect.truthy(removed)
      expect.equal(q:size(), 3)
      expect.equal(q:pop(), 1)
      expect.equal(q:pop(), 3)
      expect.equal(q:pop(), 2)
      expect.truthy(q:empty())
   end)

   it("remove returns false if value not present", function()
      local q = Queue()
      q:push(1)
      q:push(2)
      expect.falsy(q:remove(3))
      expect.equal(q:size(), 2)
   end)

end)
