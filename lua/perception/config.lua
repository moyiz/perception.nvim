local builtins = require "perception.builtins"

---@class perception.Config
---@field base perception.filter.Config Common settings that will be merged to
---                                     each filter.
---@field filters table<string, perception.filter.Config> Per filter settings.
---@field ui perception.ui.Config

---@class perception.filter.Level
---@field min number Minimum valid number that can be accepted by the filter.
---@field max number Maximum valid number that can be accepted by the filter.
---@field default number Default level to set.
---@field step number Default step size.

---@class perception.filter.Config
---@field enabled boolean Whether the filter should be enabled or not.
---@field level perception.filter.Level Slider level bounds.
---@field priority number Dictates order of appliance (higher is first).
---@field ignore_bg boolean Whether to ignore background colors.
---@field ignore_hl string[] Names of groups to ignore when applying a filter.
---@field apply fun(color: perception.Color, value: number): perception.Color

---@class perception.ui.Config
---@field mode "floating"|"split"
---@field floating_win_config vim.api.keyset.win_config
---@field split_win_config vim.api.keyset.win_config
---@field slider_width number The width of the sliding part of the slider.
---@field key_handlers perception.ui.key_handlers

---@type perception.Config
local config = {
  base = {
    enabled = true,
    level = {
      default = 0,
      step = 5,
    },
    priority = 100,
    ignore_bg = false,
    ignore_hl = {},
  },
  filters = {
    hue = {
      level = {
        min = -360,
        max = 360,
      },
      priority = 50,
      apply = builtins.hue,
    },
    temperature = {
      level = {
        min = -255,
        max = 255,
      },
      priority = 45,
      apply = builtins.temperature,
    },
    red = {
      level = {
        min = -255,
        max = 255,
      },
      priority = 40,
      apply = builtins.red,
    },
    tint = {
      level = {
        min = -255,
        max = 255,
      },
      priority = 35,
      apply = builtins.tint,
    },
    green = {
      level = {
        min = -255,
        max = 255,
      },
      priority = 35,
      apply = builtins.green,
    },
    blue = {
      level = {
        min = -255,
        max = 255,
      },
      priority = 32,
      apply = builtins.blue,
    },
    hsl_saturation = {
      level = {
        min = -100,
        max = 100,
      },
      priority = 30,
      apply = builtins.hsl_saturation,
    },
    hsv_saturation = {
      level = {
        min = -100,
        max = 100,
      },
      priority = 30,
      apply = builtins.hsv_saturation,
    },
    sepia = {
      level = {
        min = 0,
        max = 40,
        step = 10,
      },
      priority = 26,
      apply = builtins.sepia,
    },
    sepia_intensity = {
      level = {
        min = 0,
        max = 255,
      },
      priority = 25,
      apply = builtins.sepia_intensity,
    },
    grayscale = {
      level = {
        min = 0,
        max = 1,
      },
      priority = 24,
      apply = builtins.grayscale,
    },
    -- invert = {
    --   level = {
    --     min = 0,
    --     max = 1,
    --   },
    --   priority = 22,
    --   apply = builtins.invert,
    -- },
    inversion = {
      level = {
        min = 0,
        max = 100,
      },
      priority = 22,
      apply = builtins.inversion,
    },
    luminance = {
      level = {
        min = -100,
        max = 100,
      },
      priority = 20,
      apply = builtins.luminance,
    },
    value = {
      level = {
        min = -100,
        max = 100,
      },
      priority = 20,
      apply = builtins.value,
    },
    brightness = {
      level = {
        min = -255,
        max = 255,
      },
      priority = 15,
      apply = builtins.brightness,
    },
    dim = {
      level = {
        min = -255,
        max = 255,
      },
      priority = 10,
      apply = builtins.dim,
    },
    contrast = {
      level = {
        min = -255,
        max = 255,
      },
      priority = 5,
      apply = builtins.contrast,
    },
  },
  ui = {
    mode = "floating",
    floating_win_config = {
      title = "[  perception  ]",
      title_pos = "left",
      anchor = "NE",
      style = "minimal",
      border = "rounded",
      relative = "editor",
      width = 66,
      height = 17,
      row = 1,
      col = vim.o.columns,
      noautocmd = true,
    },
    split_win_config = {
      split = "right",
      width = 79,
      noautocmd = true,
    },
    slider_width = 32,
    key_handlers = {
      ["<Left>"] = function(slider)
        slider = slider --[[@as perception.ui.Slider]]
        slider:decrease(vim.v.count)
      end,
      ["h"] = "<Left>",
      ["<Right>"] = function(slider)
        slider = slider --[[@as perception.ui.Slider]]
        slider:increase(vim.v.count)
      end,
      ["l"] = "<Right",
      ["="] = function(slider)
        slider = slider --[[@as perception.ui.Slider]]
        slider:set(vim.v.count)
      end,
      ["-"] = function(slider)
        slider = slider --[[@as perception.ui.Slider]]
        slider:set(-vim.v.count)
      end,
      ["o"] = function()
        vim.ui.input({ prompt = "Save colorscheme as: " }, function(name)
          if name and name ~= "" then
            require("perception").export_colorscheme(name)
          end
        end)
      end,
      ["<Esc>"] = function()
        require("perception").ui:close()
      end,
      ["q"] = "<Esc>",
    },
  },
}

return {
  new = function(opts)
    return vim.tbl_deep_extend("force", config, opts or {})
  end,
}
