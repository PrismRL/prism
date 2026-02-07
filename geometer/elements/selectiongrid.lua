local Inky = geometer.require "inky"

---@class TileElementProps : Inky.Props
---@field placeable Placeable
---@field size Vector2 the final size of a tile in editor
---@field display Display
---@field onSelect fun(index: number)
---@field overlay love.Texture
---@field index integer

---@class TileElement : Inky.Element
---@field props TileElementProps

---@param self TileElement
---@param scene Inky.Scene
local function Tile(self, scene)
   local scale = prism.Vector2(
      self.props.size.x / self.props.display.cellSize.x,
      self.props.size.y / self.props.display.cellSize.y
   )

   self:onPointer("press", function()
      self.props.onSelect(self.props.index)
   end)

   self:onPointerEnter(function()
      love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
   end)

   self:onPointerExit(function()
      love.mouse.setCursor()
   end)

   return function(_, x, y, w, h)
      local drawable = self.props.placeable.entity:get(prism.components.Drawable)
      if not drawable then return end
      
      local quad = self.props.display:getQuad(drawable.index)

      love.graphics.push("all")
      love.graphics.setCanvas(self.props.overlay)
      love.graphics.setColor(drawable.background:decompose())
      love.graphics.rectangle(
         "fill",
         x / 8 * self.props.size.x,
         y / 8 * self.props.size.y,
         self.props.size.x,
         self.props.size.y
      )
      love.graphics.setColor(drawable.color:decompose())
      love.graphics.draw(
         self.props.display.spriteAtlas.image,
         quad,
         (x / 8) * self.props.size.x,
         (y / 8) * self.props.size.y,
         nil,
         scale.x,
         scale.y
      )
      love.graphics.pop()
   end
end

---@type fun(scene: Inky.Scene): TileElement
local TileElement = Inky.defineElement(Tile)

---@class SelectionGridProps : Inky.Props
---@field size Vector2 the final size of a tile in editor
---@field display Display
---@field onSelect fun(index: number)
---@field overlay love.Texture
---@field placeables Placeable[]
---@field elements TileElement[]
---@field filtered number[]
---@field selected Placeable
---@field startRange number
---@field endRange number

---@class SelectionGrid : Inky.Element
---@field props SelectionGridProps
---
---@param self SelectionGrid
---@param scene Inky.Scene
local function SelectionGrid(self, scene)
   local function resetRange()
      self.props.startRange = 1
      self.props.endRange = #self.props.filtered <= 15 and #self.props.filtered or 15
   end

   resetRange()

   local upOnSelect = self.props.onSelect
   self.props.onSelect = function(index)
      self.props.selected = self.props.placeables[index]
      upOnSelect(index)
   end

   self.props.elements = {}
   for index, placeable in ipairs(self.props.placeables) do
      local tile = TileElement(scene)
      tile.props.display = self.props.display
      tile.props.index = index
      tile.props.onSelect = self.props.onSelect
      tile.props.overlay = self.props.overlay
      tile.props.size = self.props.size
      tile.props.placeable = placeable
      table.insert(self.props.elements, tile)
   end
   self.props.onSelect(1)

   self:useEffect(function()
      resetRange()
   end, "filtered")

   self:onPointer("scroll", function(_, pointer, dx, dy)
      local max = #self.props.filtered
      local startRange = self.props.startRange
      local endRange = self.props.endRange

      if dy < 0 and max > endRange then
         startRange = startRange + 3
         endRange = math.min(endRange + 3, max)
      elseif dy > 0 and startRange > 3 then
         startRange = startRange - 3
         local sub = endRange % 3 == 0 and 3 or endRange % 3
         endRange = endRange - sub
      end

      self.props.startRange = startRange
      self.props.endRange = endRange
   end)

   ---@return number
   local function getScrollBarPosition()
      local max = #self.props.elements
      local bucket
      if self.props.startRange == 1 then
         bucket = 1
      elseif self.props.endRange == max then
         bucket = 9
      else
         local perBucket = max / 9
         bucket = ((self.props.startRange + self.props.endRange) / 2) / perBucket
      end
      return bucket
   end

   ---@return number
   local function getGrid()
      local grid = 2
      local max = #self.props.filtered

      if self.props.startRange > 3 then
         if self.props.endRange < max then
            grid = 4
         else
            grid = 1
         end
      elseif self.props.endRange < max then
         grid = 3
      end

      return grid
   end

   local scrollColor = prism.Color4.fromHex(0x2ce8f5)
   local selector = love.graphics.newImage(geometer.assetPath .. "/assets/selector.png")
   local gridAtlas =
      spectrum.SpriteAtlas.fromGrid(geometer.assetPath .. "/assets/grid.png", 7 * 8, 11 * 8)

   return function(_, x, y, w, h, depth)
      gridAtlas:drawByIndex(getGrid(), x + 24, y)

      love.graphics.setColor(scrollColor:decompose())
      love.graphics.rectangle("fill", x + (11 * 8) + 2, y + (8 * getScrollBarPosition()), 4, 8)
      love.graphics.setColor(1, 1, 1, 1)
      local column = 1
      local row = 1
      for i = self.props.startRange, self.props.endRange do
         local tile = self.props.elements[self.props.filtered[i]]

         local tileX, tileY = x + 16 + (8 * (2 * column)), y + (8 * row)
         tile:render(tileX, tileY, 8, 8, depth + 1)
         if tile.props.placeable == self.props.selected then
            love.graphics.draw(selector, tileX - 8, tileY - 8)
         end
         column = column + 1
         if column % 4 == 0 then
            column = 1
            row = row + 2
         end
      end
   end
end

---@alias SelectionGridInit fun(scene: Inky.Scene): SelectionGrid
---@type SelectionGridInit
local SelectionGridElement = Inky.defineElement(SelectionGrid)

return SelectionGridElement
