-- Neorg-style WYSIWYG-lite for Typst (.typ) files.
--
-- Layer 1 — Conceal + Extmarks (this file):
--   Headings : coloured icon + background bar,  = signs concealed
--   Bold     : *  concealed, warm-pink bold
--   Italic   : _  concealed, seafoam italic
--   Code     : `backticks` concealed, code-block highlight
--   Math     : $ delimiters highlighted in lilac, kept editable inline
--   Raw blks : ``` … ``` styled throughout
--   Bullets  : -  →  • / ◦ / ▸ (depth-aware)
--   Enums    : 1. numbers highlighted
--
-- Layer 2 — math side panel (typst-preview.nvim + tinymist):
--   <leader>tp  live browser preview — full fidelity, math rendered perfectly
--   <leader>tv  PDF in Zathura (auto-reloads on save)
--   Open either panel and keep it beside Neovim for equation previewing.
--
-- Layer 3 — cursor-triggered sixel preview (typst-math-preview.lua):
--   On CursorHold inside $…$, the equation under the cursor is compiled to
--   PNG, converted to sixel via chafa, and emitted to /dev/tty just below
--   the line. Works in zellij (native sixel) and any sixel-capable terminal.
--   Move the cursor away to dismiss.  :TypstMathPreviewToggle / Clear
--
-- Prerequisites (run once inside Neovim):
--   :MasonInstall tinymist   — LSP + PDF builder
--   :TSInstall typst         — treesitter grammar (after nvim-treesitter loads)

-- ─── Namespace ─────────────────────────────────────────────────────────────

local ns = vim.api.nvim_create_namespace('typst_render')

-- ─── Poimandres palette highlight groups ───────────────────────────────────

local function def_hl()
  local s = vim.api.nvim_set_hl
  -- Heading backgrounds (dark tinted layers)
  s(0, 'TypstH1Bg',    { bg = '#232637' })
  s(0, 'TypstH2Bg',    { bg = '#1f2133' })
  s(0, 'TypstH3Bg',    { bg = '#1c1e2e' })
  -- Heading icons + text
  s(0, 'TypstH1',      { fg = '#5de4c7', bold = true })   -- poimandres cyan
  s(0, 'TypstH2',      { fg = '#add7ff', bold = true })   -- sky blue
  s(0, 'TypstH3',      { fg = '#89ddff', bold = true })   -- light blue
  s(0, 'TypstH4',      { fg = '#91b4d5', bold = true })   -- muted blue
  -- Inline markup
  s(0, 'TypstBold',    { fg = '#f087bd', bold = true })   -- pink
  s(0, 'TypstItalic',  { fg = '#5fb3a1', italic = true }) -- seafoam
  s(0, 'TypstCode',    { fg = '#a6accd', bg = '#1e2033' })
  -- Block-level
  s(0, 'TypstCodeBlk', { bg = '#191b2a' })
  s(0, 'TypstMath',    { fg = '#fcc5e9' })                -- light lilac/pink
  s(0, 'TypstMathBlk', { bg = '#1e1c2e' })
  -- Structural
  s(0, 'TypstBullet',  { fg = '#5de4c7' })
  s(0, 'TypstEnum',    { fg = '#add7ff', bold = true })
  s(0, 'TypstHRule',   { fg = '#2d2f45' })
  s(0, 'TypstLabel',   { fg = '#d0679d', italic = true }) -- labels <like-this>
end

-- ─── Tables ────────────────────────────────────────────────────────────────

local H_ICON = { '󰉫 ', '󰉬 ', '󰉭 ', '󰉮 ', '󰉯 ', '󰉰 ' }
local H_BG   = { 'TypstH1Bg', 'TypstH2Bg', 'TypstH3Bg',
                 'TypstH3Bg', 'TypstH3Bg', 'TypstH3Bg' }
local H_FG   = { 'TypstH1', 'TypstH2', 'TypstH3',
                 'TypstH4', 'TypstH4', 'TypstH4' }
local SYMS   = { '•', '◦', '▸', '▹' }

-- ─── Inline span scanner ───────────────────────────────────────────────────
-- Left-to-right, first-match-wins.  Math/code "consume" their range so that
-- bold/italic delimiters inside $…$ or `…` are never matched.

