# 🌃 perception.nvim

Apply various filters to customize the current colorscheme.

> [!WARNING]
> This plugin is experimental. It saves a copy of the current
> colorscheme which will later be used as a base for applying color changing
> filters. Some inconsistencies and weird color behaviour might occur. It was
> not tested with other color modifying plugins.

> [!NOTE]
> I probably have near zero color theory knowledge and I am positively sure that
> there are plenty of inaccuracies in the implementation of builtin filters.
> Filter implementations and level ranges are subjected to change. Your
> contribution is more than welcomed to tackle these inaccuracies.

## 📹 Demo
[perception2.webm](https://github.com/user-attachments/assets/62698e3a-fb99-4d6b-a84c-5109e3885f1b)


## 🎨 Features
- Fine-tune one or more builtin filters, or easily implement your own:
  - Color levels.
  - Brightness.
  - Contrast.
  - Dimness.
  - Hue.
  - Saturation.
  - Sepia tone.
  - Luminance.
  - Color temperature.
  - Tint.
  - Color inversion.
  - Grayscale.
- Configurable priority to customize order of appliance.
- Generate a new Lua colorscheme from the modified colors.

## 🔨 Installation

### 💤 Lazy
```lua
{
  "moyiz/perception.nvim",
  lazy = true,
  cmd = { "PerceptionUI" },
  opts = {},
}
```

## ⚙️ Options
See [config.lua](./lua/perception/config.lua).

## 📘 Usage
Colors can be adjusted by either using the builtin UI, or by invoking
`require("perception").set(filter_name, value)`. A list of enabled filters can
be obtained with `require("perception").list_filters()`.

### 🪟 UI
A floating window (by default) containing a list of filter sliders, sorted by
order of appliance. Simply call `:PerceptionUI` or
`require("perception").ui:toggle()` and the UI window will appear. Navigate to
the line of a filter to set (`<Down>` / `<Up>` / `j` / `k` / `/` / `t` / `f`
/ other navigation keys). Default keys:
- Press `h`/`<Left>` to reduce the current value by a per-filter pre-configured
  step. Prefixing the movement with a number will override the default step.
- Press `l`/`<Right>` to increase the current value by a per-filter
  pre-configured step. Prefixing the movement with a number will override the
  default step.
- Press `<NUM>=` to set current value to `<NUM>`. Omitting `<NUM>` will set the
  value to 0.
- Press `<NUM>-` to set current value to `-<NUM>`. Omitting `<NUM>` will set the
  value to 0.
- Press `o` to save current colors as a new colorscheme.
- Press `q`/`<Esc>` to close the UI window.

### 🎨 Generate Colorscheme
Once you are satisfied with the color adjustments, it can be used to generate
a standalone colorscheme (independent of `perception.nvim`).

```lua
require("perception").generate_colorscheme("first")
```
It will generate a lua module in the default colors directory
(`~/.config/nvim/colors/first.lua`), containing a bit of boilerplate and
a `nvim_set_hl` call for each highlight group.
At this point, `first` can be loaded as any other colorscheme.

The method accepts the following parameters:
- `name` - The name of the colorscheme, will be set to the lua module name.
- `colors_dir` - Optional. Override path to colors directory.
- `background` - Optional. Override `background` options. Will be set to
  `"dark"` by default.
- `termguicolors` - Optional. Whether to enable 24-bit RGB (default: true).

## Custom Filters
Additional custom filters can be defined and enabled via config. There are two
relevant config sections: `base` and `filters`.
`base` acts as a default / common ground for filter configuration. It will be
merged and overridden by each filter specific configuration. See
[Options](#TODO) for the default `base`.
A filter configuration is an object defined in `config.filters`, mapping
a filter name to its configuration object and consists the following fields:
```lua
```

Enabling a filter will add it to the ordered by priority list
`config.state.ordering` and render its slider in the UI.

The actual implementation of the filter is defined in `apply` key of its
configuration. It is basiaclly a Lua function with the following signature:
```lua
---@param color perception.Color
---@param value number
---@return perception.Color
```
It receives a `Color` object (`color.lua`) and a value guaranteed to reside in
the configured level range, and returns a (possibly) modified `Color` object.
Note: The filter should not modify any color when applied for `default` value
(tunable, defaults to `0`).

See `builtins.lua` for filter examples.
See `config.lua` for the default filters configuration.
See `utils.lua` for handy utilities.

### Examples
Let's add some filters.

#### 🎡 RGB Right Rotator
Some imaginary example. Let's define a RGB Right Rotator as a filter that
gradually rotates the RGB values of a color. Example: `#012345` will become
`#450123` when fully rotated.
The filter accepts a color and a range of `[0, 100]` that will indicate the
percentage of color rotation,

```lua
{
  rgb_rotator = {
    level = {
      min = 0,
      max = 100,
      step = 10
    },
    priority = 30,
    apply = function(color, value)
      local truncate = require("perception.utils").truncate
      local r, g, b = unpack(color:as_rgb())
      local rd = math.floor(r * value / 100)
      local gd = math.floor(g * value / 100)
      local bd = math.floor(b * value / 100)
        truncate(r - rd + bd),
        truncate(g - gd + rd),
        truncate(b - bd + gd)
      )
    end,
  },
}
```

- `level` - Sets the bounds of input value, and a default step size.
- `priority` - A value of `31` places the filter just before the saturation
  filters.
- `apply` - Since `value` is "percentage", we first calculate the relative
  portiong of each color component, and then reduce it from the color itself and
  adding the relative portion of the prior color.

Tip: Consider increasing `{ ui = { floating_win_config = { height = N } } }` to
match the number of enabled filters. Maybe it should be the default behaviour.

## 🔬 Issues
This plugin modifies highlight groups in the global namespace, rather than using
a dedicated namespace. It holds the original highlight groups in a local
variable, then uses it as a reference for applying the filters. This approach
solved few pain points of the initial implementation that used a dedicated
namespace for the modified highlight groups:
- Window specific namespaces. Some plugins manage their own namespace for
  highlight groups (e.g. `which-key.nvim`, `telescope`), which usually depend on
  highlight groups from the global namespace (linked highlight groups).
- "Cleared" highlight groups will revert to global namespace colors (more common
  with "no color" variations e.g. `NormalNC`, `StatusLineNC`).

## ⛓️  Limitations
- `generate_colorscheme` currently dumps ALL highlight groups. The generated
colorscheme is probably bigger than it has to be (~2k LOC, ~140KB).
- Filters process each color individually and are not aware of the specific
  highlight group.
- Applying filters more than once (e.g. changing hue, applying inversion and
  luminance, then changing hue again). Workaround, add a new filter with
  different priority that has the same `apply` method. 

## 🗒️ ToDo
- Instead of persisting changes by generating a colorscheme, support exporting
  filter states as perception profiles that can be loaded upon any colorscheme.
- Improve `generate_colorscheme`. It currently dumps all highlight group, which
  is probably unnecessary and gets quite big.
- Improve UI rendering (flickers when arrows are held).
- Highlight UI widgets (in a dedicated namespace).
- Tests.

## 📜 License
See [License](./LICENSE).
