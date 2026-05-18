return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  ft = { 'markdown' },
  opts = {
    heading = { enabled = true },
    code    = {
      enabled         = true,
      style           = 'normal',
      width           = 'block',
      border          = 'thin',
      highlight        = 'RenderMarkdownCode',
      highlight_inline = 'RenderMarkdownCodeInline',
    },
    bullet  = { enabled = true },
    checkbox = { enabled = true },
  },
  config = function(_, opts)
    require('render-markdown').setup(opts)
    -- Elevated bg so fenced blocks pop off Normal (#1B1E28) without
    -- washing out poimandres syntax tokens.
    vim.api.nvim_set_hl(0, 'RenderMarkdownCode',       { bg = '#252837' })
    vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInline', { bg = '#2A2F3D', fg = '#5DE4C7' })
  end,
}