local function scan_inline(line)
  local spans = {}
  local i, len = 1, #line

  while i <= len do
    local c = line:sub(i, i)

    if c == '$' then
      -- Inline or display math: $…$ (Typst has only one math delimiter)
      local j = line:find('%$', i + 1)
      if j then
        spans[#spans + 1] = { 'math', i, j }
        i = j + 1
      else
        i = i + 1
      end

    elseif c == '`' then
      local j = line:find('`', i + 1)
      if j then
        spans[#spans + 1] = { 'code', i, j }
        i = j + 1
      else
        i = i + 1
      end

    elseif c == '*' then
      local j = line:find('%*', i + 1)
      if j and j > i + 1 then
        spans[#spans + 1] = { 'bold', i, j }
        i = j + 1
      else
        i = i + 1
      end

    elseif c == '_' then
      local j = line:find('_', i + 1)
      if j and j > i + 1 then
        spans[#spans + 1] = { 'italic', i, j }
        i = j + 1
      else
        i = i + 1
      end

    elseif c == '<' then
      -- Typst labels: <my-label>
      local j = line:find('>', i + 1)
      if j and not line:sub(i + 1, j - 1):find('%s') then
        spans[#spans + 1] = { 'label', i, j }
        i = j + 1
      else
        i = i + 1
      end

    else
      i = i + 1
    end
  end

  return spans
end

-- ─── Extmark helpers ───────────────────────────────────────────────────────

local function mark(buf, row, cs, ce, opts)
  opts.end_col = ce
  vim.api.nvim_buf_set_extmark(buf, ns, row, cs, opts)
end

local function bg_line(buf, row, hl, pri)
  vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
    hl_group = hl,
    hl_eol   = true,
    end_row  = row + 1,
    priority = pri or 10,
  })
end

-- ─── Per-line decoration ───────────────────────────────────────────────────

local function decorate(buf, lnum, line)
  if line == '' then return end

  -- ── Heading ──────────────────────────────────────────────────────────────
  local eq = line:match('^(=+)')
  if eq then
    local lvl    = math.min(#eq, 6)
    local after  = line:sub(#eq + 1)
    local gap    = after:sub(1, 1) == ' ' and 1 or 0
    local prefix = #eq + gap

    bg_line(buf, lnum, H_BG[lvl], 10)

    -- Replace the entire "=…= " prefix with the heading icon
    vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
      virt_text     = {{ H_ICON[lvl], H_FG[lvl] }},
      virt_text_pos = 'overlay',
      end_col       = prefix,
      priority      = 20,
    })

    -- Highlight the heading text itself
    if prefix < #line then
      mark(buf, lnum, prefix, #line, { hl_group = H_FG[lvl], priority = 20 })
    end
    return  -- headings don't have further inline markup
  end

  -- ── Horizontal rule (--- or more) ────────────────────────────────────────
  if line:match('^%-%-%-+%s*$') then
    vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
      virt_text     = {{ string.rep('─', 72), 'TypstHRule' }},
      virt_text_pos = 'overlay',
      priority      = 20,
    })
    return
  end

  -- ── Bullet list item ─────────────────────────────────────────────────────
  local ind_b = line:match('^(%s*)%- ')
  if ind_b then
    local depth = math.floor(#ind_b / 2) + 1
    local sym   = SYMS[math.min(depth, #SYMS)]
    vim.api.nvim_buf_set_extmark(buf, ns, lnum, #ind_b, {
      end_col       = #ind_b + 1,
      virt_text     = {{ sym, 'TypstBullet' }},
      virt_text_pos = 'overlay',
      priority      = 20,
    })
    -- fall-through: continue to render inline spans in the bullet text
  end

  -- ── Numbered list item ───────────────────────────────────────────────────
  local ind_e, numstr = line:match('^(%s*)(%d+)%.')
  if ind_e then
    mark(buf, lnum, #ind_e, #ind_e + #numstr + 1,
      { hl_group = 'TypstEnum', priority = 20 })
    -- fall-through
  end

  -- ── Inline spans ─────────────────────────────────────────────────────────
  for _, sp in ipairs(scan_inline(line)) do
    local kind       = sp[1]
    local s0, e0     = sp[2] - 1, sp[3] - 1  -- 0-indexed

    if kind == 'math' then
      mark(buf, lnum, s0, e0 + 1, { hl_group = 'TypstMath', priority = 30 })

    elseif kind == 'code' then
      mark(buf, lnum, s0,     s0 + 1, { conceal = '',           priority = 30 })
      mark(buf, lnum, s0 + 1, e0,     { hl_group = 'TypstCode', priority = 30 })
      mark(buf, lnum, e0,     e0 + 1, { conceal = '',           priority = 30 })

    elseif kind == 'bold' then
      mark(buf, lnum, s0,     s0 + 1, { conceal = '',             priority = 30 })
      mark(buf, lnum, s0 + 1, e0,     { hl_group = 'TypstBold',   priority = 30 })
      mark(buf, lnum, e0,     e0 + 1, { conceal = '',             priority = 30 })

    elseif kind == 'italic' then
      mark(buf, lnum, s0,     s0 + 1, { conceal = '',               priority = 30 })
      mark(buf, lnum, s0 + 1, e0,     { hl_group = 'TypstItalic',   priority = 30 })
      mark(buf, lnum, e0,     e0 + 1, { conceal = '',               priority = 30 })

    elseif kind == 'label' then
      mark(buf, lnum, s0, e0 + 1, { hl_group = 'TypstLabel', priority = 30 })
    end
  end
end

-- ─── Full buffer render pass ───────────────────────────────────────────────

local function render(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if vim.bo[buf].filetype ~= 'typst'    then return end

  local win = vim.fn.bufwinid(buf)
  if win == -1 then return end

  local cursor = vim.api.nvim_win_get_cursor(win)[1] - 1  -- 0-indexed
  local first  = vim.fn.line('w0', win) - 1
  local last   = vim.fn.line('w$', win)

  vim.api.nvim_buf_clear_namespace(buf, ns, first, last)

  -- Determine block state (raw / math) at `first` by scanning from line 0.
  -- This handles the case where the visible window starts inside a block.
  local in_raw, in_math = false, false
  if first > 0 then
    for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, first, false)) do
      if l:match('^```')             then in_raw  = not in_raw  end
      if not in_raw and l:match('^%s*%$%s*$') then in_math = not in_math end
    end
  end

  local lines = vim.api.nvim_buf_get_lines(buf, first, last, false)

  for i, line in ipairs(lines) do
    local lnum = first + i - 1

    -- ── Raw code block ───────────────────────────────────────────────────
    if line:match('^```') then
      in_raw = not in_raw
      bg_line(buf, lnum, 'TypstCodeBlk', 10)

    elseif in_raw then
      bg_line(buf, lnum, 'TypstCodeBlk', 10)

    -- ── Block math (standalone $ on its own line) ────────────────────────
    elseif not in_raw and line:match('^%s*%$%s*$') then
      in_math = not in_math
      bg_line(buf, lnum, 'TypstMathBlk', 10)

    elseif in_math then
      bg_line(buf, lnum, 'TypstMathBlk', 10)

    -- ── Normal text — skip the cursor line so raw syntax shows through ───
    elseif lnum ~= cursor then
      decorate(buf, lnum, line)
    end
  end
end

-- ─── Debounced scheduling ──────────────────────────────────────────────────

local _tmr = {}
local function sched(buf)
  if _tmr[buf] then _tmr[buf]:stop() end
  _tmr[buf] = vim.defer_fn(function()
    _tmr[buf] = nil
    render(buf)
  end, 80)
end

-- ─── Autocmds ──────────────────────────────────────────────────────────────

local function setup()
  local g = vim.api.nvim_create_augroup('typst_render', { clear = true })

  -- Set buffer options and run first render when a typst file opens
  vim.api.nvim_create_autocmd('FileType', {
    group   = g,
    pattern = 'typst',
    callback = function(ev)
      vim.opt_local.conceallevel  = 2
      vim.opt_local.concealcursor = ''  -- cursor line always shows raw text
      render(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinScrolled' }, {
    group   = g,
    pattern = '*.typ',
    callback = function(ev) render(ev.buf) end,
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group   = g,
    pattern = '*.typ',
    callback = function(ev) sched(ev.buf) end,
  })

  -- Re-render when cursor changes line to move the "raw zone"
  local _prev = {}
  vim.api.nvim_create_autocmd('CursorMoved', {
    group   = g,
    pattern = '*.typ',
    callback = function(ev)
      local ln = vim.api.nvim_win_get_cursor(0)[1]
      if ln ~= _prev[ev.buf] then
        _prev[ev.buf] = ln
        render(ev.buf)
      end
    end,
  })

  -- Re-apply highlights after any colorscheme switch
  vim.api.nvim_create_autocmd('ColorScheme', {
    group    = g,
    callback = function()
      def_hl()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == 'typst' then
          render(buf)
        end
      end
    end,
  })

  -- Handle the case where Neovim is launched directly on a .typ file:
  -- FileType already fired before our autocmd was registered, so we
  -- manually attach any already-open typst buffers.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == 'typst' then
      local win = vim.fn.bufwinid(buf)
      if win ~= -1 then
        vim.api.nvim_win_call(win, function()
          vim.opt_local.conceallevel  = 2
          vim.opt_local.concealcursor = ''
        end)
      end
      render(buf)
    end
  end
end

-- ─── Bootstrap ─────────────────────────────────────────────────────────────
-- def_hl() uses absolute colours so timing vs. colorscheme doesn't matter.
-- setup() is called immediately so the FileType autocmd is always registered
-- in time for the first buffer open.

def_hl()
setup()

return {}
