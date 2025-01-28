local normalize = require("perception.utils").normalize
local truncate = require("perception.utils").truncate

local M = {}

---@param color perception.Color
---@param value number
---@return perception.Color
M.dim = function(color, value)
  local factor = (value / 255) + 1
  return color:apply_rgb(function(c)
    return truncate(c * factor)
  end)
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.brightness = function(color, value)
  return color:apply_rgb(function(c)
    return truncate(c + value)
  end)
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.contrast = function(color, value)
  local contrast = (259 * (255 + value)) / (255 * (259 - value))
  return color:apply_rgb(function(c)
    return truncate(contrast * (c - 128) + 128)
  end)
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.red = function(color, value)
  local r, g, b = unpack(color:as_rgb())
  return color:from_rgb(truncate(r + value, 255), g, b)
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.green = function(color, value)
  local r, g, b = unpack(color:as_rgb())
  return color:from_rgb(r, truncate(g + value, 255), b)
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.blue = function(color, value)
  local r, g, b = unpack(color:as_rgb())
  return color:from_rgb(r, g, truncate(b + value, 255))
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.hue = function(color, value)
  local h, s, l = unpack(color:as_hsl())
  return color:from_hsl(truncate(h * (value / 360 + 1), 360), s, l)
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.hsl_saturation = function(color, value)
  local h, s, l = unpack(color:as_hsl())
  return color:from_hsl(h, truncate(s * (value / 100 + 1), 100), l)
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.hsv_saturation = function(color, value)
  local h, s, v = unpack(color:as_hsv())
  return color:from_hsv(h, truncate(s * (value / 100 + 1), 100), v)
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.luminance = function(color, value)
  local h, s, l = unpack(color:as_hsl())
  return color:from_hsl(h, s, truncate(l * (value / 100 + 1), 100))
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.value = function(color, value)
  local h, s, v = unpack(color:as_hsv())
  return color:from_hsv(h, s, truncate(v * (value / 100 + 1), 100))
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.temperature = function(color, value)
  local r, g, b = unpack(color:as_rgb())
  return color:from_rgb(truncate(r + value, 255), g, truncate(b - value))
end

M.tint = M.green

-- ---@param color perception.Color
-- ---@param value number
-- M.invert = function(color, value)
--   return color:apply_rgb(function(c)
--     return value % 2 == 0 and c or 255 - c
--   end)
-- end

---@param color perception.Color
---@param value number
---@return perception.Color
M.inversion = function(color, value)
  return color:apply_rgb(function(c)
    return normalize(value, 0, 100, c, 255 - c)
  end)
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.grayscale = function(color, value)
  if value % 2 == 0 then
    return color
  end
  local r, g, b = unpack(color:as_rgb())
  local gray = math.floor((r + g + b) / 3)
  return color:from_rgb(gray, gray, gray)
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.sepia = function(color, value)
  if value ~= 0 then
    color = M.grayscale(color, 1)
    local g = color:as_rgb()[1]
    return color:from_rgb(g + (value * 2), g + value, g)
  end
  return color
end

---@param color perception.Color
---@param value number
---@return perception.Color
M.sepia_intensity = function(color, value)
  return M.blue(color, -value)
end

return M
