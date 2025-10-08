--- @type UIWindow
local Window = spectrum.require "ui/window"

--- @type UIContainer
local Container = spectrum.require "ui/container"

--- @type IO
local IO = spectrum.require "ui/io"

--- @type Style
local DEFAULTSTYLE = spectrum.require "ui/style"

---Holds cursor position and active container during layout.
---@class ContainerInfo
---@field cursorX integer
---@field cursorY integer
---@field container UIContainer

---Represents the main immediate-mode UI system for Spectrum.
---@class UI : Object
---@field baseStyle Style
---@field frame integer
---@field display Display
---@field io IO
---@field windows table<string, UIWindow>
---@field curWindow UIWindow|nil
---@field cursorX integer
---@field cursorY integer
---@field lineMaxH integer
---@field clipStack table
---@field idStack string[]
---@field hot string|nil
---@field active string|nil
---@field focus string|nil
---@field drawList DrawCommand[]
---@field orderCounter integer
---@field currentClip Rectangle?
---@field containerStack ContainerInfo[]
local UI = prism.Object:extend "UI"

---Creates a new UI instance.
---@param style? Style
function UI:__new(style)
   self.baseStyle      = style or DEFAULTSTYLE
   self.styleStack     = {}
   self.frame          = 0
   self.display        = nil
   self.io             = IO()
   self.windows        = {}
   self.curWindow      = nil
   self.cursorX        = 0
   self.cursorY        = 0
   self.lineMaxH       = 1
   self.clipStack      = {}
   self.containers     = {}
   self.containerStack = {}
   self.idStack        = {}
   self.hot            = nil
   self.active         = nil
   self.focus          = nil
   self.drawList       = {}
   self.orderCounter   = 0
   self._collapsible   = {}
end

