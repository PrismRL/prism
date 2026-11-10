----------------------------------------------------------------
-- hoisted pool for BFS frontier entries
----------------------------------------------------------------
local _frontierPool = {}

local function allocEntry(x, y, depth)
   local t = _frontierPool[#_frontierPool]
   if t then
      _frontierPool[#_frontierPool] = nil
      t[1], t[2], t[3] = x, y, depth
      return t
   end
   return { x, y, depth }
end

local function freeEntry(t)
   t[1], t[2], t[3] = nil, nil, nil
   _frontierPool[#_frontierPool + 1] = t
end

--- @alias BFSPassableCallback fun(x: integer, y: integer, depth: integer): boolean

--- Computes a breadth first search from the given starting position.
--- @param start Vector2 The starting position.
--- @param passableCallback BFSPassableCallback A callback to determine if a position is passable.
--- @param callback fun(x: number, y: number, depth: integer) A callback function called for each visited cell.
--- @param neighborhood? Neighborhood An optional set of vectors that count as adjacent. Defaults to prism.neighborhood.
local function bfs(start, passableCallback, callback, neighborhood)
   neighborhood = neighborhood or prism.neighborhood

   local frontier = prism.Queue()
   frontier:push(allocEntry(start.x, start.y, 0))
   local visited = prism.SparseGrid()

   visited:set(start.x, start.y, true)
   callback(start.x, start.y, 0)

   while not frontier:empty() do
      local entry = frontier:pop()
      local x, y, depth = entry[1], entry[2], entry[3]
      freeEntry(entry)

      for _, neighborDir in ipairs(prism.neighborhood) do
         local nx, ny = x + neighborDir.x, y + neighborDir.y

         local nextDepth = depth + 1

         if not visited:get(nx, ny) and passableCallback(nx, ny, nextDepth) then
            visited:set(nx, ny, true)
            callback(nx, ny, nextDepth)
            frontier:push(allocEntry(nx, ny, nextDepth))
         end
      end
   end
end

return bfs
