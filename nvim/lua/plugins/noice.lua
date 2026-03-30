return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
  },
  opts = {
    -- Route notifications through Snacks notifier
    notify = {
      enabled = true,
      view = 'notify',
    },

    -- Beautify the command line
    cmdline = {
      enabled = true,
      view = 'cmdline_popup',
      format = {
        cmdline   = { icon = '>' },
        search_down = { icon = '/' },
        search_up   = { icon = '?' },
        filter    = { icon = '$' },
        lua       = { icon = '' },
        help      = { icon = '?' },
      },
    },

    -- LSP progress and hover improvements
    lsp = {
      override = {
        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
        ['vim.lsp.util.stylize_markdown'] = true,
        ['cmp.entry.get_documentation'] = false, -- blink handles this
      },
      hover    = { enabled = true },
      signature = { enabled = true },
      progress  = { enabled = true },
    },

    -- Let Snacks handle vim.ui.select and vim.ui.input
    popupmenu = { enabled = false },
    views = {
      -- do not override vim.ui.select (snacks handles it)
      select = { enabled = false },
    },

    -- Filter out noisy messages
    routes = {
      -- Hide "written" file save messages
      { filter = { event = 'msg_show', find = 'written' },        opts = { skip = true } },
      -- Hide search count messages
      { filter = { event = 'msg_show', find = '^/' },             opts = { skip = true } },
      -- Hide LSP loading progress spam
      { filter = { event = 'lsp',      kind = 'progress' },       opts = { skip = true } },
    },

    -- Use mini view for minor messages (non-intrusive)
    messages = {
      view              = 'mini',
      view_error        = 'mini',
      view_warn         = 'mini',
      view_history      = 'messages',
      view_search       = 'virtualtext',
    },
  },
}
