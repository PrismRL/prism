-- Run from the repository root with LuaJIT:
-- luajit test/benchmarks/pathfinding.lua [source-root] [results-prefix]
-- Use an unchanged checkout as source-root to measure the baseline in a separate process.
-- Each CSV row aggregates 48 searches across 12 seeded maps. Path output can be compared
-- byte-for-byte between runs to check behavior separately from timing.
local source = arg[1] or "."
local prefix = arg[2] or "/tmp/prism-pathfinding"
local function load(path)
   return dofile(source .. "/engine/" .. path .. ".lua")
end

prism = {}
prism.Object = load "core/object"
prism.Vector2 = load "math/vector"
prism.PriorityQueue = load "structures/priority_queue"
prism.Path = load "algorithms/astar/path"
prism.neighborhood = prism.Vector2.neighborhood8
prism._defaultDistance = "8way"
local astar = load "algorithms/astar/astar"
local Vector2 = prism.Vector2

local function randomGenerator(seed)
   return function(limit)
      seed = seed * 16807 % 2147483647
      return seed % limit + 1
   end
end

local function makeCases(kind, size, seed)
   local random = randomGenerator(seed)
   local cells, costs = {}, {}
   for y = 1, size do
      cells[y], costs[y] = {}, {}
      for x = 1, size do
         local roll = random(100)
         cells[y][x] = kind ~= "sparse" and kind ~= "dense"
            or roll > (kind == "sparse" and 20 or 35)
         costs[y][x] = kind == "weighted" and random(9) or 1
      end
   end

   if kind == "maze" then
      -- Alternating gaps in walls force winding routes of different lengths.
      for x = 4, size - 1, 4 do
         local gap = random(math.max(1, math.floor(size / 4)))
         if x % 8 == 0 then gap = size - gap + 1 end
         for y = 1, size do
            cells[y][x] = y == gap
         end
      end
   elseif kind == "disconnected" then
      for y = 1, size do
         cells[y][math.floor(size / 2)] = false
      end
   end

   local points = {
      { 1, 1, math.min(size, 5), math.min(size, 4) },
      { random(size), random(size), random(size), random(size) },
      { 1, 1, size, size },
      { 1, size, size, 1 },
   }
   local cases = {}
   for i, point in ipairs(points) do
      local sx, sy, gx, gy = unpack(point)
      cells[sy][sx], cells[gy][gx] = true, true
      cases[i] = {
         start = Vector2(sx, sy),
         goal = Vector2(gx, gy),
         passable = function(x, y)
            return cells[y] and cells[y][x] or false
         end,
         cost = kind == "weighted" and function(x, y)
            return costs[y][x]
         end or nil,
         minDistance = i == 4 and 2 or 0,
         neighborhood = seed % 2 == 0 and Vector2.neighborhood4 or Vector2.neighborhood8,
      }
   end
   return cases
end

local function search(case)
   return astar(
      case.start,
      case.goal,
      case.passable,
      case.cost,
      case.minDistance,
      "4way",
      case.neighborhood
   )
end

local output = assert(io.open(prefix .. ".csv", "w"))
local paths = assert(io.open(prefix .. ".paths", "w"))
output:write("kind,size,queries,found,median_ms,min_ms,max_ms,allocated_kib\n")
for _, kind in ipairs({ "open", "sparse", "dense", "maze", "weighted", "disconnected" }) do
   for _, size in ipairs({ 24, 48, 96 }) do
      local cases = {}
      for seed = 1, 12 do
         for _, case in ipairs(makeCases(kind, size, seed)) do
            cases[#cases + 1] = case
         end
      end

      local found = 0
      for index, case in ipairs(cases) do
         local path = search(case)
         paths:write(kind, ",", size, ",", index, ":")
         if path then
            found = found + 1
            for i, node in ipairs(path:getPath()) do
               paths:write(node.x, ",", node.y, ",", path:totalCostAt(i), ";")
            end
         else
            paths:write("nil")
         end
         paths:write("\n")
      end

      -- Warm the JIT before measuring; keep normal garbage collection during timings.
      for warmup = 1, 3 do
         for _, case in ipairs(cases) do
            search(case)
         end
      end
      local times = {}
      for batch = 1, 5 do
         collectgarbage("collect")
         local start = os.clock()
         for _, case in ipairs(cases) do
            search(case)
         end
         times[batch] = (os.clock() - start) * 1000
      end
      table.sort(times)

      -- With collection stopped, growth measures allocated bytes, not retained memory.
      local allocated = 0
      for _, case in ipairs(cases) do
         collectgarbage("collect")
         collectgarbage("stop")
         local before = collectgarbage("count")
         search(case)
         allocated = allocated + collectgarbage("count") - before
         collectgarbage("restart")
      end
      output:write(
         string.format(
            "%s,%d,%d,%d,%.6f,%.6f,%.6f,%.3f\n",
            kind,
            size,
            #cases,
            found,
            times[3],
            times[1],
            times[5],
            allocated
         )
      )
      output:flush()
      print(string.format("%s %dx%d: %d searches, %.2f ms", kind, size, size, #cases, times[3]))
      io.flush()
   end
end
output:close()
paths:close()
