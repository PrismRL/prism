--- @param level Level The level to take opacity information from.
--- @param origin Vector2 The origin point of the fov.
--- @param maxDepth integer The range in tiles the fov will extend from origin.
--- @param callback fun(x: integer, y: integer, cell: Cell) A function called for each visible cell.
local function fov(level, origin, maxDepth, callback)
   callback(origin.x, origin.y, level:getCell(origin.x, origin.y))

   if maxDepth < 1 then return end

   for i = 0, 3 do
      local quadrant = prism.FOV.Quadrant(i, origin)

      local function reveal(x, y)
         local x, y = quadrant:transform(x, y)

         if x < 1 or y < 1 or x > level.map.w or y > level.map.w then return end

         callback(x, y, level:getCell(x, y))
      end

      ---@param row FOV.Row
      ---@param col integer
      local function isSymmetric(row, col)
         local startNum = row.startSlope:tonumber()
         local endNum = row.endSlope:tonumber()
         return (col >= row.depth * startNum) and (col <= row.depth * endNum)
      end

      local function isWall(x, y)
         if not y then return false end
         local x, y = quadrant:transform(x, y)

         if x < 1 or y < 1 or x > level.map.w or y > level.map.w then return true end
         return level:getCellOpaque(x, y)
      end

      local function isFloor(x, y)
         if not y then return false end
         local x, y = quadrant:transform(x, y)

         if x < 1 or y < 1 or x > level.map.w or y > level.map.w then return false end

         return not level:getCellOpaque(x, y)
      end

      local function slope(x, y)
         return prism.FOV.Fraction(2 * y - 1, 2 * x)
      end

      local function scanIterative(row)
         --- @type FOV.Row[]
         local rows = { row }
         while #rows > 0 do
            ---@type FOV.Row
            row = table.remove(rows)

            local px, py
            for x, y in row:eachTile() do
               if isWall(x, y) or isSymmetric(row, y) then reveal(x, y) end
               if isWall(px, py) and isFloor(x, y) then row.startSlope = slope(x, y) end
               if isFloor(px, py) and isWall(x, y) then
                  local nextRow = row:next()
                  nextRow.endSlope = slope(x, y)

                  if nextRow.depth <= maxDepth then table.insert(rows, nextRow) end
               end
               px, py = x, y
            end
            if isFloor(px, py) then
               local nextRow = row:next()
               if nextRow.depth <= maxDepth then table.insert(rows, row:next()) end
            end
         end
      end

      local firstRow = prism.FOV.Row(1, prism.FOV.Fraction(-1), prism.FOV.Fraction(1))
      scanIterative(firstRow)
   end
end

return fov
