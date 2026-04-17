return {
  'MagicDuck/grug-far.nvim',
  config = function()
    require('grug-far').setup({})

    local map = vim.keymap.set
    map('n', '<leader>cs', '<cmd>GrugFar<cr>', { desc = 'Search and replace (grug-far)' })
    map('v', '<leader>cs', function()
      require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })
    end, { desc = 'Search and replace word (grug-far)' })
  end,
}
