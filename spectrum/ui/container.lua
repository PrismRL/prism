---@class UIContainerOpts
---@field minW        integer|nil   # Minimum width (defaults to 1)
---@field minH        integer|nil   # Minimum height (defaults to 1)
---@field maxW        integer|nil   # Maximum width (no cap if nil)
---@field maxH        integer|nil   # Maximum height (no cap if nil)
---@field autoSize    boolean?
---@field autoSizeW   boolean
---@field autoSizeH   boolean
---@field expand      boolean
---@field expandW     boolean
---@field expandH     boolean
---@field style       Style|nil     # Optional per-container style reference

---@class UIContainer : Object
---@field opts UIContainerOpts
---@field w integer
---@field h integer
---@field minW integer
---@field minH integer
---@field innerW integer
---@field innerH integer
---@field contentW integer
---@field contentH integer
---@field scrollX integer
---@field scrollY integer
---@field _sbDraggingH boolean
---@field _sbDraggingV boolean
---@field _sbGrabDX integer
---@field _sbGrabDY integer
---@field absX integer
---@field absY integer
---@field z integer
---@field innerX integer
---@field innerY integer
local UIContainer = prism.Object:extend("UIContainer", true)

---Creates a new UIContainer instance.
---@param w integer|nil
---@param h integer|nil
---@param opts UIContainerOpts|nil
function UIContainer:__new(w, h, opts)
   opts                                 = opts or {}
   self.w                               = math.max(1, w or 10)
   self.h                               = math.max(1, h or 6)
   self.minW                            = math.max(1, opts.minW or 1)
   self.minH                            = math.max(1, opts.minH or 1)

   self.opts = opts

   self.scrollX, self.scrollY           = 0, 0
   self.contentW, self.contentH         = 0, 0
   self.innerW, self.innerH             = 0, 0
   self._sbDraggingH, self._sbDraggingV = false, false
   self._sbGrabDX, self._sbGrabDY       = 0, 0
   self.absX, self.absY, self.z         = 0, 0, 0
   self.innerX, self.innerY             = 0, 0
end

---Advances the cursor position in the layout according to the container direction.
---@param ui UI
---@param w integer|nil
---@param h integer|nil
function UIContainer:advanceCursor(ui, w, h)
   local style = ui:getStyle()
   w = w or style.layout.itemW
   h = h or style.layout.itemH
   if style.container.layoutDir == "vertical" then
      ui.cursorY  = ui.cursorY + h + style.layout.spacingY
      ui.lineMaxH = 1
      return
   end
   ui.cursorX  = ui.cursorX + w + style.layout.spacingX
   ui.lineMaxH = math.max(ui.lineMaxH or 1, h)
end

---Sets the container size while enforcing min and max constraints.
---@param w integer|nil
---@param h integer|nil
function UIContainer:setSize(w, h)
   local opts = self.opts
   if w then
      w = math.max(self.minW, w)
      if opts.maxW then w = math.min(opts.maxW, w) end
      self.w = w
   end
   if h then
      h = math.max(self.minH, h)
      if opts.maxH then h = math.min(opts.maxH, h) end
      self.h = h
   end
end

--- Returns numeric flags for container borders (1 if present, 0 if not).
--- @param style table The style object containing container and border definitions.
--- @return integer tb, integer bb, integer lb, integer rb
local function getBorderFlags(style)
   if not style or not style.container or not style.border then
      return 0, 0, 0, 0
   end

   local hasTop    = style.container.hasBorder and style.border.sides.top
   local hasBottom = style.container.hasBorder and style.border.sides.bottom
   local hasLeft   = style.container.hasBorder and style.border.sides.left
   local hasRight  = style.container.hasBorder and style.border.sides.right

   local tb = hasTop and 1 or 0
   local bb = hasBottom and 1 or 0
   local lb = hasLeft and 1 or 0
   local rb = hasRight and 1 or 0

   return tb, bb, lb, rb
end

---Computes layout metrics and absolute positioning for this container.
---@param ui UI
---@param absX integer
---@param absY integer
---@param z integer
function UIContainer:layout(ui, absX, absY, z)
   local style = ui:getStyle()

   local tb, bb, lb, rb = getBorderFlags(style)

   if self.opts.autoSizeW or self.opts.autoSize then
      self.w = self.contentW + lb + rb
      self.innerW = self.contentW
   end

   if self.opts.autoSizeH or self.opts.autoSize then
      self.h = self.contentH + tb + bb
      self.innerH = self.contentH
   end

   local scope = ui:_currentScope()
   if self.opts.expand or self.opts.expandW then
      self.w = scope.innerW
      self.innerW = self.w - lb - rb
   end

   local scope = ui:_currentScope()
   if self.opts.expand or self.opts.expandH then
      self.h = scope.innerH
      self.innerH = self.h - tb - bb
   end

   self.absX, self.absY, self.z = absX, absY, z

   self.innerW = math.max(0, self.w) - lb - rb
   self.innerH = math.max(0, self.h) - tb - bb
   self.innerX = absX + lb
   self.innerY = absY + tb
   self.contentW, self.contentH = 0, 0
