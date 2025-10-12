--- @type UIContainer
local Container = spectrum.require "ui/container"

---@class UIWindowOpts : UIContainerOpts
---@field resizable  boolean?
---@field moveable   boolean?
---@field scrollX    boolean?
---@field scrollY    boolean?
---@field autoResize boolean?
---@field style      Style|nil?
---@field title      boolean?

---Default options for UIWindow.
---@type UIWindowOpts
local DEFAULT_OPTS = {
   resizable  = true,
   moveable   = true,
   scrollX    = true,
   scrollY    = true,
   autoResize = false,
   style      = nil,
   title      = true,
}

---A movable, resizable, and optionally collapsible window container.
---@class UIWindow : UIContainer
---@field id string
---@field x integer
---@field y integer
---@field w integer
---@field h integer
---@field z integer
---@field collapsed boolean
---@field dragging boolean
---@field dragDX integer
---@field dragDY integer
---@field opts UIWindowOpts
---@field minW integer
---@field minH integer
---@field rsStartMX integer
---@field rsStartMY integer
---@field rsStartW integer
---@field rsStartH integer
---@field resizing boolean
local Window = Container:extend("UIWindow", true)

---Creates a new UIWindow.
---@param title string
---@param x? integer
---@param y? integer
---@param w? integer
---@param h? integer
---@param z? integer
---@param opts? UIWindowOpts
function Window:__new(title, x, y, w, h, z, opts)
   self.title = title
   self.x, self.y = x or 1, y or 1
   self.z = z
   Container.__new(self, w or 30, h or 10, opts)
   self.opts = opts or {}
   for k, v in pairs(DEFAULT_OPTS) do
      if self.opts[k] == nil then self.opts[k] = v end
   end
   self.collapsed = false
   self.dragging = false
   self.dragDX, self.dragDY = 0, 0
   self.resizing = false
   self.rsStartMX, self.rsStartMY = 0, 0
   self.rsStartW, self.rsStartH = 0, 0
   self.minW, self.minH = 2, 2
   self.bg = true
   self.border = true
end

---Updates the window rectangle if new values are provided.
---@param x? integer
---@param y? integer
---@param w? integer
---@param h? integer
function Window:setRect(x, y, w, h)
   if x then self.x = x end
   if y then self.y = y end
   if w then self.w = w end
   if h then self.h = h end
end

---Returns true if a point lies inside the window bounds.
---@param mx integer
---@param my integer
---@return boolean
function Window:contains(mx, my)
   return (mx >= self.x and mx < self.x + self.w and my >= self.y and my < self.y + self.h)
end

---Returns true if a point lies within the title bar row.
---@param mx integer
---@param my integer
---@return boolean
function Window:titleHit(mx, my)
   if not self.opts.title then return false end
   return (mx >= self.x and mx < self.x + self.w and my == self.y)
end

---Returns true if a point hits the collapse toggle glyph.
---@param mx integer
---@param my integer
---@return boolean
function Window:collapseHit(mx, my)
   if not self.opts.title then return false end
   return (mx == self.x + self.w - 1 and my == self.y)
end

---Returns true if a point hits the bottom-right resize handle.
---@param mx integer
---@param my integer
---@return boolean
function Window:resizeHit(mx, my)
   return (mx == self.x + self.w - 1 and my == self.y + self.h - 1)
end

---Returns true if the window is resizable.
---@return boolean
function Window:isResizable()
   return self.opts.resizable and not self.opts.autoResize
end

---Brings the window to the front when pressed.
---@param ui UI
---@param io {mx: integer, my: integer, mpressed: boolean}
---@param maxZ integer
---@return boolean captured
function Window:bringToFrontOnPress(ui, io, maxZ)
   if io.mpressed and self:contains(io.mx, io.my) then
      self.z = maxZ + 1
      ui.focus = self.id
      return true
   end
   return false
end

