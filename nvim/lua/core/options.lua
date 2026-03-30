-- ~/.config/nvim/lua/core/options.lua

vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers
vim.opt.cursorline = true     -- Highlight the current line
vim.opt.termguicolors = true  -- Enable 24-bit RGB colors
vim.opt.undofile = true       -- Persist undo history
vim.opt.mouse = 'a'           -- Enable mouse support
vim.opt.scrolloff = 8         -- Keep 8 lines of context around the cursor

-- Indentation
vim.opt.tabstop = 4       -- Number of spaces a <Tab> counts for
vim.opt.shiftwidth = 4    -- Size of an indent
vim.opt.expandtab = true  -- Use spaces instead of tabs
vim.opt.autoindent = true -- Copy indent from current line when starting a new line

-- Search
vim.opt.hlsearch = true    -- Highlight all matches on search
vim.opt.incsearch = true   -- Show matches while typing
vim.opt.ignorecase = true  -- Ignore case in search patterns
vim.opt.smartcase = true   -- Override ignorecase if search pattern contains uppercase letters

-- Use ripgrep for :grep
vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden --glob=!.git/'
vim.opt.grepformat = '%f:%l:%c:%m'

-- Font setting for GUI clients
vim.o.guifont = "FiraCode Nerd Font:h11"


-- -----------------------------------------------------------------------------
-- CLIPBOARD CONFIGURATION (Local & Remote/OSC 52)
-- -----------------------------------------------------------------------------

-- Only use OSC 52 if we are over SSH
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
else
  -- On local machine, 'unnamedplus' uses the system clipboard for all yanks
  -- If you prefer using <leader>y for the clipboard (as we set in keymaps.lua),
  -- you can leave this line commented out.
  -- vim.opt.clipboard = 'unnamedplus'
end
