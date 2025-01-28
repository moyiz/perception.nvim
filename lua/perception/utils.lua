local function redraw_cur_win()
  vim.api.nvim__redraw {
    win = vim.api.nvim_get_current_win(),
    flush = true,
    valid = false,
  }
end

---Truncates a number into the given limits.
---@return number
local function truncate(n, max, min)
  max = max or 255
  min = min or 0
  if n > max then
    return max
  end
  if n < min then
    return min
  end
  return n
end

---Normalizes a number into new bounds.
---@return number
local function normalize(n, n_min, n_max, target_min, target_max)
  n = truncate(n, n_max, n_min)
  return (n - n_min) / (n_max - n_min) * (target_max - target_min) + target_min
end

---Rounds a number to its nearest non-fraction.
local function round(x)
  return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

---Align a string to the center of given width.
local function center(s, width)
  return string.rep(" ", math.floor(width / 2))
    .. s
    .. string.rep(" ", math.ceil(width / 2))
end

return {
  center = center,
  round = round,
  redraw_cur_win = redraw_cur_win,
  truncate = truncate,
  normalize = normalize,
}
