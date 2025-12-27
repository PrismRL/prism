--- Computes a dijkstra map from a list of goal positions.
--- @param goals table<number, Vector2> List of goal positions.
--- @param passableCallback PassableCallback
--- @param neighborhood Neighborhood An optional set of vectors that count as adjacent. Defaults to prism.neighborhood.
--- @return SparseGrid<number> map The Dijkstra map as a SparseGrid where each cell's value is its distance to the nearest goal.
local function dijkstraMap(goals, passableCallback, neighborhood)
   neighborhood = neighborhood or prism.neighborhood
   -- Create the SparseGrid to store distances
   local distances = prism.SparseGrid()

   -- Queue for exploring cells (FIFO for BFS-like behavior)
   local frontier = {}

   -- Initialize frontier with goals
   for _, goal in ipairs(goals) do
      table.insert(frontier, goal)
      distances:set(goal.x, goal.y, 0)
   end

   while #frontier > 0 do
      local current = table.remove(frontier, 1)
      ---@cast current Vector2

      local currentCost = distances:get(current.x, current.y) or math.huge

      for _, neighborDir in ipairs(neighborhood) do
         local neighbor = current + neighborDir
         ---@cast neighbor Vector2

         if passableCallback(neighbor.x, neighbor.y) then
            local existingCost = distances:get(neighbor.x, neighbor.y) or math.huge

            if currentCost + 1 < existingCost then
               distances:set(neighbor.x, neighbor.y, currentCost + 1)
               table.insert(frontier, neighbor)
            end
         end
      end
   end

   return distances
end

return dijkstraMap
