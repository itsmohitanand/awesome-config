-- -----------------------------------------------------------------------------
-- #1: CLIPBOARD AND LEADER KEY
-- -----------------------------------------------------------------------------

-- Theme — change this string to switch colorscheme; run switch-theme to sync all apps
local theme = 'cyberdream'

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable synchronization with the system clipboard
vim.opt.clipboard = "unnamedplus"

-- Smart Clipboard Logic: Local vs. SSH
-- This ensures copy/paste works whether you are on your laptop or a server.
if vim.env.SSH_TTY then
    -- We are remote: Use OSC 52 to tunnel clipboard to local machine
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
    -- We are local: Unset to let Neovim auto-detect xclip, pbcopy, or wl-clipboard
    vim.g.clipboard = nil
end

-- -----------------------------------------------------------------------------
-- #2: LAZY.NVIM BOOTSTRAP
-- -----------------------------------------------------------------------------

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- -----------------------------------------------------------------------------
-- #3: LOAD CORE CONFIG (External Files)
-- -----------------------------------------------------------------------------

require('core.options')
require('keymaps')

-- -----------------------------------------------------------------------------
-- #4: LAZY.NVIM PLUGIN SETUP
-- -----------------------------------------------------------------------------

require('lazy').setup(
{
  -- Colorschemes (active one set by `theme` variable above)
  { 'scottmckendry/cyberdream.nvim', lazy = false, priority = 1000 },
  { 'Everblush/nvim', name = 'everblush', lazy = false, priority = 999 },
  
  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup()
    end,
  },
  
  -- Quality of Life
  { 'tpope/vim-commentary' },

  -- Import all modular plugin configs from lua/plugins/ directory
  { import = 'plugins' },
}, {
  rocks = { enabled = false },
})

vim.cmd.colorscheme(theme)
