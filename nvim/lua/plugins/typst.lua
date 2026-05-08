-- Typst: live preview + LSP (tinymist).
-- tinymist supersedes the abandoned typst-lsp project.
return {
  {
    'chomosuke/typst-preview.nvim',
    ft = 'typst',
    build = function()
      require('typst-preview').update()
    end,
    opts = {
      dependencies_bin = { ['tinymist'] = 'tinymist' },
      open_cmd = nil, -- nil → opens in default browser; set e.g. 'firefox %s' to override
      invert_colors = 'auto', -- invert in dark mode
      follow_cursor = true,
    },
    keys = {
      { '<leader>tp', '<cmd>TypstPreview<cr>',       desc = 'Typst: start preview' },
      { '<leader>ts', '<cmd>TypstPreviewStop<cr>',   desc = 'Typst: stop preview' },
      { '<leader>tt', '<cmd>TypstPreviewToggle<cr>', desc = 'Typst: toggle preview' },
    },
  },
}
