---@param start Vector2 The starting position.
---@param passableCallback PassableCallback A callback to determine if a position is passable.
---@param callback fun(x: number, y: number) A callback function called for each visited cell.
local function bfs(start, passableCallback, callback, neighborhood)
   neighborhood = neighborhood or prism.neighborhood
   -- Queue for exploring cells (FIFO for BFS behavior)
   local frontier = { start }

   -- Set to track visited cells
   local visited = prism.SparseGrid()

   -- Mark the start position as visited
   visited:set(start.x, start.y, true)
   callback(start.x, start.y)

   while #frontier > 0 do
      local current = table.remove(frontier, 1)
      ---@cast current Vector2

      for _, neighborDir in ipairs(prism.neighborhood) do
         local neighbor = current + neighborDir
         ---@cast neighbor Vector2

         local nx, ny = neighbor.x, neighbor.y
         if not visited:get(nx, ny) and passableCallback(nx, ny) then
            visited:set(nx, ny, true)
            callback(nx, ny)
            table.insert(frontier, neighbor)
         end
      end
   end
end

return bfs
