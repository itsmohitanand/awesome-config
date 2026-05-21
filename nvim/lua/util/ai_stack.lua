-- Stacked AI sidebar: keep at most one AI terminal (opencode or iron)
-- visible in the right column. Other buffers stay alive in the background.
-- A winbar shows which kinds are loaded and highlights the visible one.

local M = {}

-- Shared width so opencode and iron windows match exactly.
function M.width()
  return math.floor(vim.o.columns * 0.4)
end

local function set_winbar_on_buf_windows(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      vim.wo[win].winbar = '%{%v:lua.require("util.ai_stack").winbar()%}'
    end
  end
end

local group = vim.api.nvim_create_augroup('ai_stack', { clear = true })
vim.api.nvim_create_autocmd('TermOpen', {
  group = group,
  callback = function(ev)
    local name = vim.api.nvim_buf_get_name(ev.buf)
    if name:match('opencode') then
      vim.b[ev.buf].ai_kind = 'opencode'
    elseif name:match('ipython') then
      vim.b[ev.buf].ai_kind = 'iron'
    elseif vim.bo[ev.buf].filetype == 'sidekick_terminal' or vim.b[ev.buf].sidekick_cli then
      vim.b[ev.buf].ai_kind = 'sidekick'
    end
    if vim.b[ev.buf].ai_kind then
      set_winbar_on_buf_windows(ev.buf)
    end
  end,
})

vim.api.nvim_set_hl(0, 'AiStackActive',   { link = 'PmenuSel', default = true })
vim.api.nvim_set_hl(0, 'AiStackInactive', { link = 'Comment',  default = true })

-- Tag any currently-visible terminal window not already tagged as AI as
-- the given kind, and apply the winbar. Used by sidekick whose buffer names
-- don't match a predictable pattern (especially under zellij mux).
function M.tag_visible_terminals(kind)
  vim.schedule(function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == 'terminal' and not vim.b[buf].ai_kind then
        vim.b[buf].ai_kind = kind
        vim.wo[win].winbar = '%{%v:lua.require("util.ai_stack").winbar()%}'
      end
    end
  end)
end

-- Hide every AI sidebar window whose kind isn't `keep_kind`. Buffers stay alive.
function M.hide_others(keep_kind)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local kind = vim.b[buf].ai_kind
    if kind and kind ~= keep_kind then
      vim.api.nvim_win_hide(win)
    end
  end
end

-- Pane indicator. Only shows kinds that currently have a loaded buffer.
function M.winbar()
  local cur_kind = vim.b[vim.api.nvim_get_current_buf()].ai_kind
  local loaded = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].ai_kind then
      loaded[vim.b[buf].ai_kind] = true
    end
  end
  local parts = {}
  for _, k in ipairs({ 'opencode', 'iron', 'sidekick' }) do
    if loaded[k] then
      local marker = (k == cur_kind) and '●' or '○'
      local hl     = (k == cur_kind) and 'AiStackActive' or 'AiStackInactive'
      table.insert(parts, ('%%#%s# %s %s %%*'):format(hl, marker, k))
    end
  end
  return ' ' .. table.concat(parts, ' ') .. ' '
end

return M
