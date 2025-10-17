local palette = {
   prism.Color4.fromHex(0xbe4a2f),
   prism.Color4.fromHex(0xd77643),
   prism.Color4.fromHex(0xead4aa),
   prism.Color4.fromHex(0xe4a672),
   prism.Color4.fromHex(0xb86f50),
   prism.Color4.fromHex(0x733e39),
   prism.Color4.fromHex(0x3e2731),
   prism.Color4.fromHex(0xa22633),
   prism.Color4.fromHex(0xe43b44),
   prism.Color4.fromHex(0xf77622),
   prism.Color4.fromHex(0xfeae34),
   prism.Color4.fromHex(0xfee761),
   prism.Color4.fromHex(0x63c74d),
   prism.Color4.fromHex(0x3e8948),
   prism.Color4.fromHex(0x265c42),
   prism.Color4.fromHex(0x193c3e),
   prism.Color4.fromHex(0x124e89),
   prism.Color4.fromHex(0x0099db),
   prism.Color4.fromHex(0x2ce8f5),
   prism.Color4.fromHex(0xffffff),
   prism.Color4.fromHex(0xc0cbdc),
   prism.Color4.fromHex(0x8b9bb4),
   prism.Color4.fromHex(0x5a6988),
   prism.Color4.fromHex(0x3a4466),
   prism.Color4.fromHex(0x262b44),
   prism.Color4.fromHex(0x181425),
   prism.Color4.fromHex(0xff0044),
   prism.Color4.fromHex(0x68386c),
   prism.Color4.fromHex(0xb55088),
   prism.Color4.fromHex(0xf6757a),
   prism.Color4.fromHex(0xe8b796),
   prism.Color4.fromHex(0xc28569),
}

---Default style definition.
---@type Style
local default = {
   colors = {
      text = prism.Color4.WHITE,
      textDim = prism.Color4(0.82, 0.82, 0.85, 1),
   },

   layout = {
      padX = 0,
      padY = 0,
      spacingX = 1,
      spacingY = 0,
      itemW = 12,
      itemH = 1,
   },

   border = {
      fg = prism.Color4.WHITE,
      bg = palette[25],
      chars = { v = " ", h = " ", tl = " ", tr = " ", bl = " ", br = " " },
      sides = { left = true, right = true, top = true, bottom = true },
   },

   window = {
      bg = palette[25],
      panelBg = palette[25],
      titleBg = prism.Color4(0.16, 0.16, 0.20, 1),
      titleFg = prism.Color4(1, 1, 1, 1),
      titleAlign = "left",
      titleH = 1,
   },

   container = {
      bg = palette[25],
      hasBg = true,
      hasBorder = true,
      autoSize = false,
      padding = 0,
      layoutDir = "vertical",
   },

   button = {
      bg = palette[18],
      fg = prism.Color4.WHITE,
      hotBg = palette[18] * 0.9,
      activeBg = palette[18] * 0.7,
      padX = 1,
      h = nil,
      align = "center",
   },

   textinput = {
      bg = prism.Color4(0.20, 0.18, 0.22, 1),
      fg = prism.Color4(1, 1, 1, 1),
      placeholderFg = prism.Color4(0.70, 0.70, 0.74, 1),
      caretColor = prism.Color4(0.95, 0.95, 0.20, 1),
      pad = 0,
      caretGlyph = "|",
      blinkFrames = 180,
      blinkOnFrames = 90,
      reserveCaretCol = true,
   },

   list = {
      fg = prism.Color4(1, 1, 1, 1),
      rowBgA = prism.Color4(0.13, 0.13, 0.15, 1),
      rowBgB = prism.Color4(0.11, 0.11, 0.13, 1),
      hotBg = prism.Color4(0.22, 0.22, 0.26, 1),
      selBg = prism.Color4(0.34, 0.34, 0.40, 1),
      rowH = 1,
      padX = 1,
      striped = true,
   },

   scrollbar = {
      track = prism.Color4(0.20, 0.20, 0.24, 1),
      thumb = prism.Color4(0.34, 0.34, 0.40, 1),
      thickness = 1,
   },

   checkbox = {
      bg = prism.Color4(0.18, 0.18, 0.22, 1),
      hotBg = prism.Color4(0.22, 0.22, 0.26, 1),
      activeBg = prism.Color4(0.34, 0.34, 0.40, 1),
      fg = prism.Color4(1.00, 1.00, 1.00, 1),
      labelFg = prism.Color4(1.00, 1.00, 1.00, 1),
      boxSize = nil,
      spacing = 1,
      mark = "X",
   },

   slider = {
      track = prism.Color4(0.20, 0.20, 0.24, 1),
      thumb = prism.Color4(0.34, 0.34, 0.40, 1),
      hot = prism.Color4(0.22, 0.22, 0.26, 1),
      active = prism.Color4(0.40, 0.40, 0.46, 1),
      valueFg = prism.Color4(1, 1, 1, 1),
      trackH = 3,
      thumbW = 1,
   },
}

local mainPanel = {
   container = {
      bg = palette[16],
   },

   window = {
      bg = palette[16],
   },

   border = {
      bg = palette[16],
   },
}

local playButton = {
   button = { bg = palette[13] },
}

return { default = default, mainPanel = mainPanel, playButton = playButton }
