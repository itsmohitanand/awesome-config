-- -----------------------------------------------------------------------------
-- #1: CLIPBOARD AND LEADER KEY
-- -----------------------------------------------------------------------------

-- Theme — change this string to switch colorscheme; run switch-theme to sync all apps
local theme = 'poimandres'

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
require('core.sticky_scroll')
require('keymaps')

-- -----------------------------------------------------------------------------
-- #4: LAZY.NVIM PLUGIN SETUP
-- -----------------------------------------------------------------------------

require('lazy').setup(
{
  -- Colorschemes (active one set by `theme` variable above)
  { 'olivercederborg/poimandres.nvim', lazy = false, priority = 1000 },
  { 'scottmckendry/cyberdream.nvim', lazy = false, priority = 999 },
  { 'Everblush/nvim', name = 'everblush', lazy = false, priority = 998 },
  
  -- Quality of Life
  { 'tpope/vim-commentary' },

  -- Import all modular plugin configs from lua/plugins/ directory
  { import = 'plugins' },
}, {
  rocks = { enabled = false },
})

vim.cmd.colorscheme(theme)

if theme == 'poimandres' then
  -- module names (numpy, os, pathlib…)  → bright blue
  vim.api.nvim_set_hl(0, '@module',        { fg = '#ADD7FF' })
  vim.api.nvim_set_hl(0, '@module.python', { fg = '#ADD7FF' })
  -- the alias / bound name (np, pd, plt…) → keep as foreground but bold so it reads differently
  vim.api.nvim_set_hl(0, '@variable',      { fg = '#E4F0FB' })
  -- function calls  → teal
  vim.api.nvim_set_hl(0, '@function',      { fg = '#5DE4C7' })
  vim.api.nvim_set_hl(0, '@function.call', { fg = '#5DE4C7' })
  -- class / type names  → softer blue
  vim.api.nvim_set_hl(0, '@type',          { fg = '#89DDFF' })
  -- parameters / arguments  → blue-gray so they don't shout
  vim.api.nvim_set_hl(0, '@variable.parameter', { fg = '#767C9D' })
end
