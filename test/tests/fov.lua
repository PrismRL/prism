local lester = require "test.lester"
local describe, it, expect = lester.describe, lester.it, lester.expect

local function makeLevel(width, height, walls)
   local level = { map = { w = width, h = height }, opacityReads = 0 }
   local function key(x, y)
      assert(x >= 1 and x <= width and y >= 1 and y <= height, "Out of bounds FOV access")
      return x .. "," .. y
   end
   function level:getCell(x, y)
      return key(x, y)
   end
   function level:getCellOpaque(x, y)
      self.opacityReads = self.opacityReads + 1
      return (walls or {})[key(x, y)] == true
   end
   return level
end

local function visible(level, x, y, range)
   local cells = {}
   prism.computeFOV(level, { x = x, y = y }, range, function(cx, cy, cell)
      expect.equal(cell, cx .. "," .. cy)
      cells[cell] = true
   end)
   return cells
end

describe("FOV", function()
   it("reveals only the origin for zero or negative range", function()
      local level = makeLevel(7, 7)
      for _, range in ipairs { 0, -1 } do
         expect.equal(visible(level, 4, 4, range), { ["4,4"] = true })
      end
      expect.equal(level.opacityReads, 0)
   end)

   it("reveals open tiles within the square range on rectangular maps", function()
      for _, size in ipairs { { 5, 11 }, { 11, 5 } } do
         local level = makeLevel(size[1], size[2])
         for _, origin in ipairs { { 1, 1 }, { 3, 3 }, { size[1], size[2] } } do
            local seen = visible(level, origin[1], origin[2], 4)
            for y = 1, size[2] do
               for x = 1, size[1] do
                  local inRange = math.max(math.abs(x - origin[1]), math.abs(y - origin[2])) <= 4
                  expect.equal(seen[x .. "," .. y] == true, inRange)
               end
            end
         end
      end
   end)

   it("reveals a wall and hides tiles behind it in all four directions", function()
      local walls = { ["4,3"] = true, ["5,4"] = true, ["4,5"] = true, ["3,4"] = true }
      local seen = visible(makeLevel(7, 7, walls), 4, 4, 3)
      for wall in pairs(walls) do
         expect.truthy(seen[wall])
      end
      for _, hidden in ipairs { "4,2", "6,4", "4,6", "2,4" } do
         expect.falsy(seen[hidden])
      end
   end)

   it("stops scanning when the origin is enclosed", function()
      local walls = {}
      for y = 2, 4 do
         for x = 2, 4 do
            if x ~= 3 or y ~= 3 then walls[x .. "," .. y] = true end
         end
      end
      local level = makeLevel(5, 5, walls)
      local seen = visible(level, 3, 3, 20)
      local count = 0
      for _ in pairs(seen) do
         count = count + 1
      end
      expect.equal(count, 9)
      expect.equal(level.opacityReads, 12)
   end)

   it("allows nested scans from a visibility callback", function()
      local level = makeLevel(7, 7, { ["3,2"] = true, ["3,3"] = true, ["5,4"] = true })
      local expected = visible(level, 4, 4, 5)
      local seen = {}
      local nested = false
      prism.computeFOV(level, { x = 4, y = 4 }, 5, function(x, y, cell)
         seen[cell] = true
         if not nested and x ~= 4 then
            nested = true
            visible(level, 2, 6, 4)
         end
      end)
      expect.truthy(nested)
      expect.equal(seen, expected)
   end)

   it("preserves reciprocal visibility between floors around corners", function()
      local walls = { ["3,2"] = true, ["3,3"] = true, ["3,4"] = true, ["5,5"] = true }
      local level = makeLevel(7, 6, walls)
      local views = {}
      for y = 1, 6 do
         for x = 1, 7 do
            local key = x .. "," .. y
            if not walls[key] then views[key] = visible(level, x, y, 7) end
         end
      end
      for a, view in pairs(views) do
         for b, reverse in pairs(views) do
            expect.equal(view[b] == true, reverse[a] == true)
         end
      end
   end)
end)
