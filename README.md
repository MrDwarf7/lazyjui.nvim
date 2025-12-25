# LazyJui.nvim

A Neovim plugin that provides a beautiful floating window interface for [jj](https://github.com/jj-vcs/jj),
leveraging the [jjui](https://github.com/idursun/jjui) TUI for functionality.

## Features

- **Floating Window Interface** - Clean, distraction-free jjui experience
- **Fast Integration** - Seamless integration with your Neovim workflow
- **Customizable** - Configurable window size, borders, and behavior
- **Smart Window Management** - Auto-resize, focus handling, and proper cleanup
- **Health Checks** - Built-in dependency validation

## Prerequisites

- **Neovim** 0.7.0
- **[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)** - Required dependency
- **[jj](https://github.com/jj-vcs/jj)** - The VCS used with the plugin
- **[jjui](https://github.com/idursun/jjui)** - The TUI/tool that's spawned inside the floating window

## Installation & Configuration

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "mrdwarf7/lazyjui.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim"
  },
  keys = {
    {
      -- Default is <Leader>jj
      -- An example of a custom mapping to open the interface
      "<Leader>gj",
      function()
        require("lazyjui").open()
      end,
    },
  },
  -- You can also simply pass `opts = true` or `opts = {}` and the default options will be used
  ---@type lazyjui.Opts
  opts =  {
    -- Optionally:
    border_chars = {}, -- to remove the entire outer border (or nil)
    -- or
    -- Use custom set of border chars (must be 8 long)
    -- border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }

    -- Support for custom command pass-through
    -- In this example, we use the revset `all()` command
    --
    -- Will default to just `jjui`
    cmd = { "jjui", "-r", "all()" },
    height = 0.8, -- default is 0.8,
    width = 0.9, -- default is 0.9,
    winblend = 0, -- default is 0 (fully opaque). Set to 100 for fully transparent (not recommended though).
  }
}
```

## Usage

### Commands

- `:LazyJui` - Open the LazyJui floating window

### API

```lua
local lazyjui = require("lazyjui")

-- Open the interface
lazyjui.open()

-- Close the interface
lazyjui.close()
```

### Health Check

Verify your installation and dependencies:

```vim
:checkhealth lazyjui
```

## Keymaps

The plugin sets a default keymap to open the interface.
You can customize it in your Neovim configuration:

```lua
vim.api.nvim_set_keymap('n', '<Leader>gj', ':lua require("lazyjui").open()<CR>', { noremap = true, silent = true })
```

Or the recommended way is to use the `keys` table in the plugin spec/configuration:

```lua
{
  "mrdwarf7/lazyjui.nvim",
  keys = {
    {
      "<Leader>gj",
      function()
        require("lazyjui").open()
      end,
    },
  }
}
```

## How It Works

LazyJui creates a floating window and spawns the `jjui` command inside it as a terminal job. The window:

- Automatically resizes when you resize Neovim
- Closes when you lose focus
- Properly cleans up resources to prevent memory leaks
- Integrates with plenary.nvim for enhanced window positioning when available

## Troubleshooting

### "jjui executable not found" error

Make sure you have the `jjui` command available & installed. It must be available on your PATH:

```bash
# Check if jjui is installed
which jjui

# Oh no!
```

```bash
# Follow the instructions on the official jjui repository

# If using Arch for instance:
paru -S jjui-bin # or yay
```

### Window positioning issues

If you're experiencing window positioning problems, make sure you have plenary.nvim installed. LazyJui uses plenary's advanced window positioning when available.
If you're still having problems with it, please open an issue with details about your Neovim version, OS, and any relevant configuration.

### Health check fails

Run `:checkhealth lazyjui` to diagnose issues. Common problems:

- Missing plenary.nvim dependency
- jjui not in PATH
- Neovim version too old

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Related Projects

- **[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)** - Window management and other utilities
- **[jj](https://github.com/jj-vcs/jj)** - The new-fangled VCS system that's all the rage with the cool kids
- **[jjui](https://github.com/idursun/jjui)** - A TUI tool for jj that makes it a _lil_ bit easier to understand what is going on
