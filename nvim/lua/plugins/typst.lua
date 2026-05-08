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
      { '<leader>tp', '<cmd>TypstPreview<cr>',       desc = 'Typst: start browser preview' },
      { '<leader>ts', '<cmd>TypstPreviewStop<cr>',   desc = 'Typst: stop browser preview' },
      { '<leader>tt', '<cmd>TypstPreviewToggle<cr>', desc = 'Typst: toggle browser preview' },
    },
  },
  {
    -- Open the current .typ's PDF (built by tinymist on save) in zathura.
    -- zathura auto-reloads, so subsequent :w updates the view.
    'nvim-lua/plenary.nvim',
    ft = 'typst',
    config = function()
      vim.keymap.set('n', '<leader>tv', function()
        local buf = vim.api.nvim_buf_get_name(0)
        if buf == '' or vim.bo.filetype ~= 'typst' then
          vim.notify('not a typst buffer', vim.log.levels.WARN)
          return
        end
        if vim.bo.modified then vim.cmd.write() end
        local pdf = buf:gsub('%.typ$', '.pdf')
        if vim.fn.filereadable(pdf) == 0 then
          vim.notify('PDF not yet built — save once and retry', vim.log.levels.INFO)
          return
        end
        vim.system({ 'zathura', pdf }, { detach = true })
      end, { desc = 'Typst: open PDF in zathura' })
    end,
  },
}
