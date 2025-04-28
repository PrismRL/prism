local Inky = geometer.require "inky"

---@type ButtonInit
local Button = geometer.require "elements.button"
---@type FilePanelInit
local FilePanel = geometer.require "elements.filepanel"
---@type EditorGridInit
local EditorGrid = geometer.require "elements.editorgrid"
---@type ToolsInit
local Tools = geometer.require "elements.tools"
---@type SelectionPanelInit
local SelectionPanel = geometer.require "elements.selectionpanel"

---@class EditorRootProps : Inky.Props
---@field gridPosition Vector2
---@field display Display
---@field attachable SpectrumAttachable
---@field scale Vector2
---@field quit boolean
---@field editor Editor

---@class EditorRoot : Inky.Element
---@field props EditorRootProps

---@param self EditorRoot
---@param scene Inky.Scene
---@return function
local function EditorRoot(self, scene)
   self.props.gridPosition = prism.Vector2(4, 4)

   love.graphics.setDefaultFilter("nearest", "nearest")
   local atlas = spectrum.SpriteAtlas.fromGrid(geometer.assetPath .. "/assets/buttons.png", 24, 12)

   local width = love.graphics.getWidth() / self.props.scale.x
   width = width - (width % 8)
   local height = love.graphics.getHeight() / self.props.scale.y
   height = height - (height % 8)
   local canvas = love.graphics.newCanvas(width, height)
   local overlay = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
   local frame = love.graphics.newImage(geometer.assetPath .. "/assets/frame.png")
   local frameBottom = love.graphics.newImage(geometer.assetPath .. "/assets/frame_bottom.png")

   local filePanel = FilePanel(scene)
   filePanel.props.scale = self.props.scale
   filePanel.props.overlay = overlay

   local fileButton = Button(scene)
   fileButton.props.tileset = atlas.image
   fileButton.props.unpressedQuad = atlas:getQuadByIndex(1)
   fileButton.props.pressedQuad = atlas:getQuadByIndex(2)
   fileButton.props.toggle = true
   fileButton.props.disabled = not self.props.editor.fileEnabled
   fileButton.props.disabledQuad = atlas:getQuadByIndex(11)
   fileButton.props.onPress = function(pointer)
      filePanel.props.open = true
      filePanel.props.editor = self.props.editor
      pointer:captureElement(filePanel, true)
   end

   local playButton = Button(scene)
   playButton.props.tileset = atlas.image
   playButton.props.unpressedQuad = atlas:getQuadByIndex(3)
   playButton.props.pressedQuad = atlas:getQuadByIndex(4)
   playButton.props.onRelease = function()
      self.props.quit = true
   end

   local debugButton = Button(scene)
   debugButton.props.tileset = atlas.image
   debugButton.props.unpressedQuad = atlas:getQuadByIndex(5)
   debugButton.props.pressedQuad = atlas:getQuadByIndex(6)
   debugButton.props.onRelease = function()
      self.props.quit = true
      self.props.attachable.debug = true
   end

   local forwardButton = Button(scene)
   forwardButton.props.tileset = atlas.image
   forwardButton.props.unpressedQuad = atlas:getQuadByIndex(7)
   forwardButton.props.pressedQuad = atlas:getQuadByIndex(8)

   local cellButton = Button(scene)
   cellButton.props.tileset = atlas.image
   cellButton.props.unpressedQuad = atlas:getQuadByIndex(7)
   cellButton.props.pressedQuad = atlas:getQuadByIndex(8)

   local actorButton = Button(scene)
   actorButton.props.tileset = atlas.image
   actorButton.props.unpressedQuad = atlas:getQuadByIndex(9)
   actorButton.props.pressedQuad = atlas:getQuadByIndex(10)

   local tools = Tools(scene)

   local grid = EditorGrid(scene)
   grid.props.scale = prism.Vector2(2, 2)
   self:useEffect(function()
      grid.props.editor = self.props.editor
      grid.props.display = self.props.display
      grid.props.attachable = self.props.attachable
      tools.props.editor = self.props.editor
   end, "attachable", "display")

   local selectionPanel = SelectionPanel(scene)
   selectionPanel.props.display = self.props.display
   selectionPanel.props.size = prism.Vector2(self.props.scale.x * 8, self.props.scale.y * 8)
   selectionPanel.props.editor = self.props.editor
   selectionPanel.props.overlay = overlay

   local fillModeButton = Button(scene)
   local toggleAtlas = spectrum.SpriteAtlas.fromGrid(geometer.assetPath .. "/assets/toggle.png", 16, 8)
   fillModeButton.props.tileset = toggleAtlas.image
   fillModeButton.props.pressedQuad = toggleAtlas:getQuadByIndex(1)
   fillModeButton.props.unpressedQuad = toggleAtlas:getQuadByIndex(2)
   fillModeButton.props.toggle = true
   fillModeButton.props.untoggle = true
   fillModeButton.props.pressed = true
   fillModeButton.props.onPress = function()
      self.props.editor.fillMode = not self.props.editor.fillMode
   end

   self:on("fillMode", function(_, fillMode)
      fillModeButton.props.pressed = fillMode
   end)

   self:on("closeFilePanel", function()
      fileButton.props.pressed = false
   end)

   self:on("focus", function(_, focused)
      self.props.editor.keybindsEnabled = not focused
   end)

   local background = prism.Color4.fromHex(0x181425)
   local frameBackground = prism.Color4.fromHex(0x193c3e)
   local panelBackground = prism.Color4.fromHex(0x262b44)
   return function(_, x, y, w, h, depth)
      love.graphics.push("all")
      love.graphics.setCanvas(overlay)
      love.graphics.clear()
      love.graphics.setColor(frameBackground:decompose())
      love.graphics.rectangle(
         "fill",
         0,
         canvas:getHeight() * self.props.scale.y,
         overlay:getWidth(),
         overlay:getHeight() - canvas:getHeight() * self.props.scale.y
      )
      love.graphics.setColor(panelBackground:decompose())
      love.graphics.rectangle(
         "fill",
         canvas:getWidth() * self.props.scale.x,
         0,
         overlay:getWidth() - canvas:getWidth() * self.props.scale.x,
         overlay:getHeight()
      )
      love.graphics.rectangle(
         "fill",
         (canvas:getWidth() - 88) * self.props.scale.x,
         canvas:getHeight() * self.props.scale.y,
         1000,
         overlay:getHeight() - canvas:getHeight() * self.props.scale.y
      )
      love.graphics.pop()

      love.graphics.setBackgroundColor(background:decompose())
      love.graphics.push("all")

      local bottomEdge = canvas:getHeight() - 16
      local panelEdge = canvas:getWidth() - 104
      love.graphics.setCanvas(canvas)
      love.graphics.clear()
      love.graphics.setColor(frameBackground:decompose())
      love.graphics.rectangle("fill", 0, bottomEdge, panelEdge + 16, love.graphics.getHeight())
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setScissor(0, 0, panelEdge, bottomEdge)
      love.graphics.draw(frame)
      love.graphics.draw(frameBottom, 0, bottomEdge - 16)
      love.graphics.setScissor()
      fileButton:render(8, bottomEdge, 24, 12)
      playButton:render(8 * 2 + 24, bottomEdge, 24, 12)
      debugButton:render(8 * 6 + 24, bottomEdge, 24, 12)
      forwardButton:render(8 * 10 + 24, bottomEdge, 24, 12)
      tools:render(panelEdge - 13 * 8, canvas:getHeight() - 24, 112, 12)
      selectionPanel:render(panelEdge, 0, 88, canvas:getHeight(), depth + 1)
      fillModeButton:render(panelEdge + 80, canvas:getHeight() - 48, 16, 8)
      if filePanel.props.open then filePanel:render(8, canvas:getHeight() - 8 * 11, 8 * 12, 8 * 8, depth + 1) end
      love.graphics.setCanvas()

      grid:render(
         self.props.gridPosition.x,
         self.props.gridPosition.y,
         (panelEdge + 16) * self.props.scale.x,
         bottomEdge * self.props.scale.y,
         depth + 0.5
      )

      love.graphics.scale(self.props.scale:decompose())
      love.graphics.draw(canvas, 0, 0)
      love.graphics.origin()
      love.graphics.draw(overlay, 0, 0)

      love.graphics.pop()
   end
end

---@type fun(scene: Inky.Scene): EditorRoot
local EditorRootElement = Inky.defineElement(EditorRoot)
return EditorRootElement
