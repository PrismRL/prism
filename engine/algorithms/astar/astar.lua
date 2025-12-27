---@param a Vector2
---@param b Vector2
local function heuristic(a, b)
   return a:distance(b)
end

-- helper function to reconstruct the path
local function reconstructPath(cameFrom, costSoFar, current)
   local path = {}
   local costs = {}

   local last
   while current do
      table.insert(path, 1, current)

      if last then
         local lastCost = costSoFar[last:hash()]
         local cost = costSoFar[current:hash()]
         table.insert(costs, 1, lastCost - cost)
      end

      last = current
      current = cameFrom[current:hash()]
   end

   table.remove(path, 1)
   return prism.Path(path, costs)
end

local function defaultCostCallback(_, _)
   return 1
end

--- Gets a path between two points using A* pathfinding. It is usually preferable to use :lua:func:`Level.findPath`.
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
   frontier:push(start, 0)

   local cameFrom = {} -- [vec] = vec | nil
   local costSoFar = {} -- [vec] = float

   cameFrom[start:hash()] = nil
   costSoFar[start:hash()] = 0

   local final
   local pathFound = false
   while not frontier:isEmpty() do
      local current = frontier:pop()
      --- @cast current Vector2
      if current:getRange(goal, distanceType) <= minDistance then
         final = current
         pathFound = true
         break
      end

      for _, neighborDir in ipairs(neighborhood) do
         local neighbor = current + neighborDir
         --- @cast neighbor Vector2
         if passableCallback(neighbor.x, neighbor.y) then
            local moveCost = costCallback(neighbor.x, neighbor.y)
            local newCost = costSoFar[current:hash()] + moveCost
            if not costSoFar[neighbor:hash()] or newCost < costSoFar[neighbor:hash()] then
               costSoFar[neighbor:hash()] = newCost
               local priority = newCost + heuristic(neighbor, goal)
               frontier:push(neighbor, priority)
               cameFrom[neighbor:hash()] = current
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