end

---Sets the UI cursor to the container’s padded inner origin.
---@param ui UI
function UIContainer:setCursor(ui)
   local style = ui:getStyle()
   local pad = style.container.padding
   local padL = style.container.padXLeft or pad
   local padT = style.container.padYTop or pad
   ui:setCursor(self.innerX + padL, self.innerY + padT)
end

---Pushes the container’s clipping region to the UI clip stack.
---@param ui UI
function UIContainer:pushClip(ui)
   ui:pushClip(self.innerX, self.innerY, self.innerW, self.innerH)
end

---Updates the content size if larger than previous measurements.
---@param ui UI
---@param w integer
---@param h integer
function UIContainer:setContentSize(ui, w, h)
   local newW = math.max(self.contentW, w)
   local newH = math.max(self.contentH, h)
   self.contentW, self.contentH = newW, newH
end

---Returns the maximum horizontal and vertical scroll values.
---@return integer maxScrollX, integer maxScrollY
function UIContainer:maxScroll()
   return
      math.max(0, self.contentW - self.innerW),
      math.max(0, self.contentH - self.innerH)
end

---Clamps scroll offsets to valid ranges.
function UIContainer:clampScroll()
   local mx, my = self:maxScroll()
   self.scrollX = math.max(0, math.min(self.scrollX, mx))
   self.scrollY = math.max(0, math.min(self.scrollY, my))
end

---Returns true if horizontal scrolling is required.
---@return boolean
function UIContainer:hscrollNeeded()
   local mx = self:maxScroll()
   return mx > 0
end

---Returns true if vertical scrolling is required.
---@return boolean
function UIContainer:vscrollNeeded()
   local _, my = self:maxScroll()
   return my > 0
end

---Returns the track rectangle for the given scrollbar axis.
---@param axis '"vertical"'|'"horizontal"'
---@return integer x, integer y, integer w, integer h
function UIContainer:getScrollbarRect(axis)
   if axis == "vertical" then
      return self.absX + self.w - 1, self.absY, 1, self.h - 1
   else
      return self.absX, self.absY + self.h - 1, self.w - 1, 1
   end
end

---Computes scrollbar geometry for the specified axis.
---@param axis '"vertical"'|'"horizontal"'
---@return table g
function UIContainer:computeScrollbar(axis)
   local maxScrollX, maxScrollY = self:maxScroll()
   local trackX, trackY, trackW, trackH = self:getScrollbarRect(axis)
   local visibleLen   = math.max(1, axis == "vertical" and self.innerH or self.innerW)
   local contentLen   = math.max(1, axis == "vertical" and self.contentH or self.contentW)
   local maxScroll    = axis == "vertical" and maxScrollY or maxScrollX
   local scroll       = axis == "vertical" and (self.scrollY or 0) or (self.scrollX or 0)
   local trackLen     = (axis == "vertical") and trackH or trackW
   local thumbLen     = math.max(1, math.floor((visibleLen / contentLen) * trackLen + 0.5))
   local usableTravel = math.max(0, trackLen - thumbLen)
   local ratio        = (maxScroll > 0) and math.min(1, math.max(0, scroll / maxScroll)) or 0
   local offset       = math.floor(usableTravel * ratio + 0.5)
   local thumbX, thumbY, thumbW, thumbH
   if axis == "vertical" then
      thumbX, thumbY, thumbW, thumbH = trackX, trackY + offset, 1, thumbLen
   else
      thumbX, thumbY, thumbW, thumbH = trackX + offset, trackY, thumbLen, 1
   end
   return {
      axis = axis,
      trackX = trackX, trackY = trackY, trackW = trackW, trackH = trackH,
      visibleLen = visibleLen, contentLen = contentLen, maxScroll = maxScroll,
      thumbLen = thumbLen, usableTravel = usableTravel,
      thumbX = thumbX, thumbY = thumbY, thumbW = thumbW, thumbH = thumbH,
      scroll = scroll,
   }
end

