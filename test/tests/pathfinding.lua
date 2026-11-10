require "engine"

local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect
local Vector2 = prism.Vector2

local function passable(x, y)
   return x >= 0 and x <= 4 and y >= 0 and y <= 4
end

describe("Pathfinding", function()
   it("reconstructs long paths with aligned movement costs", function()
      local path = prism.astar(Vector2(0, 0), Vector2(1000, 0), function(x, y)
         return y == 0 and x >= 0 and x <= 1000
      end, function(x, y)
         return x % 3 + 1
      end, 0, "4way", Vector2.neighborhood4)

      expect.equal(path:length(), 1000)
      local cost = 0
      for i, node in ipairs(path:getPath()) do
         expect.equal(node, Vector2(i, 0))
         cost = cost + i % 3 + 1
         expect.equal(path:totalCostAt(i), cost)
      end
      expect.equal(path:getTotalCost(), cost)
   end)

   it("reconstructs negative coordinates and coordinate hash boundaries", function()
      for _, origin in ipairs({ -0x2000000, -5, 0x2000000 - 3 }) do
         local path = prism.astar(
            Vector2(origin, origin),
            Vector2(origin + 2, origin),
            function(x, y)
               return y == origin and x >= origin and x <= origin + 2
            end,
            nil,
            0,
            "4way",
            Vector2.neighborhood4
         )
         expect.equal(path:getPath(), { Vector2(origin + 1, origin), Vector2(origin + 2, origin) })
         expect.equal(path:getTotalCost(), 2)
      end
   end)

   it("keeps scratch vectors private across nested searches and returned paths", function()
      local inner
      local start, goal = Vector2(0, 0), Vector2(4, 0)
      local path = prism.astar(start, goal, function(x, y)
         if not inner then inner = prism.astar(Vector2(4, 4), Vector2(0, 4), passable) end
         return passable(x, y)
      end)
      expect.equal(start, Vector2(0, 0))
      expect.equal(goal, Vector2(4, 0))
      expect.equal(path:getPath(), { Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(4, 0) })
      expect.equal(inner:getPath(), { Vector2(3, 4), Vector2(2, 4), Vector2(1, 4), Vector2(0, 4) })
      path:getPath()[1].x = 99
      expect.equal(path:getPath()[2], Vector2(2, 0))
      expect.equal(inner:getPath()[1], Vector2(3, 4))
   end)

   it("uses the requested distance metric with scratch vectors", function()
      for _, distance in ipairs({ "4way", "8way", "manhattan", "chebyshev", "euclidean" }) do
         local goal = Vector2(4, 4)
         local path = prism.astar(Vector2(0, 0), goal, passable, nil, 2, distance)
         local nodes = path:getPath()
         expect.truthy(nodes[#nodes]:getRange(goal, distance) <= 2)
         expect.truthy(nodes[#nodes - 1]:getRange(goal, distance) > 2)
      end
   end)

   it("finds a cheaper detour around expensive cells", function()
      local path = prism.astar(Vector2(0, 0), Vector2(4, 0), passable, function(x, y)
         return y == 0 and x > 0 and x < 4 and 20 or 1
      end, 0, "4way", Vector2.neighborhood4)

      expect.equal(path:getTotalCost(), 6)
      expect.equal(path:getPath()[path:length()], Vector2(4, 0))
   end)

   it("returns nil for unreachable goals and starts already in range", function()
      expect.equal(
         prism.astar(Vector2(0, 0), Vector2(4, 0), function()
            return false
         end),
         nil
      )
      expect.equal(prism.astar(Vector2(0, 0), Vector2(0, 0), passable), nil)
      expect.equal(prism.astar(Vector2(0, 0), Vector2(1, 0), passable, nil, 1), nil)
   end)

   it("stops at the requested distance", function()
      local path = prism.astar(Vector2(0, 0), Vector2(4, 0), passable, nil, 2, "4way")
      expect.equal(path:getPath()[path:length()]:getRange(Vector2(4, 0), "4way"), 2)
   end)

   it("computes distances from multiple goals", function()
      local distances =
         prism.dijkstra({ Vector2(0, 0), Vector2(4, 4) }, passable, Vector2.neighborhood4)
      for x = 0, 4 do
         for y = 0, 4 do
            expect.equal(distances:get(x, y), math.min(x + y, 8 - x - y))
         end
      end
      expect.equal(distances:get(5, 0), nil)
   end)

   it("supports nested breadth-first searches with pooled entries", function()
      local count = 0
      prism.breadthFirstSearch(Vector2(0, 0), passable, function(x, y, depth)
         expect.equal(depth, math.max(x, y))
         local innerCount = 0
         prism.breadthFirstSearch(Vector2(4, 4), passable, function(ix, iy, innerDepth)
            expect.equal(innerDepth, math.max(4 - ix, 4 - iy))
            innerCount = innerCount + 1
         end)
         expect.equal(innerCount, 25)
         count = count + 1
      end)
      expect.equal(count, 25)
   end)

   it("visits each reachable cell once in breadth-first order", function()
      local visited = prism.SparseGrid()
      local lastDepth = 0
      local count = 0
      prism.breadthFirstSearch(Vector2(0, 0), passable, function(x, y, depth)
         expect.falsy(visited:get(x, y))
         expect.truthy(depth >= lastDepth)
         expect.equal(depth, math.max(x, y))
         visited:set(x, y, true)
         lastDepth = depth
         count = count + 1
      end)
      expect.equal(count, 25)
   end)
end)
