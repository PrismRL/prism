--- @param self UI
--- @param label string|nil
--- @param value number
--- @param min number
--- @param max number
--- @param w integer|nil
--- @param opts { style?: Style, fmt?: string }|nil
--- @return number newValue
--- @return boolean changed
local function slider(self, label, value, min, max, w, opts)
   if max == min then max = min + 1 end
   local prev = value
   if value < min then value = min elseif value > max then value = max end

   if opts and opts.style then self:pushStyle(opts.style) end
   local style = self:getStyle()

   local totalW = w or style.layout.itemW
   local x, y, iw, ih = self:_itemRect(totalW, 1)

   self:pushID(("slider@%d,%d:%s"):format(x, y, tostring(label or "")))
   local id = self:makeID()

   -- Geometry
   local trackX, trackY = x, y
   local trackW, trackH = w, 1
   local thumbW, thumbH = style.slider.thumbW, trackH

   local function clamp(v) return math.max(min, math.min(max, v)) end
   local function toPos(v)
      local t = (v - min) / (max - min)
      return trackX + math.floor(t * math.max(0, trackW - thumbW))
   end
   local function toValue(mx)
      local t = (mx - trackX) / math.max(1, (trackW - thumbW))
      return clamp(min + t * (max - min))
   end

   -- Interaction
   local hovered, active = false, false
   if self:_scopeAcceptsMouse() then
      hovered = self:_mouseOver(trackX, trackY, trackW, trackH)
      if hovered and self.io.mpressed then
         self.active = id
         value = toValue(self.io.mx)
      end
      if self.active == id then
         self:setMouseCursor("sizewe")
         active = true
         value = toValue(self.io.mx)
         if self.io.mreleased then self.active = nil end
      end
      if hovered then self.hot = id end
   end

   -- Centered value on track
   local valueText = string.format(opts and opts.fmt or "%.2f", value)
   self:_text(trackX, y, valueText, style.colors.textDim, "center", trackW)


   local thumbX = toPos(value)
   self:_bgRect(
      thumbX, trackY, thumbW, thumbH,
      (active and style.slider.active)
      or (self.hot == id and style.slider.hot)
      or style.slider.thumb
   )

   -- Draw
   self:_bgRect(trackX, trackY, trackW, trackH, style.slider.track)


   -- Label to the right
   if label then
      local lx = trackX + trackW + 1
      self:_text(lx, y, label, style.colors.text, "left", #label)
   end

   self:_advanceCursor(iw, ih)
   self:popID()
   if opts and opts.style then self:popStyle() end

   return value, (value ~= prev)
end

return slider
