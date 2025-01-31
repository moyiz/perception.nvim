<!-- panvimdoc-ignore-start -->
![GitHub License](https://img.shields.io/github/license/moyiz/perception.nvim)
![GitHub Tag](https://img.shields.io/github/v/tag/moyiz/perception.nvim)
<!-- panvimdoc-ignore-end -->

# 🌃 perception.nvim

Adjust current colorscheme by applying various color filters.

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

<!-- panvimdoc-ignore-start -->

## 📹 Demo
[perception2.webm](https://github.com/user-attachments/assets/62698e3a-fb99-4d6b-a84c-5109e3885f1b)

<!-- panvimdoc-ignore-end -->

## 🎨 Features
- Fine-tune colorscheme using one or more builtin filters, or easily implement
  your own:
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
- Export a new Lua colorscheme from the modified colors without ties to this
  plugin.

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
Color adjustments can be applied by either using the builtin UI, or by calling
`require("perception").set(filter_name, value)`. A list of enabled filters can
be obtained with `require("perception").list_filters()`.

### 🪟 UI
- API: `require("pereption").ui:toggle()`
- Command: `:PerceptionUI`

A floating window (by default) containing a list of filter sliders, sorted by
order of appliance. Navigate to the line of a filter to change (`<Down>` / `<Up>`
/ `j` / `k` / `/` / `t` / `f` / other navigation keys) and:
- Press `h`/`<Left>` to reduce the current value by a per-filter pre-configured
  step. Prefixing the movement with a number will override the default step.
- Press `l`/`<Right>` to increase the current value by a per-filter
  pre-configured step. Prefixing the movement with a number will override the
  default step.
- Press `<NUM>=` to set current value to `<NUM>`. Omitting `<NUM>` will set the
  value to 0.
- Press `<NUM>-` to set current value to `-<NUM>`. Omitting `<NUM>` will set the
  value to 0.
- Press `o` to export current highlight groups as a new colorscheme.
- Press `q`/`<Esc>` to close the UI window.

## 🎨 Export a Colorscheme
- API: `require("perception").export_colorscheme(name)`

Once you are satisfied with the color adjustments, it can be used to generate

Generates a lua module in the default colors directory
(`~/.config/nvim/colors/<name>.lua`), containing a bit of boilerplate and
a `nvim_set_hl` call for each highlight group. The generated module is
a standalone colorscheme (independent of `perception.nvim`) and can be loaded as
any other colorscheme.

The method accepts the following parameters:
- `name` - The name of the colorscheme, will be set to the lua module name.
- `colors_dir` - Optional. Override path to colors directory.
- `background` - Optional. Override `background` options. Will be set to
  `"dark"` by default.
- `termguicolors` - Optional. Whether to enable 24-bit RGB (default: true).

## 🛃 Custom Filters
This plugin support adding custom color filters via its config.
See [config.lua](./lua/perception/config.lua). `base` contains the default
values for each filter configuration.

Enabled filters are sorted by priority, and each will have its own slider
rendered in the UI buffer.

The actual implementation of the filter is defined in `apply` key of its
configuration. 

It receives a `perception.Color` object and a number `value` guaranteed to
reside in the configured level range. It returns a (possibly) modified
`perception.Color` object.

> [!NOTE]
> The filter should not modify any color when `value` is its `default` value
> (tunable, defaults to `0`).

See [color.lua](./lua/perception/color.lua) for `perception.Color` object.

See [builtins.lua](./lua/perception/builtins.lua) for filter function examples.

See [config.lua](./lua/perception/config.lua) for the default filters
configuration.


### 🎡 Example - RGB Right Rotator
Some imaginary example.

Let's define a RGB Right Rotator as a filter that gradually rotates the RGB
values of a color to the right. Example: `#012345` will become `#450123` when
fully rotated. The filter accepts a color and a range of `[0, 100]` that will
indicate the percentage of color rotation,

```lua
{
  rgb_rotator = {
    level = {
      min = 0,
      max = 100,
      step = 10
    },
    priority = 31,
    apply = function(color, value)
      local u = require "perception.utils"
      local r, g, b = unpack(color:as_rgb())
      local rd = r * value / 100
      local gd = g * value / 100
      local bd = b * value / 100
      return color:from_rgb(
        u.truncate(u.round(r - rd + bd)),
        u.truncate(u.round(g - gd + rd)),
        u.truncate(u.round(b - bd + gd))
      )
    end,
  },
}
```

- `level` - Sets the bounds of input value, and a default step size.
- `priority` - A value of `31` places the filter just before the saturation
  filters.
- `apply` - Since `value` is "percentage", we first calculate the relative
  portion of each color component. Then, reduce it from the color itself and
  re-add it to the color component on its right.

Tip: Consider increasing `{ ui = { floating_win_config = { height = N } } }` to
match the number of enabled filters. Maybe it should be the default behaviour.

## 🔬 Issues
This plugin modifies highlight groups in the global namespace, rather than using
a dedicated namespace. It holds the original highlight groups in a local
variable, then uses each color as an initial value of the filter composition.
This approach solves few pain points of the first implementation that used
a dedicated namespace for the modified highlight groups:
- Window specific namespaces. Some plugins manage their own namespace for
  highlight groups (e.g. `which-key.nvim`, `telescope`), which usually depend on
  highlight groups from the global namespace (linked highlight groups).
- "Cleared" highlight groups will revert to global namespace colors (more common
  with "no color" variations e.g. `NormalNC`, `StatusLineNC`).

## ⛓️  Limitations
- `export_colorscheme` currently dumps ALL highlight groups. The generated
  colorscheme is probably bigger than it has to be and depends on the number of
  highlight groups defined in the base colorscheme and loaded plugins (for me:
  ~2k LOC, ~140KB). With that in mind, exported colorschemes would miss
  highlight groups that were added to your configuration after their generation.
- Filters process each color individually and are not aware of the specific
  highlight group.
- Applying filters more than once (e.g. changing hue, applying inversion and
  luminance, then changing hue again). Workaround, add a new filter with
  different priority that has the same `apply` method.

<!-- panvimdoc-ignore-start -->

## 🗒️ ToDo
- Instead of persisting changes by generating a colorscheme, support exporting
  filter states as perception profiles that can be loaded upon any colorscheme.
- Improve `export_colorscheme` per the points stated in Limitations section.
- Improve UI rendering (flickers when arrows are held).
- Highlight `PercetpionUI` sliders (in a dedicated namespace).
- Save & restore filter profiles and states.
- Tests.

## 📜 License
See [License](./LICENSE).

<!-- panvimdoc-ignore-end -->
<!-- vim: set textwidth=80: -->
