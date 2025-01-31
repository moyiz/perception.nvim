local Color = require "perception.color"
local Config = require "perception.config"
local redraw_cur_win = require("perception.utils").redraw_cur_win
local truncate = require("perception.utils").truncate
local UI = require("perception.ui").UI
local Slider = require("perception.ui").Slider

local M = {}

---@type perception.Config
M.config = nil

---@class perception.state.Filter
---@field value number
---@field widget perception.ui.Slider
---@field callback fun(state: perception.state.Filter) Trigger on value change.

---@class perception.State
---@field enabled boolean Whether color adjustments are enabled or not.
---@field ordering string[] An ordered list (by priority) of enabled filters.
---@field filters table<string, perception.state.Filter>

---@type perception.State
local _state = nil

---Holds the original highlight groups. Used as a source for filter appliance.
---@type table<string, vim.api.keyset.highlight>
local _orig_hl_groups = nil

---@type perception.ui.UI
M.ui = nil

---Applies custom options and enables brightness adjustments.
M.setup = function(opts)
  _state = { ordering = {}, filters = {} }
  M.config = Config.new(opts)
  -- Initialize filters
  for name, filter in pairs(M.config.filters) do
    filter = vim.tbl_deep_extend("keep", filter, M.config.base)
    if filter.enabled == true then
      table.insert(_state.ordering, name)
    end
    M.config.filters[name] = filter
  end
  -- Sort by priority in descending order.
  table.sort(_state.ordering, function(left, right)
    return M.config.filters[left].priority > M.config.filters[right].priority
  end)
  -- Setup UI
  local widgets = {}
  -- Get the maximum width for filter labels
  local label_width = math.max(unpack(vim.tbl_map(function(i)
    return #i
  end, _state.ordering))) + 2
  -- Get the maximum width for filter ranges
  local range_width = math.max(unpack(vim.tbl_map(function(name)
    local filter = M.config.filters[name]
    return math.max(#tostring(filter.level.min), #tostring(filter.level.max))
  end, _state.ordering))) * 3 + 4
  -- Initialize sliders
  for _, name in ipairs(_state.ordering) do
    local filter = M.config.filters[name]
    ---@type perception.ui.Slider
    local widget = Slider:init {
      label = name,
      label_width = label_width,
      slider_width = M.config.ui.slider_width,
      range_width = range_width,
      min_value = filter.level.min,
      max_value = filter.level.max,
      step = filter.level.step,
      current = filter.level.default,
      callback = function(value)
        M.set(name, value)
      end,
    }
    _state.filters[name] = {
      value = filter.level.default,
      widget = widget,
      callback = function(state)
        state.widget.current = state.value
        M.ui:redraw() -- Refresh UI on state changes
      end,
    }
    table.insert(widgets, widget)
  end
  M.ui = UI:init {
    win_config = M.config.ui.mode == "floating"
        and M.config.ui.floating_win_config
      or M.config.ui.split_win_config,
    widgets = widgets,
    key_handlers = M.config.ui.key_handlers,
  }
  -- Save original highlight groups
  _orig_hl_groups = vim.api.nvim_get_hl(0, {})
  M.enable()
  -- Setup Commands
  vim.api.nvim_create_user_command("PerceptionUI", function()
    M.ui:toggle()
  end, {
    desc = "Toggle UI",
  })
  vim.api.nvim_create_user_command("PerceptionToggleFilters", function()
    M.toggle()
  end, {
    desc = "Toggle between original colorscheme and filtered colors",
  })
  vim.api.nvim_create_user_command("PerceptionSet", function(cmd_args)
    M.set(cmd_args.fargs[1], tonumber(cmd_args.fargs[2]) or 0)
  end, {
    desc = "Set the given filter to the given value.",
    nargs = "*",
  })
end

---Applies filters (from state) to original highlight groups and modifies
---highlight groups in global namespace..
local function apply_filters()
  if not _state.enabled then
    return
  end
  for hl_name, hl_group in pairs(_orig_hl_groups) do
    for _, filter_name in ipairs(_state.ordering) do
      local filter_state = _state.filters[filter_name]
      local filter = M.config.filters[filter_name]
      if not vim.list_contains(filter.ignore_hl or {}, hl_name) then
        hl_group = vim.deepcopy(hl_group)
        local attrs = { "fg", "sp" }
        if not filter.ignore_bg then
          table.insert(attrs, "bg")
        end
        for _, attr in ipairs(attrs) do
          if hl_group[attr] then
            hl_group[attr] = filter
              .apply(Color:from_number(hl_group[attr]), filter_state.value)
              :as_number()
          end
        end
      end
    end
    hl_group.force = true
    vim.api.nvim_set_hl(0, hl_name, hl_group)
  end
  redraw_cur_win()
end

local function validate_filter_name(name)
  if not vim.tbl_contains(_state.ordering, name) then
    vim.notify(
      "No such filter: "
        .. name
        .. ".\nValid options: "
        .. vim.inspect(_state.ordering)
    )
    return false
  end
  return true
end

M.list_filters = function()
  return _state.ordering
end

---Enables color adjustments.
M.enable = function()
  _state.enabled = true
  apply_filters()
end

---Disables color adjustments. Restores original highlight groups.
M.disable = function()
  _state.enabled = false
  for hl_name, hl_group in pairs(_orig_hl_groups) do
    hl_group.force = true
    vim.api.nvim_set_hl(0, hl_name, hl_group)
  end
  redraw_cur_win()
end

---Toggles color adjustments.
M.toggle = function()
  if _state.enabled then
    M.disable()
  else
    M.enable()
  end
end

---Applies a value to the specified filter.
---The given value is truncated to match the configured level settings.
---@param filter_name string The name of the filter.
---@param value number The value (level) to set to the specified filter.
---       Truncated to the minimum and maximum range set of the filter.
M.set = function(filter_name, value)
  if not validate_filter_name(filter_name) then
    return
  end
  local level = M.config.filters[filter_name].level
  _state.filters[filter_name].value = truncate(value, level.max, level.min)
  _state.filters[filter_name].callback(_state.filters[filter_name])
  apply_filters()
end

---Get the current value (level) of the specified filter.
---@param filter_name string The name of the filter.
---@return number?
M.get = function(filter_name)
  if not validate_filter_name(filter_name) then
    return
  end
  return _state.filters[filter_name].value
end

-- ---Loads a profile onto the current highlight groups.
-- M.load_profile = function()
--   --
-- end
--
-- ---Save current filter settings.
-- ---A profile does not contain any colors, just the filter settings.
-- ---It can be applied to any colorscheme.
-- M.save_profile = function()
--   --
-- end

---Generate a Lua colorscheme and write it to `colors` directory.
---The generated colorscheme would not depend on this plugin.
---@param name string The name of the colorscheme
---@param colors_dir? string Path to colors directory.
---@param background? "dark"|"light"|nil Background to set (default: "dark").
---@param termguicolors? boolean Enable 24-bit RGB (default: true).
M.generate_colorscheme = function(name, colors_dir, background, termguicolors)
  colors_dir = colors_dir or vim.fn.stdpath "config" .. "/colors"
  background = background or "dark"
  termguicolors = termguicolors or true
  local cs = [[
vim.api.nvim_command "hi clear"
if vim.fn.exists "syntax_on" then
  vim.api.nvim_command "syntax reset"
end

vim.o.background = "]] .. background .. [["
vim.o.termguicolors = ]] .. tostring(termguicolors) .. [[

vim.g.colors_name = "]] .. name .. '"'
  for hl_name, hl_group in pairs(vim.api.nvim_get_hl(0, {})) do
    hl_group = vim.deepcopy(hl_group)
    local attrs = { "fg", "sp", "bg" }
    for _, attr in ipairs(attrs) do
      if hl_group[attr] then
        hl_group[attr] = Color:from_number(hl_group[attr]):as_hex()
      end
    end
    cs = cs
      .. '\nvim.api.nvim_set_hl(0, "'
      .. hl_name
      .. '", '
      .. vim.inspect(hl_group):gsub("\n", ""):gsub(" +", " ")
      .. ")"
  end
  vim.fn.mkdir(colors_dir, "p")
  local file_path = colors_dir .. "/" .. name .. ".lua"
  local fd = io.open(file_path, "w")
  if not fd then
    vim.print("Could not open file for writing: " .. file_path)
    return
  end
  fd:write(cs)
  fd:close()
end

return M
