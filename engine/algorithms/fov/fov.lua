--- @param level Level The level to take opacity information from.
--- @param origin Vector2 The origin point of the fov.
--- @param maxDepth integer The range in tiles the fov will extend from origin.
--- @param callback fun(x: integer, y: integer, cell: Cell)
local function fov(level, origin, maxDepth, callback)
   local getCell, getOpaque = level.getCell, level.getCellOpaque
   local ox, oy = origin.x, origin.y
   callback(ox, oy, getCell(level, ox, oy))
   if maxDepth < 1 then return end

   local width, height = level.map.w, level.map.h
   -- Pending sectors use five numeric slots: depth, start numerator/denominator,
   -- end numerator/denominator. Each invocation owns its stack for reentrant callbacks.
   local pending = {}
   local top = 0

   for quadrant = 0, 3 do
      local dx, dy, cx, cy
      if quadrant == 0 then
         dx, dy, cx, cy = 0, -1, 1, 0
      elseif quadrant == 1 then
         dx, dy, cx, cy = 1, 0, 0, 1
      elseif quadrant == 2 then
         dx, dy, cx, cy = 0, 1, 1, 0
      else
         dx, dy, cx, cy = -1, 0, 0, 1
      end

      local depth = 1
      local startNum, startDen, endNum, endDen = -1, 1, 1, 1
      while true do
         -- Keep the rational slopes until rounding to preserve half-tile ties.
         local mincol = math.floor(startNum * depth / startDen + 0.5)
         local maxcol = math.ceil(endNum * depth / endDen - 0.5)
         local startBound = depth * (startNum / startDen)
         local endBound = depth * (endNum / endDen)
         local baseX, baseY = ox + depth * dx, oy + depth * dy
         local canAdvance = depth + 1 <= maxDepth
         -- nil distinguishes the first tile from a floor or wall transition.
         local previousWall

         for col = mincol, maxcol do
            local x, y = baseX + col * cx, baseY + col * cy
            local inBounds = x >= 1 and y >= 1 and x <= width and y <= height
            local wall = not inBounds or getOpaque(level, x, y)

            if inBounds and (wall or (col >= startBound and col <= endBound)) then
               callback(x, y, getCell(level, x, y))
            end

            if previousWall == true and not wall then
               startNum, startDen = 2 * col - 1, 2 * depth
               startBound = depth * (startNum / startDen)
            elseif previousWall == false and wall and canAdvance then
               pending[top + 1], pending[top + 2], pending[top + 3], pending[top + 4], pending[top + 5] =
                  depth + 1, startNum, startDen, 2 * col - 1, 2 * depth
               top = top + 5
            end
            previousWall = wall
         end

         if previousWall == false and canAdvance then
            -- Continue directly; earlier splits remain on the stack in scan order.
            depth = depth + 1
         elseif top > 0 then
            depth, startNum, startDen, endNum, endDen =
               pending[top - 4], pending[top - 3], pending[top - 2], pending[top - 1], pending[top]
            top = top - 5
         else
            break
         end
      end
   end
end

return fov
