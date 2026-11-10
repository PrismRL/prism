--- @class PriorityQueue<T> : Object
--- @overload fun(T): PriorityQueue
local PriorityQueue = prism.Object:extend("PriorityQueue")

function PriorityQueue:__new()
   -- Payloads may be nil; the dense priorities array determines the heap size.
   self._heap = {}
   self._priorities = {}
end

--- Swap elements at indices i and j in the heap
--- @param i integer
--- @param j integer
function PriorityQueue:_swap(i, j)
   self._heap[i], self._heap[j] = self._heap[j], self._heap[i]
   self._priorities[i], self._priorities[j] = self._priorities[j], self._priorities[i]
end

--- Bubble up the element at index i to its proper place in the heap
--- @param i integer
function PriorityQueue:_bubbleUp(i)
   local heap, priorities = self._heap, self._priorities
   local element, priority = heap[i], priorities[i]
   while i > 1 do
      local parent = math.floor(i / 2)
      if priorities[parent] > priority then
         heap[i], priorities[i] = heap[parent], priorities[parent]
         i = parent
      else
         break
      end
   end
   heap[i], priorities[i] = element, priority
end

--- Bubble down the element at index i to its proper place in the heap
--- @param i integer
function PriorityQueue:_bubbleDown(i)
   local heap, priorities = self._heap, self._priorities
   local size = #priorities
   local element, priority = heap[i], priorities[i]
   while 2 * i <= size do
      local child = 2 * i
      local rightChild = child + 1
      if rightChild <= size and priorities[rightChild] < priorities[child] then
         child = rightChild
      end

      if priorities[child] >= priority then break end
      heap[i], priorities[i] = heap[child], priorities[child]
      i = child
   end
   heap[i], priorities[i] = element, priority
end

--- Push a new element to the PriorityQueue.
--- @param data any
--- @param priority integer
function PriorityQueue:push(data, priority)
   -- Keep priorities separate to avoid allocating a wrapper for every push.
   local index = #self._priorities + 1
   self._heap[index] = data
   self._priorities[index] = priority
   self:_bubbleUp(index)
end

--- @generic T
--- @return T|nil
function PriorityQueue:pop()
   if self:isEmpty() then return nil end

   local heap, priorities = self._heap, self._priorities
   local size = #priorities
   local highestPriorityElement = heap[1]
   heap[1], priorities[1] = heap[size], priorities[size]
   heap[size], priorities[size] = nil, nil

   if not self:isEmpty() then self:_bubbleDown(1) end

   return highestPriorityElement
end

function PriorityQueue:isEmpty()
   return #self._priorities == 0
end

function PriorityQueue:size()
   return #self._priorities
end

-- Unit tests

local pq = PriorityQueue()

-- Test pushing to the PriorityQueue
pq:push("a", 3)
assert(pq:size() == 1, "Size should be 1 after one push.")
assert(not pq:isEmpty(), "PriorityQueue should not be empty after one push.")

-- Test multiple push
pq:push("b", 2)
pq:push("c", 1)
assert(pq:size() == 3, "Size should be 3 after three pushes.")
assert(not pq:isEmpty(), "PriorityQueue should not be empty after three pushes.")

-- Test that pop returns the highest priority element
local highestPriorityElement = pq:pop()
assert(highestPriorityElement == "c", "Highest priority element should be 'c'.")
assert(pq:size() == 2, "Size should be 2 after one pop.")

-- Test that pop works correctly with multiple elements
highestPriorityElement = pq:pop()
assert(highestPriorityElement == "b", "Highest priority element should be 'b'.")
assert(pq:size() == 1, "Size should be 1 after two pops.")

highestPriorityElement = pq:pop()
assert(highestPriorityElement == "a", "Highest priority element should be 'a'.")
assert(pq:size() == 0, "Size should be 0 after three pops.")

-- Test that PriorityQueue is empty after all elements are popped
assert(pq:isEmpty(), "PriorityQueue should be empty after all elements are popped.")

-- Test with duplicate priorities
local pq2 = PriorityQueue()
pq2:push("a", 2)
pq2:push("b", 1)
pq2:push("c", 2)
assert(pq2:pop() == "b", "First popped element should be 'b'.")
assert(pq2:size() == 2, "Size should be 2 after one pop.")
local next = pq2:pop()
assert((next == "a" or next == "c"), "Second popped element should be 'a' or 'c'.")
next = pq2:pop()
assert((next == "a" or next == "c"), "Third popped element should be 'a' or 'c'.")

-- Test with large quantities of data
local pq3 = PriorityQueue()
for i = 1, 1000 do
   pq3:push(tostring(i), 1000 - i)
end
assert(pq3:size() == 1000, "Size should be 1000 after 1000 pushes.")
assert(pq3:pop() == "1000", "First popped element should be '1000'.")
assert(pq3:size() == 999, "Size should be 999 after one pop.")
assert(pq3:pop() == "999", "Second popped element should be '999'.")

-- Test with negative priorities
local pq4 = PriorityQueue()
pq4:push("a", -1)
pq4:push("b", -2)
pq4:push("c", -3)
assert(pq4:pop() == "c", "First popped element should be 'c'.")
assert(pq4:pop() == "b", "Second popped element should be 'b'.")
assert(pq4:pop() == "a", "Third popped element should be 'a'.")

return PriorityQueue
