return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  opts = {
    formatters_by_ft = {
      python = { 'ruff_format', 'ruff_organize_imports' },
      lua    = { 'stylua' },
      tex    = { 'latexindent' },
    },
    format_on_save = {
      timeout_ms = 2000,
      lsp_format = 'fallback',
    },
  },
}
