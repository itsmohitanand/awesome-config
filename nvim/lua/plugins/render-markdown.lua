return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  ft = { 'markdown', 'norg' },
  opts = {
    heading = { enabled = true },
    code    = { enabled = true },
    bullet  = { enabled = true },
    checkbox = { enabled = true },
  },
}
