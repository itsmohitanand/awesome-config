return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require('harpoon')
    harpoon:setup()

    -- Quick menu toggle
    vim.keymap.set('n', '<leader>h', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Harpoon menu' })

    -- Add current file
    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
      local name = vim.fn.expand('%:t')
      Snacks.notify('Pinned: ' .. name)
    end, { desc = 'Harpoon add file' })

    -- Jump to slots 1–5
    for i = 1, 5 do
      vim.keymap.set('n', '<leader>' .. i, function()
        harpoon:list():select(i)
      end, { desc = 'Harpoon file ' .. i })
    end

    -- Cycle through pinned files
    vim.keymap.set('n', '<M-n>', function() harpoon:list():next() end, { desc = 'Harpoon next' })
    vim.keymap.set('n', '<M-p>', function() harpoon:list():prev() end, { desc = 'Harpoon prev' })
  end,
}
