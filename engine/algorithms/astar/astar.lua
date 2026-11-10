---@param a Vector2
---@param b Vector2
local function heuristic(a, b)
   return a:distance(b)
end

-- helper function to reconstruct the path
local function reconstructPath(cameFrom, costSoFar, currentHash)
   local path = {}
   local costs = {}

   local parent = cameFrom[currentHash]
   while parent do
      path[#path + 1] = prism.Vector2.unhash(currentHash)
      costs[#costs + 1] = costSoFar[currentHash] - costSoFar[parent]
      currentHash = parent
      parent = cameFrom[currentHash]
   end

   -- Reverse once instead of shifting the arrays for every step.
   for i = 1, math.floor(#path / 2) do
      local j = #path - i + 1
      path[i], path[j] = path[j], path[i]
      costs[i], costs[j] = costs[j], costs[i]
   end

   return prism.Path(path, costs)
end

local function defaultCostCallback(_, _)
   return 1
end

--- Gets a path between two points using A* pathfinding. It is usually preferable to use :lua:func:`Level.findPath`.
--- Search positions must use integer grid coordinates within Vector2's hash range:
--- [-2^25, 2^25 - 1] on each axis.
--- @param start Vector2 The starting position.
--- @param goal Vector2 The goal position.
--- @param passableCallback PassableCallback A callback for determining passability.
--- @param costCallback? CostCallback An optional callback for determning costs.
--- @param minDistance? integer A minimum distance to be away from the goal. Defaults to zero.
--- @param distanceType? DistanceType An optional distance type to use for calculating the minimum distance. Defaults to prism._defaultDistance.
--- @param neighborhood? Neighborhood A set of vectors that count as adjacent. Defaults to prism.neighborhood.
---@return Path? path A path to the goal, or nil if a path could not be found or the start is already at the minimum distance.
local function astarSearch(
   start,
   goal,
   passableCallback,
   costCallback,
   minDistance,
   distanceType,
   neighborhood
)
   minDistance = minDistance or 0
   costCallback = costCallback or defaultCostCallback
   distanceType = distanceType or prism._defaultDistance
   neighborhood = neighborhood or prism.neighborhood

   local frontier = prism.PriorityQueue()
   local startHash = start:hash()
   frontier:push(startHash, 0)

   local cameFrom = {} -- [hash] = parent hash
   local costSoFar = {} -- [hash] = float

   costSoFar[startHash] = 0

   -- Search with coordinate hashes and reuse two scratch vectors.
   -- Persistent vectors are only needed when reconstructing the returned path.
   local current = prism.Vector2()
   local neighbor = prism.Vector2()
   local final
   local pathFound = false
   while not frontier:isEmpty() do
      local currentHash = frontier:pop()
      current.x, current.y = prism.Vector2._unhash(currentHash)
      if current:getRange(goal, distanceType) <= minDistance then
         final = currentHash
         pathFound = true
         break
      end

      local currentCost = costSoFar[currentHash]
      for _, neighborDir in ipairs(neighborhood) do
         local nx, ny = current.x + neighborDir.x, current.y + neighborDir.y
         if passableCallback(nx, ny) then
            local moveCost = costCallback(nx, ny)
            local newCost = currentCost + moveCost
            local neighborHash = prism.Vector2._hash(nx, ny)
            local existingCost = costSoFar[neighborHash]
            if not existingCost or newCost < existingCost then
               neighbor.x, neighbor.y = nx, ny
               costSoFar[neighborHash] = newCost
               local priority = newCost + heuristic(neighbor, goal)
               frontier:push(neighborHash, priority)
               cameFrom[neighborHash] = currentHash
            end
         end
      end
   end

   if pathFound then
      local path = reconstructPath(cameFrom, costSoFar, final)
      return path:length() > 0 and path or nil
   end
end

return astarSearch
