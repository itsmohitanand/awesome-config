return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    picker = {
      ui_select = true,
      sources = {
        files = { hidden = true },
      },
    },
    explorer  = { enabled = true },
    lazygit   = { enabled = true },
    notifier  = { enabled = true, timeout = 3000 },
    indent    = { enabled = true },
    bigfile   = { enabled = true },
    terminal  = {
      enabled = true,
      win = {
        position = 'bottom',
        height   = 0.3,
      },
    },
    image     = { enabled = false }, -- zellij does not support kitty graphics protocol
    input     = { enabled = true },  -- required for vim.ui.select override
  },
  config = function(_, opts)
    require('snacks').setup(opts)
    -- Wire vim.ui overrides after snacks is fully initialised
    vim.ui.select = Snacks.picker.select
    vim.ui.input  = Snacks.input
  end,
  keys = {
    { '<leader>ff', function() Snacks.picker.files({ hidden = true }) end, desc = 'Find files' },
    { '<leader>fg', function() Snacks.picker.grep() end,                   desc = 'Live grep' },
    { '<leader>fb', function() Snacks.picker.buffers() end,                desc = 'Find buffers' },
    { '<leader>e',  function() Snacks.explorer() end,                      desc = 'Toggle explorer' },
    { '<leader>gg', function() Snacks.lazygit() end,                       desc = 'LazyGit' },
    { '<C-`>',      function() Snacks.terminal() end, mode = { 'n', 't' }, desc = 'Toggle terminal' },
  },
}
