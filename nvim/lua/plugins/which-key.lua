return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    delay = 0,
    icons = { rules = false },
    spec = {
      { '<leader>g',  group = 'Git' },
      { '<leader>h',  group = 'Harpoon' },
      { '<leader>r',  group = 'REPL' },
      { '<leader>tk', group = 'Telekasten' },
      { '<leader>nr', group = 'Neorg' },
      { '<leader>d',  group = 'Debug' },
      { '<leader>b',  group = 'Buffer' },
    },
  },
}
