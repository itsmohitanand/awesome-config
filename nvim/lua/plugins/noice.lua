return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = { 'MunifTanjim/nui.nvim' },
  opts = {
    cmdline = {
      enabled = true,
      view = 'cmdline_popup',
      format = {
        cmdline     = { pattern = '^:',  icon = '',  lang = 'vim' },
        search_down = { kind = 'search', pattern = '^/',  icon = ' ', lang = 'regex' },
        search_up   = { kind = 'search', pattern = '^%?', icon = ' ', lang = 'regex' },
      },
    },
    -- snacks.notifier handles messages/notifications
    messages = { enabled = false },
    notify   = { enabled = false },
    lsp = {
      override = {
        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
        ['vim.lsp.util.stylize_markdown'] = true,
      },
      hover    = { enabled = false }, -- snacks/lsp handles hover
      signature = { enabled = false },
    },
    views = {
      cmdline_popup = {
        position = { row = '40%', col = '50%' },
        size     = { width = 64, min_width = 40 },
        border   = { style = 'rounded' },
      },
      popupmenu = {
        relative = 'editor',
        position = { row = '43%', col = '50%' },
        size     = { width = 64, height = 10 },
        border   = { style = 'rounded' },
      },
    },
  },
}
