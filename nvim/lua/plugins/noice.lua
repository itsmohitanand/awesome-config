return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = { 'MunifTanjim/nui.nvim' },
  opts = {
    cmdline = {
      enabled = true,
      view = 'cmdline_popup',
      format = {
        cmdline     = { icon = '>' },
        search_down = { icon = '/' },
        search_up   = { icon = '?' },
        filter      = { icon = '$' },
        lua         = { icon = '' },
        help        = { icon = '?' },
      },
    },

    messages  = { enabled = false }, -- snacks notifier handles this
    notify    = { enabled = false }, -- snacks notifier handles this
    popupmenu = { enabled = false }, -- blink handles completion menu

    lsp = {
      override = {
        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
        ['vim.lsp.util.stylize_markdown']                = true,
      },
      hover     = { enabled = true },
      signature = { enabled = true },
      progress  = { enabled = false },
    },

    routes = {
      { filter = { event = 'msg_show', find = 'written' }, opts = { skip = true } },
    },
  },
}
