---Defines general color fields for text and dimmed text.
---@class StyleColors
---@field text Color4?
---@field textDim Color4?

---Defines layout parameters for padding, spacing, and item sizing.
---@class StyleLayout
---@field padX integer?
---@field padY integer?
---@field spacingX integer?
---@field spacingY integer?
---@field itemW integer?
---@field itemH integer?
---@field titleH integer?

---Defines visual and structural parameters for containers.
---@class StyleContainer
---@field bg Color4?
---@field hasBg boolean?
---@field hasBorder boolean?
---@field autoSize boolean?
---@field padding integer?
---@field padXLeft integer?
---@field padXRight integer?
---@field padYTop integer?
---@field padYBottom integer?
---@field layoutDir ("vertical"|"horizontal")?

---Defines appearance for window panels and titles.
---@class StyleWindow
---@field panelBg Color4?
---@field titleBg Color4?
---@field titleFg Color4?
---@field titleAlign ("left"|"center"|"right")?
---@field titleH integer?

---Specifies which sides of a border are drawn.
---@class StyleBorderToggles
---@field top boolean?
---@field left boolean?
---@field right boolean?
---@field bottom boolean?

---Defines the characters used for border drawing.
---@class StyleBorderChars
---@field v string?
---@field h string?
---@field tl string?
---@field tr string?
---@field bl string?
---@field br string?

---Defines the colors and characters used for borders.
---@class StyleBorder
---@field fg Color4?
---@field bg Color4?
---@field chars StyleBorderChars?
---@field sides StyleBorderToggles?

---Defines scrollbar appearance.
---@class StyleScrollbar
---@field track Color4?
---@field thumb Color4?
---@field thickness integer?

---Defines appearance and behavior of buttons.
---@class StyleButton
---@field bg Color4?
---@field fg Color4?
---@field hotBg Color4?
---@field activeBg Color4?
---@field padX integer?
---@field h integer?
---@field align ("left"|"center"|"right")?

---Defines appearance of text input widgets.
---@class StyleTextInput
---@field bg Color4?
---@field fg Color4?
---@field placeholderFg Color4?
---@field caretColor Color4?
---@field pad integer?
---@field caretGlyph string?
---@field blinkFrames integer?
---@field blinkOnFrames integer?
---@field reserveCaretCol boolean?

---Defines list widget colors and row layout.
---@class StyleList
---@field fg Color4?
---@field rowBgA Color4?
---@field rowBgB Color4?
---@field hotBg Color4?
---@field selBg Color4?
---@field rowH integer?
---@field padX integer?
---@field striped boolean?

---Defines checkbox widget appearance.
---@class StyleCheckbox
---@field bg Color4?
---@field hotBg Color4?
---@field activeBg Color4?
---@field fg Color4?
---@field labelFg Color4?
---@field boxSize integer?
---@field spacing integer?
---@field mark string?

---Defines slider widget colors and dimensions.
---@class StyleSlider
---@field track Color4?
---@field thumb Color4?
---@field hot Color4?
---@field active Color4?
---@field valueFg Color4?
---@field trackH integer?
---@field thumbW integer?

---Top-level structure containing all style categories.
---@class Style
---@field colors StyleColors?
---@field layout StyleLayout?
---@field border StyleBorder?
---@field container StyleContainer?
---@field window StyleWindow?
---@field button StyleButton?
---@field textinput StyleTextInput?
---@field list StyleList?
---@field scrollbar StyleScrollbar?
---@field checkbox StyleCheckbox?
---@field slider StyleSlider?

---Default style definition.
---@type Style
local default = {
   colors = {
      text    = prism.Color4(1, 1, 1, 1),
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
      bg = prism.Color4(0.33, 0.33, 0.40, 1),
      chars = { v = " ", h = " ", tl = " ", tr = " ", bl = " ", br = " " },
      sides = { left = true, right = true, top = true, bottom = true },
   },

   container = {
      bg = prism.Color4(0.14, 0.14, 0.16, 1),
      hasBg = true,
      hasBorder = true,
      autoSize = false,
      padding = 0,
      layoutDir = "vertical",
   },

   window = {
      bg = prism.Color4(0.14, 0.14, 0.16, 1),
      panelBg = prism.Color4(0.10, 0.10, 0.12, 1),
      titleBg = prism.Color4(0.16, 0.16, 0.20, 1),
      titleFg = prism.Color4(1, 1, 1, 1),
      titleAlign = "left",
      titleH = 1,
   },

   button = {
      bg       = prism.Color4(0.18, 0.18, 0.22, 1),
      fg       = prism.Color4(1, 1, 1, 1),
      hotBg    = prism.Color4(0.22, 0.22, 0.26, 1),
      activeBg = prism.Color4(0.34, 0.34, 0.40, 1),
      padX     = 1,
      h        = nil,
      align    = "center",
   },

   textinput = {
      bg              = prism.Color4(0.20, 0.18, 0.22, 1),
      fg              = prism.Color4(1, 1, 1, 1),
      placeholderFg   = prism.Color4(0.70, 0.70, 0.74, 1),
      caretColor      = prism.Color4(0.95, 0.95, 0.20, 1),
      pad             = 0,
      caretGlyph      = "|",
      blinkFrames     = 180,
      blinkOnFrames   = 90,
      reserveCaretCol = true,
   },

   list = {
      fg      = prism.Color4(1, 1, 1, 1),
      rowBgA  = prism.Color4(0.13, 0.13, 0.15, 1),
      rowBgB  = prism.Color4(0.11, 0.11, 0.13, 1),
      hotBg   = prism.Color4(0.22, 0.22, 0.26, 1),
      selBg   = prism.Color4(0.34, 0.34, 0.40, 1),
      rowH    = 1,
      padX    = 1,
      striped = true,
   },

   scrollbar = {
      track = prism.Color4(0.20, 0.20, 0.24, 1),
      thumb = prism.Color4(0.34, 0.34, 0.40, 1),
      thickness = 1,
   },

   checkbox = {
      bg       = prism.Color4(0.18, 0.18, 0.22, 1),
      hotBg    = prism.Color4(0.22, 0.22, 0.26, 1),
      activeBg = prism.Color4(0.34, 0.34, 0.40, 1),
      fg       = prism.Color4(1.00, 1.00, 1.00, 1),
      labelFg  = prism.Color4(1.00, 1.00, 1.00, 1),
      boxSize  = nil,
      spacing  = 1,
      mark     = "X",
   },

   slider = {
      track   = prism.Color4(0.20, 0.20, 0.24, 1),
      thumb   = prism.Color4(0.34, 0.34, 0.40, 1),
      hot     = prism.Color4(0.22, 0.22, 0.26, 1),
      active  = prism.Color4(0.40, 0.40, 0.46, 1),
      valueFg = prism.Color4(1, 1, 1, 1),
      trackH  = 3,
      thumbW  = 1,
   },
}

return default