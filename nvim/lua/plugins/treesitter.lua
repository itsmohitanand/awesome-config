return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  config = function()
    -- New API: nvim-treesitter is now purely a parser installer.
    -- Highlight and indent are built into nvim 0.11+.
    require('nvim-treesitter').setup()

    -- Install parsers (runs async, skips already-installed ones)
    local parsers = {
      'c', 'cpp', 'lua', 'vim', 'vimdoc',
      'bash', 'markdown', 'markdown_inline', 'python',
    }
    require('nvim-treesitter.install').install(parsers)

    -- Enable treesitter highlight for every buffer that has a parser
    vim.api.nvim_create_autocmd('FileType', {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
