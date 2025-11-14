local Inky = geometer.require "inky"
---@type ButtonInit
local Button = geometer.require "elements.button"

---@class ToolsProps : Inky.Props
---@field selected Button
---@field editor Editor

---@class Tools : Inky.Element
---@field props ToolsProps

---@param self Tools
---@param scene Inky.Scene
---@return function
local function Tools(self, scene)
   local atlas = spectrum.SpriteAtlas.fromGrid(geometer.assetPath .. "/assets/tools.png", 8, 10)
   local background = love.graphics.newImage(geometer.assetPath .. "/assets/frame_bottomright.png")

   ---@param button Button
   ---@param tool Tool
   local function onPress(button, tool)
      return function()
         self.props.selected.props.pressed = false
         self.props.selected = button
         self.props.editor.tool = tool()
      end
   end

   local penButton = Button(scene)
   penButton.props.unpressedQuad = atlas:getQuadByIndex(1)
   penButton.props.pressedQuad = atlas:getQuadByIndex(2)
   penButton.props.tileset = atlas.image
   penButton.props.toggle = true
   penButton.props.onPress = onPress(penButton, geometer.require "tools.pen")
   penButton.props.pressed = true

   self.props.selected = penButton

   local deleteButton = Button(scene)
   deleteButton.props.unpressedQuad = atlas:getQuadByIndex(3)
   deleteButton.props.pressedQuad = atlas:getQuadByIndex(4)
   deleteButton.props.tileset = atlas.image
   deleteButton.props.toggle = true
   deleteButton.props.onPress = onPress(deleteButton, geometer.require "tools.erase")

   local rectButton = Button(scene)
   rectButton.props.unpressedQuad = atlas:getQuadByIndex(5)
   rectButton.props.pressedQuad = atlas:getQuadByIndex(6)
   rectButton.props.tileset = atlas.image
   rectButton.props.toggle = true
   rectButton.props.onPress = onPress(rectButton, geometer.require "tools.rect")

   local ellipseButton = Button(scene)
   ellipseButton.props.unpressedQuad = atlas:getQuadByIndex(7)
   ellipseButton.props.pressedQuad = atlas:getQuadByIndex(8)
   ellipseButton.props.tileset = atlas.image
   ellipseButton.props.toggle = true
   ellipseButton.props.onPress = onPress(ellipseButton, geometer.require "tools.ellipse")

   local lineButton = Button(scene)
   lineButton.props.unpressedQuad = atlas:getQuadByIndex(9)
   lineButton.props.pressedQuad = atlas:getQuadByIndex(10)
   lineButton.props.tileset = atlas.image
   lineButton.props.toggle = true
   lineButton.props.onPress = onPress(lineButton, geometer.require "tools.line")

   local fillButton = Button(scene)
   fillButton.props.unpressedQuad = atlas:getQuadByIndex(11)
   fillButton.props.pressedQuad = atlas:getQuadByIndex(12)
   fillButton.props.tileset = atlas.image
   fillButton.props.toggle = true
   fillButton.props.onPress = onPress(fillButton, geometer.require "tools.fill")

   local selectButton = Button(scene)
   selectButton.props.unpressedQuad = atlas:getQuadByIndex(13)
   selectButton.props.pressedQuad = atlas:getQuadByIndex(14)
   selectButton.props.tileset = atlas.image
   selectButton.props.toggle = true
   selectButton.props.onPress = onPress(selectButton, geometer.require "tools.select")

   ---@param pointer Inky.Pointer
   ---@param button Button
   local function press(pointer, button)
      pointer:captureElement(button, true)
      pointer:raise("press")
      pointer:captureElement(button, false)
   end

   local buttons = {
      pen = penButton,
      delete = deleteButton,
      rect = rectButton,
      ellipse = ellipseButton,
      line = lineButton,
      bucket = fillButton,
      select = selectButton,
   }

   self:on("controls", function(_, pointer, controls)
      --- @cast pointer Inky.Pointer
      --- @cast controls Controls
      for action, button in pairs(buttons) do
         if controls[action].pressed then press(pointer, button) end
      end
   end)

   return function(_, x, y, w, h)
      love.graphics.draw(background, x, y + 8)
      penButton:render(x + 8, y + 8, 8, 10)
      deleteButton:render(x + 8 + 8 * 2, y + 8, 8, 10)
      rectButton:render(x + 8 + 8 * 4, y + 8, 8, 10)
      ellipseButton:render(x + 8 + 8 * 6, y + 8, 8, 10)
      lineButton:render(x + 8 + 8 * 8, y + 8, 8, 10)
      fillButton:render(x + 8 + 8 * 10, y + 8, 8, 10)
      selectButton:render(x + 8 + 8 * 12, y + 8, 8, 10)
   end
end

---@alias ToolsInit fun(scene: Inky.Scene): Tools
---@type ToolsInit
local ToolsElement = Inky.defineElement(Tools)
return ToolsElement
