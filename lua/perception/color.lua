local round = require("perception.utils").round

---@class perception.Color
---@field _r number
---@field _g number
---@field _b number
local Color = {}

---Create a color from a decimal representation.
---This is how colors are returned by `nvim_get_hl`.
---@param n number
---@return perception.Color
function Color:from_number(n)
  return self:from_rgb(
    bit.band(bit.rshift(n, 16), 0xff),
    bit.band(bit.rshift(n, 8), 0xff),
    bit.band(n, 0xff)
  )
end

---Create a color from RGB.
---@param r number [0, 255]
---@param g number [0, 255]
---@param b number [0, 255]
---@return perception.Color
function Color:from_rgb(r, g, b)
  local c = {
    _r = round(r),
    _g = round(g),
    _b = round(b),
  }
  setmetatable(c, self)
  self.__index = self
  return c
end

---Create a color from hexadecimal representation.
---@param h string Hex representation (#______ or 0x______)
---@return perception.Color
function Color:from_hex(h)
  h = h:gsub("^0x", ""):gsub("^#", "")
  return self:from_number(tonumber(h, 16))
end

---Create a color from HSL representation.
---@param h number Hue [0-360]
---@param s number Saturation [0-100]
---@param l number Luminance [0-100]
---@return perception.Color
function Color:from_hsl(h, s, l)
  s = s / 100
  l = l / 100
  local c = (1 - math.abs(2 * l - 1)) * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = l - c / 2
  c = round((c + m) * 255)
  x = round((x + m) * 255)
  m = round(m * 255)
  local rgb_t = {
    { c, x, m },
    { x, c, m },
    { m, c, x },
    { m, x, c },
    { x, m, c },
    { c, m, x },
  }
  return self:from_rgb(unpack(rgb_t[math.floor((h % 360) / 60) + 1]))
end

---Create a color from HSV representation.
---@param h number Hue [0-360]
---@param s number Saturation [0-100]
---@param v number Value [0-100]
---@return perception.Color
function Color:from_hsv(h, s, v)
  s = s / 100
  v = v / 100
  local c = v * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = v - c
  c = round((c + m) * 255)
  x = round((x + m) * 255)
  m = round(m * 255)
  local rgb_t = {
    { c, x, m },
    { x, c, m },
    { m, c, x },
    { m, x, c },
    { x, m, c },
    { c, m, x },
  }
  return self:from_rgb(unpack(rgb_t[math.floor((h % 360) / 60) + 1]))
end

---Get the number representation of color.
---@return number
function Color:as_number()
  local r, g, b = unpack(self:as_rgb())
  return bit.bor(bit.lshift(r, 16), bit.lshift(g, 8), b)
end

---Get the RGB representation of color.
---@return [number, number, number]
function Color:as_rgb()
  return { self._r, self._g, self._b }
end

---Get the hexadecimal representation of color.
---@return string
function Color:as_hex()
  local h = string.format("%x", self:as_number())
  if #h < 6 then
    h = string.rep("0", 6 - #h) .. h
  end
  return string.format("#%s", h)
end

---Get the HSL representation of color.
---@return [number, number, number]
function Color:as_hsl()
  local r, g, b = unpack(self:as_rgb())
  r = r / 255
  g = g / 255
  b = b / 255
  local c_max = math.max(r, g, b)
  local c_min = math.min(r, g, b)
  local d = c_max - c_min
  local h, s
  local l = (c_max + c_min) / 2
  if d == 0 then
    h = 0
  elseif c_max == r then
    h = 60 * (((g - b) / d) % 6)
  elseif c_max == g then
    h = 60 * (((b - r) / d) + 2)
  elseif c_max == b then
    h = 60 * (((r - g) / d) + 4)
  end
  if d == 0 then
    s = 0
  else
    s = d / (1 - math.abs(2 * l - 1))
  end
  return { h % 360, s * 100, l * 100 }
end

---Get the HSV representation of color.
---@return [number, number, number]
function Color:as_hsv()
  local r, g, b = unpack(self:as_rgb())
  r = r / 255
  g = g / 255
  b = b / 255
  local c_max = math.max(r, g, b)
  local c_min = math.min(r, g, b)
  local d = c_max - c_min
  local h, s
  local v = c_max
  if d == 0 then
    h = 0
  elseif c_max == r then
    h = 60 * (((g - b) / d) % 6)
  elseif c_max == g then
    h = 60 * (((b - r) / d) + 2)
  elseif c_max == b then
    h = 60 * (((r - g) / d) + 4)
  end
  if c_max == 0 then
    s = 0
  else
    s = d / c_max
  end
  return { h % 360, s * 100, v * 100 }
end

---Apply a function on R, G and B values of color and return a new color.
---@param f fun(c: number): number
---@return perception.Color
function Color:apply_rgb(f)
  local r, g, b = unpack(self:as_rgb())
  return self:from_rgb(f(r), f(g), f(b))
end

return Color
