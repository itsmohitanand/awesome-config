return {
  'lervag/vimtex',
  lazy = false,
  init = function()
    vim.g.vimtex_view_method = 'zathura'
    vim.g.vimtex_compiler_method = 'latexmk'
    vim.g.vimtex_compiler_latexmk = {
      aux_dir = '.aux',
      out_dir = '',
      callback = 1,
      continuous = 1,
      executable = 'latexmk',
      hooks = {},
      options = {
        '-verbose',
        '-file-line-error',
        '-synctex=1',
        '-interaction=nonstopmode',
      },
    }
    -- Disable vimtex's own completion in favour of blink.cmp + LSP
    vim.g.vimtex_complete_enabled = 0
    -- Disable default imaps (avoid conflicts with snippets)
    vim.g.vimtex_imaps_enabled = 0
    -- Folding
    vim.g.vimtex_fold_enabled = 1
    -- Quickfix: open on errors, not warnings
    vim.g.vimtex_quickfix_open_on_warning = 0
    -- Fix vim-commentary for tex files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'tex',
      callback = function()
        vim.bo.commentstring = '%% %s'
      end,
    })
  end,
}
