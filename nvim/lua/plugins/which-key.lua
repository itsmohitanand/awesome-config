return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    delay = 0,
    icons = { rules = false },
    spec = {
      { '<leader>b',  group = 'Buffer' },
      { '<leader>o',  group = 'Opencode' },
      { '<leader>c',  group = 'Code' },
      { '<leader>d',  group = 'Debug' },
      { '<leader>f',  group = 'Find / Files' },
      { '<leader>g',  group = 'Git' },
      { '<leader>h',  group = 'Harpoon' },
      { '<leader>r',  group = 'REPL' },
      { '<leader>sk', group = 'Sidekick' },
    },
  },
}
