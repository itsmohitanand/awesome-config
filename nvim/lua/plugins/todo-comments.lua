return {
  'folke/todo-comments.nvim',
  event = 'BufReadPost',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {},
  keys = {
    { '<leader>ft', '<cmd>TodoSnacks<cr>', desc = 'Find TODOs' },
  },
}
