-- Autosave any modified, real-file buffer on focus loss or buffer switch.
-- Skips unnamed, readonly, non-'' buftype, and filetypes where silent writes
-- are unsafe (commit/rebase buffers etc.).

local skip_filetypes = {
  gitcommit = true,
  gitrebase = true,
  hgcommit  = true,
  oil       = true,
  fugitive  = true,
  ['']      = true,
}

local function should_save(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if not vim.bo[bufnr].modified then return false end
  if vim.bo[bufnr].readonly then return false end
  if vim.bo[bufnr].buftype ~= '' then return false end
  if skip_filetypes[vim.bo[bufnr].filetype] then return false end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then return false end
  -- Must be a real file already on disk (avoid creating files from scratch buffers).
  if vim.fn.filereadable(name) == 0 then return false end
  return true
end

local function save(bufnr)
  if not should_save(bufnr) then return end
  vim.api.nvim_buf_call(bufnr, function()
    pcall(vim.cmd, 'silent! lockmarks update')
  end)
end

local group = vim.api.nvim_create_augroup('autosave', { clear = true })

vim.api.nvim_create_autocmd({ 'BufLeave', 'WinLeave', 'FocusLost', 'InsertLeave' }, {
  group = group,
  callback = function(args) save(args.buf) end,
})

return {}
