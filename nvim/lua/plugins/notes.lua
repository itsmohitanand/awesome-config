-- Quick-notes workflow rooted at ~/Documents/notes/.
-- Layout (seed structure; an agent reorganizes periodically):
--   daily/YYYY-MM-DD.typ   <- today's journal
--   topics/<slug>.typ      <- durable single-subject notes
--   inbox/                 <- (agent-managed) unsorted capture
-- Keys:
--   <leader>nn  open today's daily note
--   <leader>nN  prompt for title, open topical note
-- Auto-commits any save into ~/Documents/notes/ git repo (no auto-push).

local NOTES_DIR = vim.fn.expand('~/Documents/notes')

local function slugify(s)
  return (s:lower():gsub('[^a-z0-9]+', '-'):gsub('^%-+', ''):gsub('%-+$', ''))
end

local function open_note(path)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function daily_note()
  open_note(NOTES_DIR .. '/daily/' .. os.date('%Y-%m-%d') .. '.typ')
end

local function topic_note()
  vim.ui.input({ prompt = 'Note title: ' }, function(title)
    if not title or title == '' then return end
    local slug = slugify(title)
    if slug == '' then
      vim.notify('note: empty slug', vim.log.levels.WARN)
      return
    end
    open_note(NOTES_DIR .. '/topics/' .. slug .. '.typ')
  end)
end

vim.keymap.set('n', '<leader>nn', daily_note, { desc = 'Notes: today' })
vim.keymap.set('n', '<leader>nN', topic_note, { desc = 'Notes: new topic' })

-- Autosave .typ notes every 30 s; timer lives for the lifetime of the buffer.
local autosave_timers = {}

local function is_notes_typ(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  return file:find('^' .. NOTES_DIR .. '/') and file:match('%.typ$')
end

local function stop_autosave(bufnr)
  local t = autosave_timers[bufnr]
  if t then
    t:stop(); t:close()
    autosave_timers[bufnr] = nil
  end
end

local function start_autosave(bufnr)
  if autosave_timers[bufnr] then return end
  local uv = vim.uv or vim.loop
  local t = uv.new_timer()
  autosave_timers[bufnr] = t
  t:start(30000, 30000, vim.schedule_wrap(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      stop_autosave(bufnr)
      return
    end
    if vim.bo[bufnr].modified then
      vim.api.nvim_buf_call(bufnr, function() vim.cmd('silent! write') end)
    end
  end))
end

local as_group = vim.api.nvim_create_augroup('notes_autosave', { clear = true })

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  pattern = '*.typ',
  group = as_group,
  callback = function(args)
    if is_notes_typ(args.buf) then start_autosave(args.buf) end
  end,
})

vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
  pattern = '*.typ',
  group = as_group,
  callback = function(args) stop_autosave(args.buf) end,
})

-- Auto-commit all notes changes once, just before Neovim exits.
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = vim.api.nvim_create_augroup('notes_autocommit', { clear = true }),
  callback = function()
    local msg = string.format('notes: autosave @ %s', os.date('%Y-%m-%d %H:%M'))
    -- Synchronous: we must finish before the process exits.
    local add = vim.system({ 'git', '-C', NOTES_DIR, 'add', '-A' }, { text = true }):wait()
    if add.code ~= 0 then return end
    vim.system(
      { 'git', '-C', NOTES_DIR, 'commit', '--quiet', '-m', msg },
      { text = true }
    ):wait()
    -- exit 1 means nothing staged — that's fine, ignore silently.
  end,
})

return {}
