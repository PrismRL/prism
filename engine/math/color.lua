local bit = require("bit")

--- A color with red, green, blue, and alpha components.
--- @class Color4 : Object
--- @field r number The red component (0–1).
--- @field g number The green component (0–1).
--- @field b number The blue component (0–1).
--- @field a number The alpha component (0–1).
--- @overload fun(r?: number, g?: number, b?: number, a?: number): Color4
local Color4 = prism.Object:extend("Color4")

--- Creates a new Color4.
--- @param r number? Red component (0–1)
--- @param g number? Green component (0–1)
--- @param b number? Blue component (0–1)
--- @param a number? Alpha component (0–1), defaults to 1
function Color4:__new(r, g, b, a)
   self.r = r or 0
   self.g = g or 0
   self.b = b or 0
   self.a = a or 1
end

--- Creates a Color4 from a hexadecimal color value.
--- Accepts RGB (0xRRGGBB) or RGBA (0xRRGGBBAA).
--- Allocates a new Color4.
--- @param hex number Hexadecimal color value
--- @return Color4
function Color4.fromHex(hex)
   local hasAlpha = #string.format("%x", hex) > 6

   local a = bit.band(bit.rshift(hex, 0), 0xff) / 0xff
   local b = bit.band(bit.rshift(hex, hasAlpha and 8 or 0), 0xff) / 0xff
   local g = bit.band(bit.rshift(hex, hasAlpha and 16 or 8), 0xff) / 0xff
   local r = bit.band(bit.rshift(hex, hasAlpha and 24 or 16), 0xff) / 0xff

   return Color4(r, g, b, hasAlpha and a or 1)
end

--- Copies a color.
--- Allocates a new Color4 if `out` is nil.
--- @param a Color4 Source color
--- @param out Color4? Optional output color
--- @return Color4 out
function Color4.copy(a, out)
   out = out or Color4()
   out.r, out.g, out.b, out.a = a.r, a.g, a.b, a.a
   return out
end

--- Writes components directly into an existing color.
--- Does not allocate.
--- @param out Color4 Destination color
--- @param r number
--- @param g number
--- @param b number
--- @param a number
--- @return Color4 out
function Color4.compose(out, r, g, b, a)
   out.r, out.g, out.b, out.a = r, g, b, a
   return out
end

--- Adds two colors component-wise.
--- Allocates a new Color4 if `out` is nil.
--- @param a Color4
--- @param b Color4
--- @param out Color4? Optional output color
--- @return Color4 out
function Color4.add(a, b, out)
   out = out or Color4()
   out.r = a.r + b.r
   out.g = a.g + b.g
   out.b = a.b + b.b
   out.a = a.a + b.a
   return out
end

--- Subtracts one color from another component-wise.
--- Allocates a new Color4 if `out` is nil.
--- @param a Color4
--- @param b Color4
--- @param out Color4? Optional output color
--- @return Color4 out
function Color4.sub(a, b, out)
   out = out or Color4()
   out.r = a.r - b.r
   out.g = a.g - b.g
   out.b = a.b - b.b
   out.a = a.a - b.a
   return out
end

--- Multiplies a color by a scalar.
--- Allocates a new Color4 if `out` is nil.
--- @param a Color4
--- @param s number Scalar value
--- @param out Color4? Optional output color
--- @return Color4 out
function Color4.mul(a, s, out)
   out = out or Color4()
   out.r = a.r * s
   out.g = a.g * s
   out.b = a.b * s
   out.a = a.a * s
   return out
end

--- Divides a color by a scalar.
--- Allocates a new Color4 if `out` is nil.
--- @param a Color4
--- @param s number Scalar divisor
--- @param out Color4? Optional output color
--- @return Color4 out
function Color4.div(a, s, out)
   out = out or Color4()
   out.r = a.r / s
   out.g = a.g / s
   out.b = a.b / s
   out.a = a.a / s
   return out
end

--- Negates all components of a color.
--- Allocates a new Color4 if `out` is nil.
--- @param a Color4
--- @param out Color4? Optional output color
--- @return Color4 out
function Color4.neg(a, out)
   out = out or Color4()
   out.r = -a.r
   out.g = -a.g
   out.b = -a.b
   out.a = -a.a
   return out
