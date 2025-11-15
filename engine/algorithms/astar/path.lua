--- A class to represent the A* path and its cost
---@class Path : Object
---@field path Vector2[] -- The path as an ordered list of Vector2 nodes
---@field cost number -- The total cost to traverse the path
---@field private costIndex integer[]
---@overload fun(path: Vector2[], costIndex?: integer[]): Path
local Path = prism.Object:extend("Path")
Path.__index = Path

--- Constructor for the Path class
---@param path Vector2[]
---@param costIndex? integer[]
---@return Path
function Path:__new(path, costIndex)
   self.path = path
   self.costIndex = costIndex or {}
   self.cost = 0
   for i, node in ipairs(path) do
      self.cost = self.cost + (self.costIndex[i] or 0)
   end
   return self
end

--- Get the length of the path (number of nodes)
---@return integer
function Path:length()
   return #self.path
end

--- Get the total cost of the path
---@return number
function Path:getTotalCost()
   return self.cost
end

--- Get the path as a table of nodes
---@return Vector2[]
function Path:getPath()
   return self.path
end

--- Trim the path to a given total cost
---@param maxCost number -- The maximum allowable cost for the trimmed path
---@return Path -- A new Path object with the trimmed path
function Path:trim(maxCost)
   local trimmedPath = {}
   local trimmedCost = 0
   local currentCost = 0

   for i, node in ipairs(self.path) do
      local nodeCost = self.costIndex[i] or 0

      -- Add the current node's cost if it doesn't exceed the max cost
      if currentCost + nodeCost <= maxCost then
         table.insert(trimmedPath, node)
         trimmedCost = currentCost + nodeCost
         currentCost = trimmedCost
      else
         break
      end
   end

   return Path(trimmedPath, self.costIndex)
end

--- Pop the first node from the path
---@return Vector2|nil -- The removed node, or nil if the path is empty
function Path:pop()
   if #self.path == 0 then return nil end

   local removedNode = table.remove(self.path, 1)
   local nodeCost = table.remove(self.costIndex, 1)
   self.cost = self.cost - nodeCost

   return removedNode
end

function Path:popBack()
   if #self.path == 0 then return nil end

   local removedNode = table.remove(self.path, #self.path)
   local nodeCost = table.remove(self.costIndex, #self.path)
   self.cost = self.cost - nodeCost

   return removedNode
end

--- Get the total cost at a specific index in the path
---@param index integer -- The index in the path
---@return number -- The total cost up to the specified index
function Path:totalCostAt(index)
   local totalCost = 0
   for i = 1, math.min(index, #self.path) do
      local node = self.path[i]
      totalCost = totalCost + self.costIndex[i]
   end
   return totalCost
end

return Path
