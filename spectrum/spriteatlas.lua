local utf8 = require "utf8"

--- A simple sprite atlas. Used by spectrum.Display to render cells and actors.
---@class SpriteAtlas : Object
---@field image any The texture atlas love image
---@field quadsByName table<string, love.Quad> A table of quads indexed by sprite names
---@field quadsByIndex table<number, love.Quad> A table of quads indexed by sprite indices
---@overload fun(imagePath: string, spriteData: {x: integer, y: integer, width: integer, height:integer}, names?: string[]): SpriteAtlas
local SpriteAtlas = prism.Object:extend("SpriteAtlas")

--- The constructor for the SpriteAtlas class.
--- @param imagePath string The path to the texture atlas image.
--- @param spriteData table A table containing sprite names and their respective quads.
--- @param names? string[]
function SpriteAtlas:__new(imagePath, spriteData, names)
   self.image = love.graphics.newImage(imagePath)
   self.quadsByName = {}
   self.quadsByIndex = {}
   for i, data in ipairs(spriteData) do
      local quad =
         love.graphics.newQuad(data.x, data.y, data.width, data.height, self.image:getDimensions())
      if names then self.quadsByName[names[i] or tostring(i)] = quad end
      self.quadsByIndex[i] = quad
   end
end

--- Gets a quad by name.
--- @param name string The name of the sprite.
--- @return love.Quad? quad The love quad associated with the sprite name.
function SpriteAtlas:getQuadByName(name)
   return self.quadsByName[name]
end

--- Gets a quad by index.
--- @param index number The index of the sprite.
--- @return love.Quad? quad The love quad associated with the sprite index.
function SpriteAtlas:getQuadByIndex(index)
   return self.quadsByIndex[index]
end

--- Draws a sprite by name at the given position.
--- @param name string The name of the sprite.
--- @param x number The x coordinate to draw the sprite.
--- @param y number The y coordinate to draw the sprite.
function SpriteAtlas:drawByName(name, x, y)
   love.graphics.draw(self.image, self.quadsByName[name], x, y)
end

--- Draws a sprite by index at the given position.
--- @param index number The index of the sprite.
--- @param x number The x coordinate to draw the sprite.
--- @param y number The y coordinate to draw the sprite.
function SpriteAtlas:drawByIndex(index, x, y)
   love.graphics.draw(self.image, self.quadsByIndex[index], x, y)
end

--- Creates a SpriteAtlas from an Atlased JSON and PNG file.
--- @param imagePath string The path to the texture atlas image.
--- @param jsonPath string The path to the Atlased JSON file.
--- @return SpriteAtlas -- The created SpriteAtlas instance.
function SpriteAtlas.fromAtlased(imagePath, jsonPath)
   local jsonData = love.filesystem.read(jsonPath)
   local atlasData = prism.json.decode(jsonData)

   local spriteData = {}
   local names = {}
   for i, region in ipairs(atlasData.regions) do
      names[i] = region.name
      spriteData[i] = {
         x = region.rect[1],
         y = region.rect[2],
         width = region.rect[3],
         height = region.rect[4],
      }
   end

   return SpriteAtlas(imagePath, spriteData, names)
end

--- Creates a SpriteAtlas from a grid of cells.
--- @param imagePath string The path to the texture atlas image.
--- @param cellWidth number The width of each cell in the grid.
--- @param cellHeight number The height of each cell in the grid.
--- @param names string[]? The names of the sprites, mapping left to right, top to bottom. If not supplied the quads will be sorted by index not name.
--- @return SpriteAtlas -- The created SpriteAtlas instance.
function SpriteAtlas.fromGrid(imagePath, cellWidth, cellHeight, names)
   local image = love.graphics.newImage(imagePath)
   local imageWidth, imageHeight = image:getDimensions()

   assert(imageWidth % cellWidth == 0, "Image width must be evenly divisible by cell width")
   assert(imageHeight % cellHeight == 0, "Image height must be evenly divisible by cell height")

   local spriteData = {}
   local nameIndex = 1
   local cols = imageWidth / cellWidth
   local rows = imageHeight / cellHeight

   for row = 0, rows - 1 do
      for col = 0, cols - 1 do
         spriteData[nameIndex] = {
            x = col * cellWidth,
            y = row * cellHeight,
            width = cellWidth,
            height = cellHeight,
         }
         nameIndex = nameIndex + 1
      end
   end

   return SpriteAtlas(imagePath, spriteData, names)
end

--- Creates a SpriteAtlas from a grid of cells, mapping each quad to a UTF-8 character.
--- The first quad is mapped to utf8.char(startingCode), e.g. 'A' for 65, ' ' for 32.
--- @param imagePath string The path to the texture atlas image.
--- @param cellWidth number The width of each cell in the grid.
--- @param cellHeight number The height of each cell in the grid.
--- @return SpriteAtlas -- The created SpriteAtlas instance.
function SpriteAtlas.fromASCIIGrid(imagePath, cellWidth, cellHeight)
   local image = love.graphics.newImage(imagePath)
   local imageWidth, imageHeight = image:getDimensions()

   assert(imageWidth % cellWidth == 0, "Image width must be evenly divisible by cell width")
   assert(imageHeight % cellHeight == 0, "Image height must be evenly divisible by cell height")

   local totalCells = (imageWidth / cellWidth) * (imageHeight / cellHeight)
   local names = {}

   for i = 1, totalCells do
      names[i] = utf8.char(i - 1)
   end

   return SpriteAtlas.fromGrid(imagePath, cellWidth, cellHeight, names)
end

return SpriteAtlas