---Paints the container, including background, border, and scrollbars.
---@param ui UI
function UIContainer:paint(ui)
   local style   = ui:getStyle()
   local content = self.className ~= "UIWindow"

   -- Clamp scroll offsets
   self:clampScroll()

   -- Vertical scrollbar
   local gv = self:computeScrollbar("vertical")
   if gv.maxScroll > 0 then
      ui:_bgRect(gv.thumbX, gv.thumbY, gv.thumbW, gv.thumbH, style.scrollbar.thumb, content)
      ui:_bgRect(gv.trackX, gv.trackY, gv.trackW, gv.trackH, style.scrollbar.track, content)
   end

   -- Horizontal scrollbar
   local gh = self:computeScrollbar("horizontal")
   if gh.maxScroll > 0 then
      ui:_bgRect(gh.thumbX, gh.thumbY, gh.thumbW, gh.thumbH, style.scrollbar.thumb, content)
      ui:_bgRect(gh.trackX, gh.trackY, gh.trackW, gh.trackH, style.scrollbar.track, content)
   end

   -- Container background
   if style.container.hasBg then
      print(self.innerX, self.innerY)
      ui:_bgRect(self.innerX, self.innerY, self.innerW, self.innerH, style.container.bg, content)
   end

   -- Container border
   if style.container.hasBorder then
      ui:_border(
         self.absX, self.absY, self.w - 1, self.h - 1,
         style.border.bg,
         style.border.chars,
         style.border.fg,
         style.border.sides,
         content
      )
   end
end


---Handles mouse interaction for both scrollbars and updates scroll state.
---@param ui UI
---@param top boolean
---@param io table
---@param style Style|nil
---@return boolean capturedMouse
function UIContainer:handleScrollbars(ui, top, io, style)
   local capturedMouse = false
   style = ui:getStyle()

   local function processAxis(axis)
      local g = self:computeScrollbar(axis)
      if g.maxScroll <= 0 then
         if axis == "vertical" then self._sbDraggingV = false else self._sbDraggingH = false end
         return false
      end
      local mouseOnThumb = (io.mx >= g.thumbX and io.mx < g.thumbX + g.thumbW
                         and io.my >= g.thumbY and io.my < g.thumbY + g.thumbH)
      local mouseOnTrack = (io.mx >= g.trackX and io.mx < g.trackX + g.trackW
                         and io.my >= g.trackY and io.my < g.trackY + g.trackH)
      if top and io.mpressed and mouseOnThumb then
         if axis == "vertical" then
            self._sbDraggingV = true
            self._sbGrabDY    = io.my - g.thumbY
         else
            self._sbDraggingH = true
            self._sbGrabDX    = io.mx - g.thumbX
         end
         return true
      end
      if top and io.mpressed and mouseOnTrack and not mouseOnThumb then
         if axis == "vertical" then
            if io.my < g.thumbY then
               self.scrollY = g.scroll - math.max(1, self.innerH - 1)
            else
               self.scrollY = g.scroll + math.max(1, self.innerH - 1)
            end
            self.scrollY = math.max(0, math.min(self.scrollY, g.maxScroll))
         else
            if io.mx < g.thumbX then
               self.scrollX = g.scroll - math.max(1, self.innerW - 1)
            else
               self.scrollX = g.scroll + math.max(1, self.innerW - 1)
            end
            self.scrollX = math.max(0, math.min(self.scrollX, g.maxScroll))
         end
         return true
      end
      if axis == "vertical" and self._sbDraggingV then
         if io.mdown then
            local newThumbTop = math.max(g.trackY, math.min(io.my - self._sbGrabDY, g.trackY + g.usableTravel))
            local t           = (g.usableTravel > 0) and ((newThumbTop - g.trackY) / g.usableTravel) or 0
            self.scrollY      = math.floor(t * g.maxScroll + 0.5)
            return true
         end
         if io.mreleased then
            self._sbDraggingV = false
            return true
         end
      elseif axis == "horizontal" and self._sbDraggingH then
         if io.mdown then
            local newThumbLeft = math.max(g.trackX, math.min(io.mx - self._sbGrabDX, g.trackX + g.usableTravel))
            local t            = (g.usableTravel > 0) and ((newThumbLeft - g.trackX) / g.usableTravel) or 0
            self.scrollX       = math.floor(t * g.maxScroll + 0.5)
            return true
         end
         if io.mreleased then
            self._sbDraggingH = false
            return true
         end
      end
      return false
   end
   if processAxis("vertical") then capturedMouse = true end
   if processAxis("horizontal") then capturedMouse = true end
   return capturedMouse
end

return UIContainer