end

--- Linearly interpolates between two colors.
--- Allocates a new Color4 if `out` is nil.
--- @param a Color4 Start color
--- @param b Color4 End color
--- @param t number Interpolation factor (0–1)
--- @param out Color4? Optional output color
--- @return Color4 out
function Color4.lerp(a, b, t, out)
   out = out or Color4()
   out.r = a.r + (b.r - a.r) * t
   out.g = a.g + (b.g - a.g) * t
   out.b = a.b + (b.b - a.b) * t
   out.a = a.a + (b.a - a.a) * t
   return out
end

--- Clamps all components of a color to the range [0, 1].
--- Allocates a new Color4 if `out` is nil.
--- @param a Color4
--- @param out Color4? Optional output color
--- @return Color4 out
function Color4.clamp(a, out)
   out = out or Color4()
   out.r = math.min(1, math.max(0, a.r))
   out.g = math.min(1, math.max(0, a.g))
   out.b = math.min(1, math.max(0, a.b))
   out.a = math.min(1, math.max(0, a.a))
   return out
end

--- Adds two colors.
--- Always allocates a new Color4.
--- @param a Color4
--- @param b Color4
--- @return Color4
function Color4.__add(a, b)
   return Color4.add(a, b)
end

--- Subtracts two colors.
--- Always allocates a new Color4.
--- @param a Color4
--- @param b Color4
--- @return Color4
function Color4.__sub(a, b)
   return Color4.sub(a, b)
end

--- Multiplies a color by a scalar.
--- Always allocates a new Color4.
--- @param a Color4
--- @param s number
--- @return Color4
function Color4.__mul(a, s)
   return Color4.mul(a, s)
end

--- Divides a color by a scalar.
--- Always allocates a new Color4.
--- @param a Color4
--- @param s number
--- @return Color4
function Color4.__div(a, s)
   return Color4.div(a, s)
end

--- Negates a color.
--- Always allocates a new Color4.
--- @param a Color4
--- @return Color4
function Color4.__unm(a)
   return Color4.neg(a)
end

--- Checks component-wise equality.
--- @param a Color4
--- @param b Color4
--- @return boolean
function Color4.__eq(a, b)
   return a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a
end

--- Returns the average of the RGB components.
--- Does not allocate.
--- @return number
function Color4:average()
   return (self.r + self.g + self.b) / 3
end

--- Returns the components as separate values.
--- Does not allocate.
--- @return number r
--- @return number g
--- @return number b
--- @return number a
function Color4:decompose()
   return self.r, self.g, self.b, self.a
end

--- Returns a human-readable string representation.
--- Does not allocate a Color4.
--- @return string
function Color4:__tostring()
   return string.format("r: %.2f, g: %.2f, b: %.2f, a: %.2f", self.r, self.g, self.b, self.a)
end

-- stylua: ignore start
Color4.BLACK       = Color4(0, 0, 0, 1)
Color4.WHITE       = Color4.fromHex(0xFFF1E8)
Color4.RED         = Color4.fromHex(0xFF004D)
Color4.GREEN       = Color4.fromHex(0x008751)
Color4.LIME        = Color4.fromHex(0x00E436)
Color4.BLUE        = Color4.fromHex(0x29ADFF)
Color4.NAVY        = Color4.fromHex(0x1D2B53)
Color4.PURPLE      = Color4.fromHex(0x7E2553)
Color4.BROWN       = Color4.fromHex(0xAB5236)
Color4.DARKGREY    = Color4.fromHex(0x5F574F)
Color4.GREY        = Color4.fromHex(0xC2C3C7)
Color4.YELLOW      = Color4.fromHex(0xFFEC27)
Color4.ORANGE      = Color4.fromHex(0xFFA300)
Color4.PINK        = Color4.fromHex(0xFF77A8)
Color4.LAVENDER    = Color4.fromHex(0x83769C)
Color4.PEACH       = Color4.fromHex(0xFFCCAA)
Color4.TRANSPARENT = Color4(0, 0, 0, 0)
-- stylua: ignore end

return Color4
