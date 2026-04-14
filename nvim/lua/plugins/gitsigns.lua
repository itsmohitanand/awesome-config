return {
  'lewis6991/gitsigns.nvim',
  event = 'BufReadPost',
  opts = {
    signs = {
      add          = { text = '▎' },
      change       = { text = '▎' },
      delete       = { text = '' },
      topdelete    = { text = '' },
      changedelete = { text = '▎' },
    },
    current_line_blame = true,
    current_line_blame_opts = {
      delay = 300,
      virt_text_pos = 'eol',
    },
  },
  keys = {
    { ']c',         function() require('gitsigns').next_hunk() end,                desc = 'Next hunk' },
    { '[c',         function() require('gitsigns').prev_hunk() end,                desc = 'Prev hunk' },
    { '<leader>gb', function() require('gitsigns').blame_line({ full = true }) end, desc = 'Blame line' },
    { '<leader>gp', function() require('gitsigns').preview_hunk() end,             desc = 'Preview hunk' },
    { '<leader>gs', function() require('gitsigns').stage_hunk() end,               desc = 'Stage hunk' },
    { '<leader>gr', function() require('gitsigns').reset_hunk() end,               desc = 'Reset hunk' },
  },
}
