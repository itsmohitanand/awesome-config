-- Quick-notes workflow rooted at /data/notes/.
-- Layout (seed structure; an agent reorganizes periodically):
--   daily/YYYY-MM-DD.typ   <- today's journal
--   topics/<slug>.typ      <- durable single-subject notes
--   inbox/                 <- (agent-managed) unsorted capture
-- Keys:
--   <leader>nn  open today's daily note
--   <leader>nN  prompt for title, open topical note
-- Auto-commits any save inside /data/notes/ (no auto-push).

local NOTES_DIR = '/data/notes'

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

-- Auto-commit on save inside /data/notes/. Async, silent on success.
vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup('notes_autocommit', { clear = true }),
  callback = function(args)
    local file = vim.fn.fnamemodify(args.file, ':p')
    if not file:find('^' .. NOTES_DIR .. '/') then return end

    local rel = file:sub(#NOTES_DIR + 2)
    local msg = string.format('note: %s @ %s', rel, os.date('%Y-%m-%d %H:%M'))

    vim.system({ 'git', '-C', NOTES_DIR, 'add', '--', file }, { text = true }, function(add)
      if add.code ~= 0 then
        vim.schedule(function()
          vim.notify('note auto-commit: git add failed\n' .. (add.stderr or ''), vim.log.levels.ERROR)
        end)
        return
      end
      vim.system(
        { 'git', '-C', NOTES_DIR, 'commit', '--quiet', '--only', '--', file, '-m', msg },
        { text = true },
        function(commit)
          -- exit 1 with no changes staged is normal (empty save) — ignore silently.
          if commit.code ~= 0 and commit.code ~= 1 then
            vim.schedule(function()
              vim.notify('note auto-commit failed\n' .. (commit.stderr or ''), vim.log.levels.ERROR)
            end)
          end
        end
      )
    end)
  end,
})

return {}
