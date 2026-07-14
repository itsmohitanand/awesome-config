-- Quick-notes workflow rooted at ~/Documents/notes/, mirroring Quanta's layout
-- (github.com/itsmohitanand/notes + the Quanta app's journal.py):
--   inbox/dump.md         <- single freeform capture file, any heading, dump anything
--   daily/YYYY-MM-DD.md   <- today's journal, one file per day
--   <folder>/<slug>.md    <- durable named-folder notes (folder = category)
-- "topics" is being reworked into AI-generated "reflection" output (TODO, deferred).
-- Keys:
--   <leader>nn  open the dump file (jumps to end, ready to append)
--   <leader>nd  open today's daily journal
--   <leader>nN  prompt for "folder/title", open note there
-- Auto-commits any save into ~/Documents/notes/ git repo (no auto-push).

local NOTES_DIR = vim.fn.expand('~/Documents/notes')

local function slugify(s)
  return (s:lower():gsub('[^a-z0-9]+', '-'):gsub('^%-+', ''):gsub('%-+$', ''))
end

local function open_note(path)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function dump_note()
  open_note(NOTES_DIR .. '/inbox/dump.md')
  vim.cmd('normal! G')
end

local function daily_note()
  open_note(NOTES_DIR .. '/daily/' .. os.date('%Y-%m-%d') .. '.md')
end

local function folder_note()
  vim.ui.input({ prompt = 'folder/title (e.g. work/roadmap): ' }, function(input)
    if not input or input == '' then return end
    local folder, title = input:match('^(.-)/(.+)$')
    if not folder or folder == '' then
      vim.notify("note: expected 'folder/title'", vim.log.levels.WARN)
      return
    end
    local slug = slugify(title)
    if slug == '' then
      vim.notify('note: empty slug', vim.log.levels.WARN)
      return
    end
    open_note(NOTES_DIR .. '/' .. slugify(folder) .. '/' .. slug .. '.md')
  end)
end

vim.keymap.set('n', '<leader>nn', dump_note, { desc = 'Notes: dump' })
vim.keymap.set('n', '<leader>nd', daily_note, { desc = 'Notes: today' })
vim.keymap.set('n', '<leader>nN', folder_note, { desc = 'Notes: new folder note' })

-- Autosave .md notes every 30 s; timer lives for the lifetime of the buffer.
local autosave_timers = {}

local function is_notes_md(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  return file:find('^' .. NOTES_DIR .. '/') and file:match('%.md$')
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
  pattern = '*.md',
  group = as_group,
  callback = function(args)
    if is_notes_md(args.buf) then start_autosave(args.buf) end
  end,
})

vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
  pattern = '*.md',
  group = as_group,
  callback = function(args) stop_autosave(args.buf) end,
})

-- Auto-commit + push all notes changes once, just before Neovim exits.
-- `timeout 10` caps the push so a dead/offline connection can't hang the quit.
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = vim.api.nvim_create_augroup('notes_autocommit', { clear = true }),
  callback = function()
    local msg = string.format('notes: autosave @ %s', os.date('%Y-%m-%d %H:%M'))
    -- Synchronous: we must finish before the process exits.
    local add = vim.system({ 'git', '-C', NOTES_DIR, 'add', '-A' }, { text = true }):wait()
    if add.code == 0 then
      vim.system(
        { 'git', '-C', NOTES_DIR, 'commit', '--quiet', '-m', msg },
        { text = true }
      ):wait()
      -- exit 1 means nothing staged — that's fine, ignore silently.
    end
    vim.system(
      { 'timeout', '10', 'git', '-C', NOTES_DIR, 'push', '--quiet', 'origin', 'main' },
      { text = true }
    ):wait()
    -- push failures (offline, conflicts) are silent here; next close retries.
  end,
})

return {}
