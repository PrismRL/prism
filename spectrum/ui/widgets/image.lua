--- Draws a clickable image region.
--- Returns true when clicked.
--- @param self UI
--- @param texture love.graphics.Texture
--- @param quad love.graphics.Quad
--- @param w integer|nil  -- in cells
--- @param h integer|nil  -- in cells
--- @return boolean clicked
local function image(self, texture, quad, w, h)
   local style = self:getStyle()
   local x, y, iw, ih = self:_itemRect(w or style.layout.itemW, h or style.layout.itemH)

   self:pushID(("image@%d,%d"):format(x, y))
   local id = self:makeID()

   local clicked = false

   if self:_scopeAcceptsMouse() then
      local hovered = self:_mouseOver(x, y, iw, ih)
      if hovered then
         self.hot = id
         if self.io.mpressed then
            self.active = id
         end
      end

      if self.active == id and self.io.mreleased then
         if hovered then clicked = true end
         self.active = nil
      end
   end

   -- Draw background and image
   self:_image(x, y, iw, ih, texture, quad, "fit", prism.Color4.WHITE, true)

   self:_advanceCursor(iw, ih)
   self:popID()

   return clicked
end

return image
