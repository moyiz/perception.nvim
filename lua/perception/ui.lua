local truncate = require("perception.utils").truncate
local normalize = require("perception.utils").normalize
local center = require("perception.utils").center

---@class perception.ui.Event
---@field context any

---@class perception.ui.KEY_PRESSED : perception.ui.Event
---@field context {key: string}

---@class perception.ui.Position
---@field row integer
---@field col integer

---@class perception.ui.Widget
local Widget = {}

---@param buffer integer
---@param pos perception.ui.Position
function Widget:render(buffer, pos)
  --
end

---[<label>][##########|----------][<min>|<value>|<max>]
---@class perception.ui.Slider
---@field label string
---@field label_width number Label will be padded or truncated.
---@field slider_width number Width of the slider part.
---@field range_width number Width of the range part.
---@field min_value number
---@field max_value number
---@field step number Default step for `increase`. Negated for `decrease`.
---@field current number The current value of the slider.
---@field callback fun(value: number) Callback for `increase` and `decrease`.
local Slider = {}

function Slider:init(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

---Increases slider value.
---@param val? number Value to add. `nil` and `zero` will be treated as `step`.
function Slider:increase(val)
  if not val or val == 0 then
    val = self.step
  end
  self.current = truncate(self.current + val, self.max_value, self.min_value)
  self.callback(self.current)
end

---Decreases slider value.
---@param val? number Value to decrease. `nil` and `zero` will be treated as `step`.
function Slider:decrease(val)
  if not val or val == 0 then
    val = self.step
  end
  self:increase(-val)
end

function Slider:set(val)
  if not val then
    val = math.floor((self.max_value + self.min_value) / 2)
  end
  self.current = truncate(val, self.max_value, self.min_value)
  self.callback(self.current)
end

function Slider:_generate_label()
  local pad = self.label_width - #self.label - 2
  return "["
    .. string.rep(" ", math.floor(pad / 2))
    .. self.label:sub(1, self.label_width - 2)
    .. string.rep(" ", math.ceil(pad / 2))
    .. "]"
end

function Slider:_generate_bar()
  local val = math.floor(
    normalize(
      self.current,
      self.min_value,
      self.max_value,
      0,
      self.slider_width - 2
    )
  )
  local s = "["
  for i = 0, self.slider_width - 3 do
    if i < val then
      s = s .. "#"
    elseif i == val then
      s = s .. "|"
    else
      s = s .. "-"
    end
  end
  s = s .. "]"
  return s
end

function Slider:_generate_range()
  local part_width = math.floor((self.range_width - 4) / 3)
  local min_pad = part_width - #tostring(self.min_value)
  local max_pad = part_width - #tostring(self.max_value)
  local cur_pad = part_width - #tostring(self.current)
  return "["
    .. center(self.min_value, min_pad)
    .. "|"
    .. center(self.current, cur_pad)
    .. "|"
    .. center(self.max_value, max_pad)
    .. "]"
end

---Renders the slider in given buffer at specified position.
---@param buffer integer
---@param pos perception.ui.Position
function Slider:render(buffer, pos)
  local label = self:_generate_label()
  local bar = self:_generate_bar()
  local range = self:_generate_range()
  local line = label .. bar .. range
  vim.api.nvim_buf_set_lines(buffer, pos.row - 1, pos.row, false, { line })
end

---@alias perception.ui.key_handlers table<perception.ui.key, perception.ui.key | perception.ui.handler>

---@alias perception.ui.key string
---@alias perception.ui.handler fun(w: perception.ui.Widget)

---@class perception.ui.UI
---@field buffer? integer
---@field window? integer
---@field win_config vim.api.keyset.win_config
---@field widgets? perception.ui.Widget[]
---@field key_handlers? perception.ui.key_handlers
local UI = {}

function UI:init(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.buffer = nil
  self.window = nil
  self.win_config = o.win_config
  self.widgets = o.widgets or {}
  return o
end

---Redraws window and sets cursor to its last position.
function UI:redraw()
  if not self.window then
    return
  end
  local cursor_pos = vim.api.nvim_win_get_cursor(self.window)
  if self:_ensure_buffer_valid() then
    -- Clear buffer
    vim.api.nvim_buf_set_lines(self.buffer, 0, -1, false, {})
  end
  -- Horizontal layout
  for i, widget in ipairs(self.widgets) do
    widget:render(self.buffer, { row = i, col = 0 })
  end
  -- vim.cmd.redraw()
  vim.api.nvim_win_set_cursor(self.window, cursor_pos)
end

---@param widget perception.ui.Widget
function UI:add_widget(widget)
  table.insert(self.widgets, widget)
end

---@param win_config? vim.api.keyset.win_config
function UI:show(win_config)
  local config = vim.tbl_deep_extend("force", self.win_config, win_config or {})
  if self.window ~= nil and vim.api.nvim_win_is_valid(self.window) then
    vim.api.nvim_win_close(self.window, true)
  end
  self:_ensure_buffer_valid()
  self:_create_window(self.buffer, config)
  self:redraw()
  vim.api.nvim_set_current_win(self.window)
end

---Create a window with preset options.
function UI:_create_window(buf, config)
  self.window = vim.api.nvim_open_win(buf, false, config)
  vim.api.nvim_set_option_value("signcolumn", "no", { win = self.window })
  return self
end

---Ensure that `self.buffer` is a valid buffer handle.
function UI:_ensure_buffer_valid()
  if not self.buffer or not vim.api.nvim_buf_is_valid(self.buffer) then
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "perception#" .. buf)
    -- Scratch buffer
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buf })
    vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
    -- Unlisted
    vim.api.nvim_set_option_value("buflisted", false, { buf = buf })
    -- Prepare empty lines
    vim.api.nvim_buf_set_lines(
      buf,
      0,
      0,
      false,
      vim.split(string.rep(" ", #self.widgets - 1), " ")
    )
    -- Key handlers
    for key, handler in pairs(self.key_handlers) do
      vim.keymap.set("n", key, function()
        if type(handler) == "string" then
          handler = self.key_handlers[handler]
        end
        local row, col = unpack(vim.api.nvim_win_get_cursor(self.window))
        local w = self:_get_widget_in_pos(row, col)
        if w then
          handler(w)
          w:render(buf, { row = row, col = 0 })
        end
      end, { buffer = buf })
    end
    vim.api.nvim_create_autocmd({ "BufLeave" }, {
      buffer = buf,
      once = true,
      callback = function()
        self:close()
      end,
    })
    self.buffer = buf
    return false
  end
  return true
end

function UI:_get_widget_in_pos(row, _)
  return self.widgets[row]
end

function UI:close()
  if vim.api.nvim_win_is_valid(self.window) then
    vim.api.nvim_win_close(self.window, true)
  end
  self.window = nil
end

---Toggles UI window.
---@param win_config? vim.api.keyset.win_config
function UI:toggle(win_config)
  if self.window ~= nil then
    self:close()
  else
    self:show(win_config)
  end
end

return {
  UI = UI,
  Slider = Slider,
}
