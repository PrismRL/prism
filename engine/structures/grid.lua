--- A simple grid class that stores data in a single contiguous array.
--- @class Grid<T> : Object
--- @field w integer The width of the grid.
--- @field h integer The height of the grid.
--- @field data any[] The data stored in the grid.
--- @overload fun(w: integer, h: integer, initialValue: any?): Grid
local Grid = prism.Object:extend("Grid")

--- The constructor for the 'Grid' class.
--- Initializes the grid with the specified dimensions and initial value.
--- @generic T
--- @param w integer The width of the grid.
--- @param h integer The height of the grid.
--- @param initialValue T? The initial value to fill the grid with.
--- @return Grid<T> -- The initialized grid.
function Grid:__new(w, h, initialValue)
   self.w = w
   self.h = h
   self.data = {}

   if initialValue then
      for i = 1, w * h do
         self.data[i] = initialValue
      end
   end

   return self
end

--- Initializes the grid with the specified dimensions and data.
--- @generic T
--- @param w integer The width of the grid.
--- @param h integer The height of the grid.
--- @param data T[] The data to fill the grid with.
--- @return Grid<T> -- The initialized grid.
function Grid:fromData(w, h, data)
   assert(#data == w * h, "Data length does not match grid size.")

   self.w = w
   self.h = h
   self.data = data
   return self
end

--- Gets the index in the data array for the specified coordinates.
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @return number? -- The index in the data array, or nil if out of bounds.
function Grid:getIndex(x, y)
   if x < 1 or x > self.w or y < 1 or y > self.h then return nil end

   return (y - 1) * self.w + x
end

--- Sets the value at the specified coordinates.
--- @generic T
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @param value T The value to set.
function Grid:set(x, y, value)
   local index = self:getIndex(x, y)
   if index then
      self.data[index] = value
   else
      error("Index out of bounds: " .. x .. ", " .. y)
   end
end

--- Gets the value at the specified coordinates.
--- @generic T
--- @param x integer The x-coordinate.
--- @param y integer The y-coordinate.
--- @return T? value The value at the specified coordinates, or nil if out of bounds.
function Grid:get(x, y)
   local index = self:getIndex(x, y)
   if index then return self.data[index] end
   return nil
end

--- Fills the entire grid with the specified value.
--- @generic T
--- @param value T The value to fill the grid with.
function Grid:fill(value)
   for i = 1, #self.data do
      self.data[i] = value
   end
end

--- Iterates over each cell in the grid, yielding x, y, and the value.
--- @generic T
--- @return fun(): number, number, T -- An iterator returning x, y, and value for each cell.
function Grid:each()
   local i = 0
   local w, h, data = self.w, self.h, self.data
   return function()
      i = i + 1
      if i > #data then return nil end
      local x = ((i - 1) % w) + 1
      local y = math.floor((i - 1) / w) + 1
      return x, y, data[i]
   end
end

return Grid
