-- Temporarily disabled

return {}

--[[
-- nvim 0.10+ bundles treesitter parsers: c, lua, vim, vimdoc, bash,
-- markdown, markdown_inline, python, query, regex, toml.
-- Highlighting and indentation are auto-enabled for bundled parsers.
-- No plugin needed; nvim-treesitter is archived.

-- cpp is not bundled; enable treesitter highlight only when the parser exists
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local ok, _ = pcall(vim.treesitter.start, args.buf)
    if not ok then
      -- parser not available — fall back to regex syntax highlighting
      vim.bo[args.buf].syntax = 'on'
    end
  end,
})

return {}
--]]
