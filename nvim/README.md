# awesome-nvim

This is a Neovim configuration that is designed to be simple, fast, and easy to use. It is built on top of `lazy.nvim`, a modern plugin manager for Neovim.

## Installation

1.  Clone this repository to your Neovim configuration directory:
    ```bash
    git clone https://github.com/itsmohitanand/awesome-nvim.git ~/.config/nvim
    ```
2.  Start Neovim:
    ```bash
    nvim
    ```
    `lazy.nvim` will automatically install all the plugins.

## Plugins

This configuration uses the following plugins:

| Plugin | Description |
| --- | --- |
| [lazy.nvim](https://github.com/folke/lazy.nvim) | A modern plugin manager for Neovim |
| [everblush](https://github.com/Everblush/nvim) | A dark, vibrant, and beautiful colorscheme |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | A blazing fast and easy to configure statusline |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | A file explorer for Neovim |
| [vim-commentary](https://github.com/tpope/vim-commentary) | A plugin for commenting out lines of code |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | A plugin for syntax highlighting and more |
| [mason.nvim](https://github.com/williamboman/mason.nvim) | A plugin for managing LSP servers, DAP servers, linters, and formatters |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | A collection of configurations for the Neovim LSP client |
| [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) | A bridge between `mason.nvim` and `nvim-lspconfig` |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | A completion engine for Neovim |
| [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) | A completion source for `nvim-cmp` that uses the Neovim LSP client |
| [cmp-buffer](https://github.com/hrsh7th/cmp-buffer) | A completion source for `nvim-cmp` that uses the current buffer |
| [cmp-path](https://github.com/hrsh7th/cmp-path) | A completion source for `nvim-cmp` that uses the file system path |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | A snippet engine for Neovim |
| [cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip) | A completion source for `nvim-cmp` that uses `LuaSnip` |
| [nvim-dap](https://github.com/mfussenegger/nvim-dap) | A Debug Adapter Protocol client implementation for Neovim |
| [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) | A UI for `nvim-dap` |
| [mason-nvim-dap.nvim](https://github.com/jay-babu/mason-nvim-dap.nvim) | A bridge between `mason.nvim` and `nvim-dap` |

## Keymaps

### Insert Mode

| Keymap | Description |
| --- | --- |
| `jk` | Exit insert mode |
| `<C-BS>` | Delete previous word |

### Normal Mode

#### Window Navigation

| Keymap | Description |
| --- | --- |
| `<C-h>` | Move to left window |
| `<C-j>` | Move to down window |
| `<C-k>` | Move to up window |
| `<C-l>` | Move to right window |

#### File Explorer (nvim-tree)

| Keymap | Description |
| --- | --- |
| `<leader>e` | Toggle file explorer |
| `<leader>f` | Find file in explorer |

#### Buffer Navigation

| Keymap | Description |
| --- | --- |
| `<S-l>` | Next buffer |
| `<S-h>` | Previous buffer |
| `<leader>bd` | Close current buffer |

#### File

| Keymap | Description |
| --- | --- |
| `<leader>s` | Save file |
| `<leader>q` | Quit |

#### Navigation

| Keymap | Description |
| --- | --- |
| `j` | Move down by visual line |
| `k` | Move up by visual line |
| `<C-d>` | Page down and center |
| `<C-u>` | Page up and center |
| `n` | Search next and center |
| `N` | Search previous and center |

### Visual Mode

| Keymap | Description |
| --- | --- |
| `J` | Move line down |
| `K` | Move line up |
| `<` | Indent left |
| `>` | Indent right |
| `p` | Paste over selection |

### Other

| Keymap | Description |
| --- | --- |
| `<F5>` | Save and run Python file |