---Returns the current active style (top override or base style).
---@return Style
function UI:getStyle()
   local top = self.styleStack[#self.styleStack]
   return top or self.baseStyle
end

---Replaces the base style without clearing overrides.
---@param style Style
function UI:setBaseStyle(style)
   self.baseStyle = style or DEFAULTSTYLE
end

---Pushes a shallow style override table onto the stack.
---@param overrides table
function UI:pushStyle(overrides)
   local parent = self:getStyle()
   local frame  = overrides or {}
   for k, v in pairs(frame) do
      if type(v) == "table" then
         setmetatable(v, { __index = parent[k] })
      end
   end
   setmetatable(frame, { __index = parent })
   table.insert(self.styleStack, frame)
end

---Pops the last pushed style override.
function UI:popStyle()
   assert(#self.styleStack > 0, "UI:popStyle() with empty override stack")
   table.remove(self.styleStack)
end

local SEP = string.char(31)

---Pushes a new ID component onto the stack.
---@param idpart any
function UI:pushID(idpart)
   table.insert(self.idStack, tostring(idpart))
end

---Pops the most recent ID component.
function UI:popID()
   table.remove(self.idStack)
end

---Creates a unique hierarchical widget ID from the stack.
---@return string
function UI:makeID()
   return table.concat(self.idStack, SEP)
end

---Feeds mouse input to the UI in grid-cell coordinates.
---@param cellx integer|nil
---@param celly integer|nil
---@param isDown boolean|nil
---@param pressed boolean|nil
---@param released boolean|nil
function UI:feedMouse(cellx, celly, isDown, pressed, released)
   self.io:feedMouse(cellx, celly, isDown, pressed, released)
   self.winAtMouse = self:_topmostWindowAt(self.io.mx, self.io.my)
end

---Feeds key input to the UI.
---@param key string
---@param down boolean
function UI:feedKey(key, down)
   self.io:feedKey(key, down)
end

---Feeds text input to the UI.
---@param char string
function UI:feedText(char)
   self.io:feedText(char)
end

---Returns the current clip rectangle.
---@return Rectangle|nil
function UI:getClip()
   return self.currentClip
end

---Pushes a new clip rectangle and updates the cumulative region.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@return Rectangle
function UI:pushClip(x, y, w, h)
   local scrollX, scrollY = self:getScroll()
   local x, y = x - scrollX, y - scrollY
   local r = prism.Rectangle(x or 0, y or 0, w or 0, h or 0)
   if self.currentClip then
      r = self.currentClip:intersection(r) or prism.Rectangle(0, 0, 0, 0)
   end
   table.insert(self.clipStack, r)
   self.currentClip = r
   return r
end

---Pops the current clip rectangle and restores the previous one.
---@return Rectangle|nil
function UI:popClip()
   local popped = table.remove(self.clipStack)
   self.currentClip = self.clipStack[#self.clipStack] or nil
   return popped
end

---Begins a new frame for drawing.
---@param display Display
function UI:beginFrame(display)
   self.frame = self.frame + 1
   self.display = display
   self.hot = nil
   self.drawList = {}
   self.orderCounter = 0
   self.clipStack = {}
   self.currentClip = nil
end

---Tracks draw commands to update container content sizes.
---@param cmd DrawCommand
function UI:_trackContentFromCmd(cmd)
   if not cmd.content then return end
   local win = self:_currentScope()
   if not win then return end
   local w, h = 0, 0
   if cmd.kind == "text" then
      w = cmd.width or #cmd.text
      h = 1
   else
      w = cmd.w
      h = cmd.h
   end
   local right  = (cmd.x - win.innerX + w)
   local bottom = (cmd.y - win.innerY + h)
   win:setContentSize(self, right, bottom)
end

---Returns accumulated scroll from all active containers and windows.
---@return integer x
---@return integer y
function UI:getScroll()
   local x, y = 0, 0
   for _, continfo in pairs(self.containerStack) do
      local cont = continfo.container
      x, y = x + cont.scrollX, y + cont.scrollY
   end
   if self.curWindow then
      x, y = x + self.curWindow.scrollX, y + self.curWindow.scrollY
   end
   return x, y
end

---Queues a draw command.
---@param cmd DrawCommand
function UI:_emit(cmd)
   self.orderCounter = self.orderCounter + 1
   cmd.order = self.orderCounter
   cmd.clip = self:getClip()
   self:_trackContentFromCmd(cmd)
   if cmd.content then
      local x, y = self:getScroll()
      cmd.x = cmd.x - x
      cmd.y = cmd.y - y
   end
   table.insert(self.drawList, cmd)
end

---Queues a filled rectangle draw command.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param color Color4
---@param content boolean|nil
function UI:_bgRect(x, y, w, h, color, content)
   local scope = self:_currentScope()
   self:_emit({
      kind    = "rect",
      x       = x,
      y       = y,
      w       = w,
      h       = h,
      bg      = color,
      layer   = scope and scope.z or 0,
      clip    = self:getClip(),
      content = content ~= false
   })
end

---Queues a text draw command.
---@param x integer
---@param y integer
---@param str string
---@param fg Color4|nil
---@param align '"left"'|'"center"'|'"right"'|nil
---@param width integer|nil
---@param content boolean|nil
function UI:_text(x, y, str, fg, align, width, content)
   local scope = self:_currentScope()
   if str == "" then return end
   width = width or #str
   self:_emit({
      kind    = "text",
      x       = x,
      y       = y,
      text    = str,
      fg      = fg,
      layer   = scope and scope.z or 0,
      align   = align,
      width   = width,
      clip    = self:getClip(),
      content = content ~= false
   })
end

---Queues a border rectangle draw command.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param color Color4|nil
---@param chars any
---@param fg Color4|nil
---@param sides any
---@param content boolean|nil
function UI:_border(x, y, w, h, color, chars, fg, sides, content)
   local scope = self:_currentScope()
   self:_emit({
      kind    = "border",
      x       = x,
      y       = y,
      w       = w,
      h       = h,
      bg      = color,
      layer   = scope and scope.z or 0,
      ch      = chars,
      chars   = chars,
      fg      = fg,
      sides   = sides,
      clip    = self:getClip(),
      content = content ~= false
   })
end

local DEFAULT_CHARS = {}

---Ends the frame, sorts and flushes draw commands to the Display.
function UI:endFrame()
   table.sort(self.drawList, function(a, b)
      if a.layer ~= b.layer then return a.layer < b.layer end
      return a.order > b.order
   end)
   local d = self.display
   local dummyClip = prism.Rectangle(1, 1, d.width, d.height)
   for _, cmd in ipairs(self.drawList) do
      local clip = cmd.clip or dummyClip
      local cx, cy, cw, ch = clip.position.x, clip.position.y, clip.width, clip.height
      if cmd.kind == "rect" then
         d:setClip(cx, cy, cw, ch)
         d:putFilledRect(cmd.x, cmd.y, cmd.w, cmd.h, " ", prism.Color4.TRANSPARENT, cmd.bg, cmd.layer)
         d:setClip()
      elseif cmd.kind == "border" then
         d:setClip(cx, cy, cw, ch)
         local fg = cmd.fg or prism.Color4.WHITE
         local bg = cmd.bg or prism.Color4.TRANSPARENT
         local sides = cmd.sides or { left = true, right = true, top = true, bottom = true }
         local x, y, w, h = cmd.x, cmd.y, cmd.w, cmd.h
         local chars = cmd.chars or DEFAULT_CHARS
         local V, H = chars.v or cmd.ch or " ", chars.h or cmd.ch or " "
         local TL, TR = chars.tl or cmd.ch or " ", chars.tr or cmd.ch or " "
         local BL, BR = chars.bl or cmd.ch or " ", chars.br or cmd.ch or " "
         if w >= 1 and h >= 1 then
            if sides.top and sides.left then d:put(x, y, TL, fg, bg, cmd.layer) end
            if sides.top and sides.right then d:put(x + w - 1, y, TR, fg, bg, cmd.layer) end
            if sides.bottom and sides.left then d:put(x, y + h - 1, BL, fg, bg, cmd.layer) end
            if sides.bottom and sides.right then d:put(x + w, y + h, BR, fg, bg, cmd.layer) end
            if sides.top then
               for ix = 0, w do d:put(x + ix, y, H, fg, bg, cmd.layer) end
            end
            if sides.bottom then
               for ix = 0, w do d:put(x + ix, y + h, H, fg, bg, cmd.layer) end
            end
            if sides.left then
               for iy = 0, h do d:put(x, iy + y, V, fg, bg, cmd.layer) end
            end
            if sides.right then
               for iy = 0, h do d:put(x + w, iy + y, V, fg, bg, cmd.layer) end
            end
         end
         d:setClip()
      elseif cmd.kind == "text" then
         d:setClip(cx, cy, cw, ch)
         d:putString(cmd.x, cmd.y, cmd.text, cmd.fg, nil, cmd.layer, cmd.align, cmd.width)
         d:setClip()
      end
   end
   self:normalizeZBounds()
   self.io:endFrame()
   assert(#self.styleStack == 0, "Unbalanced style stack!")
   assert(#self.idStack == 0, ("Unbalanced pushID/popID: depth=%d"):format(#self.idStack))
end

---Sets the layout cursor position.
---@param x integer
---@param y integer
function UI:setCursor(x, y)
   self.cursorX, self.cursorY = x, y
   self.lineMaxH = 1
end

---Returns the current cursor position.
---@return integer x
---@return integer y
function UI:getCursor()
   return self.cursorX, self.cursorY
end

---Advances the cursor for the current layout scope.
---@param w integer
---@param h integer
function UI:_advanceCursor(w, h)
   local scope = self:_currentScope()
   scope:advanceCursor(self, w, h)
end

---Continues placing widgets on the same line.
---@param spacing integer|nil
function UI:sameLine(spacing)
   local style = self:getStyle()
   self.cursorY = self.cursorY - (self.lineMaxH + style.layout.spacingY)
   self.cursorX = self.cursorX + (spacing or style.layout.spacingX)
end

---Moves to the next layout line.
---@param h integer|nil
function UI:newLine(h)
   local style = self:getStyle()
   self.cursorX = self:_currentScope() and self:_currentScope().innerX
   self.cursorY = self.cursorY + (h or self.lineMaxH) + style.layout.spacingY
   self.lineMaxH = 1
end

---Computes the rectangle for the next layout item.
---@param w integer|nil
---@param h integer|nil
---@return integer x
---@return integer y
---@return integer iw
---@return integer ih
function UI:_itemRect(w, h)
   local style = self:getStyle()
   local x, y = self:getCursor()
   w = w or style.layout.itemW
   h = h or style.layout.itemH
   return x, y, w, h
end

---Checks if the mouse is over a rectangle.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@return boolean
function UI:_mouseOver(x, y, w, h)
   local mx, my = self.io.mx, self.io.my
   return (mx >= x and mx < x + w and my >= y and my < y + h)
end

---Returns z-depth bounds across all windows.
---@return integer min
---@return integer max
function UI:getZBounds()
   local min, max = math.huge, 0
   for _, window in pairs(self.windows) do
      min = math.min(window.z, min)
      max = math.max(window.z, max)
   end
   if min == math.huge then min = 0 end
   return min, max
end

---Normalizes window z-depths so the lowest z = 0.
function UI:normalizeZBounds()
   local min = self:getZBounds()
   for _, window in pairs(self.windows) do
      window.z = window.z - min
   end
end

---Returns the topmost window under the mouse coordinates.
---@param mx integer
---@param my integer
---@return UIWindow|nil
function UI:_topmostWindowAt(mx, my)
   local top, topz = nil, -math.huge
   for _, win in pairs(self.windows) do
      if win:contains(mx, my) and win.z > topz then
         top, topz = win, win.z
      end
   end
   return top
end

---Begins a window scope.
---@param title string
---@param x integer|nil
---@param y integer|nil
---@param w integer|nil
---@param h integer|nil
---@param opts UIWindowOpts|nil
function UI:beginWindow(title, x, y, w, h, opts)
   if self.curWindow then error("UI:beginWindow() called within another window") end
   opts = opts or {}
   self:pushStyle(opts.style or {})
   self:pushID(title)
   local id = self:makeID()
   if not self.windows[id] then
      local _, maxZ = self:getZBounds()
      self.windows[id] = Window(title, x, y, w, h, maxZ, opts)
      self.windows[id]:setRect(x, y, w, h)
      self.windows[id].id = id
   end
   local win = self.windows[id]
   if not win.opts.resizable then win:setRect(nil, nil, w, h) end
   if not win.opts.moveable then win:setRect(x, y) end
   local style = self:getStyle()
   local _, maxz = self:getZBounds()
   local isTop = self.winAtMouse == win
   win:bringToFrontOnPress(self, self.io, maxz)
   local captured =
      win:handleCollapse(self, self.io)
      or win:handleScrollbars(self, isTop, self.io, style)
      or win:handleDrag(self, isTop, self.io)
      or win:handleResize(self, isTop, self.io)
   win:layout(style)
   win:pushClip(self)
   win:setCursor(self)
   self.curWindow = win
   self.containerStack = {}
end

---Ends the current window scope.
function UI:endWindow()
   self:popID()
   self:popClip()
   self:_currentScope():paint(self)
   if not self.curWindow then
      error("UI:endWindow() called without matching beginWindow()")
   end
   assert(#self.containerStack == 0, "endWindow() with non-empty container stack")
   self.curWindow = nil
   self:popStyle()
end

---Returns the current active drawing container or root window.
---@return UIContainer
function UI:_currentScope()
   local top = self.containerStack[#self.containerStack]
   return (top and top.container) or self.curWindow
end

---Determines if the current scope accepts mouse input.
---@return boolean
function UI:_scopeAcceptsMouse()
   local root = self.curWindow
   if not root or self.winAtMouse ~= root then return false end
   local clip = self.currentClip
   if not clip then return true end
   local x, y, w, h = clip.position.x, clip.position.y, clip.width, clip.height
   local mx, my = self.io.mx, self.io.my
   return mx >= x and mx < x + w and my >= y and my < y + h
end

---Pushes a container scope onto the stack.
---@param container UIContainer
function UI:pushContainer(container)
   local saved = {
      container = container,
      cursorX   = self.cursorX,
      cursorY   = self.cursorY,
      lineMaxH  = self.lineMaxH,
   }
   table.insert(self.containerStack, saved)
   container:pushClip(self)
   container:setCursor(self)
end

---Pops the current container scope and restores layout state.
function UI:popContainer()
   local saved = table.remove(self.containerStack)
   if not saved then error("UI:popContainer() without matching pushContainer()") end
   local container = saved.container
   self:popClip()
   container:paint(self)
   self.cursorX  = saved.cursorX
   self.cursorY  = saved.cursorY
   self.lineMaxH = saved.lineMaxH
   self:_advanceCursor(container.w, container.h)
end

---Begins a container scope at the current cursor position.
---@param name string
---@param w integer
---@param h integer
---@param opts {autoSize?: boolean, style?: Style}?
---@return UIContainer
function UI:beginContainer(name, w, h, opts)
   if not self.curWindow then
      error("UI:beginContainer() requires an active window")
   end
   self:pushID(("container:%s"):format(name))
   local id = self:makeID()
   if not self.containers[id] then self.containers[id] = Container(w, h, opts) end
   local container = self.containers[id]
   opts = opts or {}
   self:pushStyle(opts.style or {})
   local curStyle = self:getStyle()
   local cx, cy = self:getCursor()
   local parent = self:_currentScope()
   local z = parent.z
   local isTop = self:_scopeAcceptsMouse()
   container:handleScrollbars(self, isTop, self.io, curStyle)
   container:layout(curStyle, cx, cy, z)
   self:pushContainer(container)
   return container
end

---Ends the current container scope.
function UI:endContainer()
   self:_currentScope():paint(self)
   self:popContainer()
   self:popID()
   self:popStyle()
end

---Retrieves or creates collapsible state for a given ID.
---@param id string
---@param defaultOpen boolean|nil
---@return table
function UI:_getCollapsibleState(id, defaultOpen)
   local s = self._collapsible[id]
   if not s then
      s = { open = (defaultOpen ~= false) }
      self._collapsible[id] = s
   end
   return s
end

---Begins a collapsible category with persistent state.
---@param title string
---@param w integer
---@param h integer
---@param opts table|nil
---@return boolean open
function UI:beginCollapsibleCategory(title, w, h, opts)
   opts = opts or {}
   self:pushID(("collapsible:%s"):format(title))
   local id = self:makeID()
   local st = self:_getCollapsibleState(id, opts.open)
   local arrow = st.open and " V" or " >"
   local clicked = self:button(title .. arrow, w, 1)
   if st.open then
      self:beginContainer(title .. ":content", w, h)
   else
      self:popID()
   end
   local lastOpen = st.open
   if clicked then st.open = not st.open end
   return lastOpen
end

---Ends a collapsible category scope.
function UI:endCollapsibleCategory()
   self:endContainer()
   self:popID()
end

local uilist = spectrum.require "ui.widgets.list"
local uibutton = spectrum.require "ui.widgets.button"
local uitextinput = spectrum.require "ui.widgets.textinput"
local uicheckbox = spectrum.require "ui.widgets.checkbox"
local uislider = spectrum.require "ui.widgets.slider"

---Draws a list widget.
---@param name string
---@param items string[]|table[]
---@param selected integer|nil
---@param w integer
---@param h integer
---@param opts table|nil
---@return integer|nil newSelected, boolean activated
function UI:list(name, items, selected, w, h, opts)
   return uilist(self, name, items, selected, w, h, opts)
end

---Draws a button and returns true if clicked.
---@param text string
---@param w integer|nil
---@param h integer|nil
---@param opts table|nil
---@return boolean clicked
function UI:button(text, w, h, opts)
   return uibutton(self, text, w, h, opts)
end

---Draws a text input field.
---@param text string
---@param w integer|nil
---@param h integer|nil
---@param opts table|nil
---@return string newText, boolean changed
function UI:textInput(text, w, h, opts)
   return uitextinput(self, text, w, h, opts)
end

---Draws a checkbox widget.
---@param text string
---@param value boolean
---@param opts table|nil
---@return boolean newValue, boolean changed
function UI:checkbox(text, value, opts)
   return uicheckbox(self, text, value, opts)
end

---Draws a slider widget.
---@param label string
---@param value number
---@param min number
---@param max number
---@param w integer|nil
---@param h integer|nil
---@param opts table|nil
---@return number newValue, boolean changed
function UI:slider(label, value, min, max, w, h, opts)
   return uislider(self, label, value, min, max, w, opts)
end

---Draws a text label.
---@param text string
---@param color Color4|nil
function UI:label(text, color)
   local x, y, w, h = self:_itemRect(#text, 1)
   local style = self:getStyle()
   self:_text(x, y, text, color or style.colors.text)
   self:_advanceCursor(w, h)
end

return UI
