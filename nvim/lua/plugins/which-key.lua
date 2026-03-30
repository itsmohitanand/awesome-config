return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    delay = 500,
    icons = { rules = false },
    spec = {
      { '<leader>r',  group = 'REPL' },
      { '<leader>tk', group = 'Telekasten' },
      { '<leader>nr', group = 'Neorg' },
      { '<leader>d',  group = 'Debug' },
      { '<leader>b',  group = 'Buffer' },
    },
  },
}
