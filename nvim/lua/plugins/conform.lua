return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  keys = {
    { '<leader>cf', function() require('conform').format({ async = true }) end, desc = 'Format buffer' },
  },
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
    formatters = {
      ruff_format = {
        command = 'uv',
        args = { 'run', 'ruff', 'format', '--force-exclude', '--stdin-filename', '$FILENAME', '-' },
      },
      ruff_organize_imports = {
        command = 'uv',
        args = { 'run', 'ruff', 'check', '--force-exclude', '--select', 'I', '--fix', '--stdin-filename', '$FILENAME', '-' },
      },
    },
  },
}
