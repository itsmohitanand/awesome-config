return {
  'sindrets/diffview.nvim',
  cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
  keys = {
    { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'File history' },
    { '<leader>gH', '<cmd>DiffviewFileHistory<cr>',  desc = 'Repo history' },
    { '<leader>gd', '<cmd>DiffviewOpen<cr>',         desc = 'Diff working tree' },
    { '<leader>gx', '<cmd>DiffviewClose<cr>',        desc = 'Close diffview' },
  },
}
