return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    delay = 0,
    icons = { rules = false },
    spec = {
      { '<leader>av', group = 'Avante' },
      { '<leader>b',  group = 'Buffer' },
      { '<leader>c',  group = 'Code' },
      { '<leader>d',  group = 'Debug' },
      { '<leader>f',  group = 'Find / Files' },
      { '<leader>g',  group = 'Git' },
      { '<leader>h',  group = 'Harpoon' },
      { '<leader>nr', group = 'Neorg' },
      { '<leader>r',  group = 'REPL' },
    },
  },
}
