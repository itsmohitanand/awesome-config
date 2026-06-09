return {
  'TheNoeTrevino/haunt.nvim',
  event = 'VeryLazy',
  opts = {
    picker = 'auto',
    per_branch_bookmarks = true,
    virt_text_hl = 'HauntNote',
  },
  config = function(_, opts)
    local function set_hl()
      -- Warm amber italic — clearly distinct from grey code comments
      vim.api.nvim_set_hl(0, 'HauntNote', { fg = '#e5c76b', italic = true })
    end
    set_hl()
    vim.api.nvim_create_autocmd('ColorScheme', { callback = set_hl })
    require('haunt').setup(opts)
  end,
  keys = {
    { '<leader>ha', function() require('haunt.api').annotate() end,         desc = 'Haunt annotate' },
    { '<leader>ht', function() require('haunt.api').toggle_annotation() end, desc = 'Haunt toggle line' },
    { '<leader>hT', function() require('haunt.api').toggle_all_lines() end,  desc = 'Haunt toggle all' },
    { '<leader>hd', function() require('haunt.api').delete() end,            desc = 'Haunt delete' },
    { '<leader>hC', function() require('haunt.api').clear_all() end,         desc = 'Haunt clear all' },
    { '<leader>hn', function() require('haunt.api').next() end,              desc = 'Haunt next' },
    { '<leader>hp', function() require('haunt.api').prev() end,              desc = 'Haunt prev' },
    { '<leader>hl', function() require('haunt.picker').show() end,           desc = 'Haunt list' },
    { '<leader>hq', function() require('haunt.api').to_quickfix() end,       desc = 'Haunt to quickfix' },
    { '<leader>hy', function() require('haunt.api').yank_locations({ current_buffer = true }) end, desc = 'Haunt yank (buffer)' },
    { '<M-n>',      function() require('haunt.api').next() end,              desc = 'Haunt next' },
    { '<M-p>',      function() require('haunt.api').prev() end,              desc = 'Haunt prev' },
  },
}