---Handles window dragging from the title bar.
---@param ui UI
---@param topmost boolean
---@param io {mx: integer, my: integer, mpressed: boolean, mreleased: boolean, mdown: boolean}
---@return boolean captured
function Window:handleDrag(ui, topmost, io)
   if not self.opts.moveable then return false end
   local captured = false
   if self:titleHit(io.mx, io.my) and io.mpressed and topmost then
      self.dragging = true
      self.dragDX = io.mx - self.x
      self.dragDY = io.my - self.y
      captured = true
      ui.focus = self.id
   end
   if self.dragging then
      if io.mdown then
         self.x = io.mx - self.dragDX
         self.y = io.my - self.dragDY
         captured = true
      end
      if io.mreleased then
         self.dragging = false
         captured = true
      end
   end
   return captured
end

---Handles collapse toggle on the title bar.
---@param ui UI
---@param io {mx: integer, my: integer, mpressed: boolean}
---@return boolean captured
function Window:handleCollapse(ui, io)
   if self:collapseHit(io.mx, io.my)then
      ui:setMouseCursor("hand")
   end
   
   if io.mpressed and self:collapseHit(io.mx, io.my) then
      self.collapsed = not self.collapsed
      ui.focus = self.id
      return true
   end
   return false
end

---Handles resize dragging from the bottom-right corner.
---@param ui UI
---@param topmost boolean
---@param io {mx: integer, my: integer, mpressed: boolean, mreleased: boolean, mdown: boolean}
---@return boolean captured
function Window:handleResize(ui, topmost, io)
   local style = ui:getStyle()
   if not self:isResizable() then return false end
   if self.collapsed then
      self.resizing = false
      return false
   end
   local captured = false
   if not self.dragging and topmost and not io.mpressed and self:resizeHit(io.mx, io.my) then
      ui:setMouseCursor("sizenwse")
   end
   if not self.dragging and topmost and io.mpressed and self:resizeHit(io.mx, io.my) then
      self.resizing = true
      self.rsStartMX, self.rsStartMY = io.mx, io.my
      self.rsStartW, self.rsStartH = self.w, self.h
      ui.focus = self.id
      captured = true
   end
   if self.resizing then
      if io.mdown then
         ui:setMouseCursor("sizenwse")
         local dx = io.mx - self.rsStartMX
         local dy = io.my - self.rsStartMY
         local newW = math.max(self.rsStartW + dx, self.minW)
         local newH = math.max(self.rsStartH + dy, self.minH)
         local titleH = style.window.titleH
         newH = math.max(newH, titleH)
         self:setSize(newW, newH)
         captured = true
      end
      if io.mreleased then
         self.resizing = false
         captured = true
      end
   end
   return captured
end

---Performs layout for the window, computing inner bounds.
---@param ui UI
function Window:layout(ui)
   Container.layout(self, ui, self.x, self.y, self.z)
end

---Renders the window, title bar, and scrollbars.
---@param ui UI
function Window:paint(ui)
   local style = ui:getStyle()
   if self.opts.title then
      ui:pushClip(self.x + 1, self.y, math.max(self.w - 2, 0), 1)
      if self.title and self.title ~= "" then
         ui:_text(self.x + 1, self.y, self.title, style.window.titleFg, style.window.titleAlign, self.w, false)
      end
      ui:popClip()
      local glyph = self.collapsed and "+" or "-"
      ui:_text(self.x + self.w - 1, self.y, glyph, style.colors.textDim or style.colors.text, nil, nil, false)
      if not self.collapsed and self:isResizable() then
         ui:_text(self.x + self.w - 1, self.y + self.h - 1, "/", style.colors.textDim or style.colors.text, nil, nil, false)
      end
      ui:_bgRect(self.x, self.y, self.w, 1, style.window.titleBg, false)
   end
   if not self.collapsed then
      Container.paint(self, ui)
   end
end

---Pushes a clipping region for the window content.
---@param ui UI
function Window:pushClip(ui)
   if self.collapsed then
      ui:pushClip(0, 0, 0, 0)
   else
      Container.pushClip(self, ui)
   end
end

---Positions the layout cursor for the window’s content region.
---@param ui UI
function Window:setCursor(ui)
   if not self.collapsed then
      Container.setCursor(self, ui)
   end
end

return Window
