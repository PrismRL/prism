local Inky = geometer.require "inky"

---@class EditorGridProps : Inky.Props
---@field offset Vector2
---@field display Display
---@field scale Vector2
---@field editor Editor
---@field attachable SpectrumAttachable

---@class EditorGrid : Inky.Element
---@field props EditorGridProps

---@param self EditorGrid
---@param scene Inky.Scene
---@return function
local function EditorGrid(self, scene)
   local tdx, tdy = 0, 0
   self:onPointer("drag", function(_, pointer, dx, dy)
      tdx, tdy = tdx + dx, tdy + dy
      local csx, csy = self.props.display.cellSize.x, self.props.display.cellSize.y
      local drx, dry = math.floor(tdx / csx), math.floor(tdy / csy)
      tdx, tdy = tdx % csx, tdy % csy
      self.props.display:moveCamera(drx, dry)
   end)

   self:onPointer("releasedrag", function(_, pointer)
      tdx, tdy = 0, 0
   end)

   self:onPointer("press", function(_, pointer)
      local display = self.props.display
      local mx, my = love.mouse.getPosition()
      local cx, cy = display:getCellUnderMouse(mx / 3, my / 3)

      local tool = self.props.editor.tool

      tool:mouseclicked(self.props.editor, self.props.attachable, cx, cy)
      pointer:captureElement(self, true)
   end)

   self:onPointer("release", function(_, pointer)
      local tool = self.props.editor.tool
      local display = self.props.display
      local cx, cy = display:getCellUnderMouse()

      if tool then tool:mousereleased(self.props.editor, self.props.attachable, cx, cy) end

      pointer:captureElement(self, false)
   end)

   self:onPointer("scroll", function(_, pointer, dx, dy) end)

   return function(_, x, y, w, h)
      love.graphics.setScissor(x, y, w, h)
      local r, g, b, a = love.graphics.getColor()
      self.props.display:clear()
      self.props.display:putLevel(self.props.attachable)
      love.graphics.push()
      love.graphics.scale(3, 3)
      self.props.editor.tool:draw(self.props.editor, self.props.display)
      self.props.display:draw()
      love.graphics.pop()
      love.graphics.setColor(r, g, b, a)

      love.graphics.setScissor()
   end
end

---@alias EditorGridInit fun(scene: Inky.Scene): EditorGrid
---@type EditorGridInit
local EditorGridElement = Inky.defineElement(EditorGrid)
return EditorGridElement
