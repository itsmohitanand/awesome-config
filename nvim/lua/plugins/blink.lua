return {
  'saghen/blink.cmp',
  version = '*',
  dependencies = { 'L3MON4D3/LuaSnip' },
  opts = {
    keymap = {
      preset = 'default',
      ['<C-b>']     = { 'scroll_documentation_up', 'fallback' },
      ['<C-f>']     = { 'scroll_documentation_down', 'fallback' },
      ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>']     = { 'hide', 'fallback' },
      ['<CR>']      = { 'accept', 'fallback' },
      ['<Tab>']     = { 'select_and_accept', 'snippet_forward', 'fallback' },
      ['<S-Tab>']   = { 'snippet_backward', 'fallback' },
      ['<C-n>']     = { 'select_next', 'fallback' },
      ['<C-p>']     = { 'select_prev', 'fallback' },
    },
    snippets = { preset = 'luasnip' },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'minuet' },
      providers = {
        minuet = {
          name = 'minuet',
          module = 'minuet.blink',
          async = true,
          timeout_ms = 3000,
          score_offset = 50,
        },
      },
    },
    completion = {
      accept = { auto_brackets = { enabled = true } },
      documentation = { auto_show = true },
      trigger = { prefetch_on_insert = false },
    },
  },
}
