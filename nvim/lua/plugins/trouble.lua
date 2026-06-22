return {
  'folke/trouble.nvim',
  cmd = 'Trouble',
  opts = {
    position = 'right',
    modes = {
      diagnostics_errors = {
        mode = 'diagnostics',
        filter = { severity = vim.diagnostic.severity.ERROR },
      },
    },
  },
}
