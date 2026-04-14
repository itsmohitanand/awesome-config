-- nvim 0.12 ships treesitter built-in; no plugin needed for parser management.
-- Bundled parsers: c, lua, vim, vimdoc, query, markdown, markdown_inline
-- Extra parsers (site/parser/): python, norg, norg_meta
vim.api.nvim_create_autocmd('FileType', {
  pattern = { '*', 'norg' },
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

return {}
