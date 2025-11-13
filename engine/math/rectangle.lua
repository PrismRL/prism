--- A Rectangle represents a 2D rectangular area with a position, width, and height.
--- @class Rectangle : Object
--- @overload fun(x?: number, y?: number, width?: number, height?: number): Rectangle
--- @field position Vector2 The top-left corner position of the rectangle.
--- @field width number The width of the rectangle.
--- @field height number The height of the rectangle.
local Rectangle = prism.Object:extend("Rectangle")

--- Constructor for Rectangle.
--- @param x number The x-coordinate of the top-left corner, or a Vector2 for the position.
--- @param y number The y-coordinate of the top-left corner (if xOrPosition is a number).
--- @param width number The width of the rectangle.
--- @param height number The height of the rectangle.
function Rectangle:__new(x, y, width, height)
   self.position = prism.Vector2(x or 0, y or 0)
   self.width = width or 0
   self.height = height or 0

   assert(self.width >= 0, "width must be non-negative")
   assert(self.height >= 0, "height must be non-negative")
end

--- Returns a copy of the rectangle.
--- @return Rectangle copy A new Rectangle instance with the same properties.
function Rectangle:copy()
   local x, y = self.position:decompose()
   return Rectangle(x, y, self.width, self.height)
end

--- Returns the minimum corner (top-left) of the rectangle.
--- This is simply the rectangle's position.
--- @return Vector2 topleft The top-left corner of the rectangle.
function Rectangle:min()
   return self.position
end

--- Returns the maximum corner (bottom-right) of the rectangle.
--- @return Vector2 bottomright The bottom-right corner of the rectangle.
function Rectangle:max()
   return self.position + prism.Vector2(self.width, self.height)
end

--- Calculates and returns the center point of the rectangle.
--- @return Vector2 center The center point of the rectangle.
function Rectangle:center()
   return self.position + prism.Vector2(self.width / 2, self.height / 2)
end

--- Calculates and returns the area of the rectangle.
--- @return number area The area of the rectangle.
function Rectangle:area()
   return self.width * self.height
end

--- Returns the width of the rectangle.
--- @return number width The width of the rectangle.
function Rectangle:getWidth()
   return self.width
end

--- Returns the height of the rectangle.
--- @return number height The height of the rectangle.
function Rectangle:getHeight()
   return self.height
end

--- Checks if a given point is inside the rectangle.
--- The point is considered inside if it's within or on the boundaries.
--- @param point Vector2 The point to check.
--- @return boolean contains True if the point is inside, false otherwise.
function Rectangle:contains(point)
   local min = self:min()
   local max = self:max()
   return point.x >= min.x and point.x <= max.x and point.y >= min.y and point.y <= max.y
end

--- Checks if this rectangle intersects with another rectangle.
--- Returns true if the rectangles overlap.
--- @param other Rectangle The other rectangle to check against.
--- @return boolean intersects True if the rectangles intersect, false otherwise.
function Rectangle:intersects(other)
   local selfMin = self:min()
   local selfMax = self:max()
   local otherMin = other:min()
   local otherMax = other:max()

   return selfMin.x < otherMax.x
      and selfMax.x > otherMin.x
      and selfMin.y < otherMax.y
      and selfMax.y > otherMin.y
end

--- Creates a new rectangle that is the union of this rectangle and another.
--- The union is the smallest rectangle that contains both rectangles.
--- @param other Rectangle The other rectangle to unite with.
--- @return Rectangle union A new Rectangle instance representing the union.
function Rectangle:union(other)
   local selfMinX, selfMinY = self.position:decompose()
   local selfMaxX, selfMaxY = self:max():decompose()

   local otherMinX, otherMinY = other.position:decompose()
   local otherMaxX, otherMaxY = other:max():decompose()

   local minX = math.min(selfMinX, otherMinX)
   local minY = math.min(selfMinY, otherMinY)
   local maxX = math.max(selfMaxX, otherMaxX)
   local maxY = math.max(selfMaxY, otherMaxY)

   local newWidth = maxX - minX
   local newHeight = maxY - minY
   return Rectangle(minX, minY, newWidth, newHeight)
end

--- Returns the four corner points of the rectangle.
--- The order is typically top-left, top-right, bottom-right, bottom-left.
--- @return table<Vector2> corners A table containing the four Vector2 corner points.
function Rectangle:toCorners()
   local topLeft = self.position
   local topRight = self.position + prism.Vector2(self.width, 0)
   local bottomRight = self.position + prism.Vector2(self.width, self.height)
   local bottomLeft = self.position + prism.Vector2(0, self.height)
   return { topLeft, topRight, bottomRight, bottomLeft }
end

--- Creates a string representation of the rectangle.
--- @return string str The string representation of the rectangle.
function Rectangle:__tostring()
   -- Calculate i and j to match BoundingBox's string format (x, y, i, j)
   local i = self.position.x + self.width
   local j = self.position.y + self.height
   return string.format(
      "Rectangle(x=%.2f, y=%.2f, i=%.2f, j=%.2f)",
      self.position.x,
      self.position.y,
      i,
      j
   )
end

return Rectangle

