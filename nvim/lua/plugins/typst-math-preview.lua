-- Cursor-triggered preview of the Typst math span under the cursor.
--
-- Two backends, auto-selected from $TERM:
--   kitty  — TERM matches kitty/ghostty. PNG → base64 → kitty graphics APC
--            escape. Kitty's native protocol; high fidelity, no chafa.
--   sixel  — everything else. PNG → chafa --format=sixel → DCS sequence.
--
-- Pipeline (kitty):   $extracted$ → typst compile (PNG) → base64 → \eG…\e\\
-- Pipeline (sixel):   $extracted$ → typst compile (PNG) → chafa → \eP…\e\\
--
-- Either way the resulting bytes are written directly to /dev/tty, bypassing
-- nvim's grid renderer. Cached on disk keyed by equation hash + backend.
--
-- Multiplexer note: inside zellij, /dev/tty is zellij's pty. Zellij may strip
-- APC (kitty graphics) escapes. If preview works outside zellij but not in,
-- that's the zellij passthrough story — upgrade zellij or run nvim outside it.
--
-- Caveat: because the image bypasses nvim's grid, any nvim redraw paints
-- over it. We clear-and-redraw the affected rows whenever the cursor leaves
-- the span; if you want the image back, jiggle the cursor.
--
-- Prerequisites on PATH:
--   typst                  — always required
--   chafa                  — required only for the sixel backend

local cfg = {
  enabled    = true,
  backend    = 'auto',       -- 'auto' | 'kitty' | 'sixel'
  hold_ms    = 250,          -- debounce after cursor stops moving
  ppi        = 220,
  cell_cols  = 40,           -- display footprint, in terminal cells
  cell_rows  = 12,
  text_size  = '18pt',
  cache_dir  = vim.fn.stdpath('cache') .. '/typst-math-preview',
}

local function backend()
  if cfg.backend and cfg.backend ~= 'auto' then return cfg.backend end
  local term = vim.env.TERM or ''
  if term:match('kitty') or term:match('ghostty') then return 'kitty' end
  return 'sixel'
end

vim.fn.mkdir(cfg.cache_dir, 'p')

-- ─── State ────────────────────────────────────────────────────────────────

local state = {
  active      = false,
  drawn_rows  = {},     -- 1-indexed terminal rows we painted into
  current_key = nil,
  pending     = false,
}

local timer

-- ─── Span detection ───────────────────────────────────────────────────────

-- Find an inline $...$ on `line` enclosing `col` (0-indexed byte offset).
local function inline_span_at(line, col)
  local pos = {}
  for i = 1, #line do
    if line:sub(i, i) == '$' then pos[#pos+1] = i end
  end
  for i = 1, #pos - 1, 2 do
    local s, e = pos[i], pos[i+1]
    if col >= s - 1 and col <= e - 1 then
      return { text = line:sub(s + 1, e - 1), kind = 'inline' }
    end
  end
  return nil
end

-- Find a block-math span enclosing 0-indexed `row` by scanning the buffer
-- from top, toggling an in-math flag at each standalone `$` line. O(n) lines
-- but only called after the hold debounce.
local function block_span_at(buf, row)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local in_math, open_row = false, nil
  for i, l in ipairs(lines) do
    if l:match('^%s*%$%s*$') then
      if in_math then
        local close_row = i - 1   -- 0-indexed
        if row >= open_row and row <= close_row then
          local body = table.concat(
            vim.api.nvim_buf_get_lines(buf, open_row + 1, close_row, false), '\n')
          return { text = body, kind = 'block',
                   open_row = open_row, close_row = close_row }
        end
        in_math = false
      else
        open_row = i - 1
        in_math  = true
      end
    end
  end
  return nil
end

local function find_span(buf, row, col)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ''
  return inline_span_at(line, col) or block_span_at(buf, row)
end

-- ─── Compile + convert ────────────────────────────────────────────────────

local function key_for(text, kind)
  return vim.fn.sha256(kind .. '|' .. text):sub(1, 16)
end

local function paths_for(key)
  return {
    typ     = cfg.cache_dir .. '/' .. key .. '.typ',
    png     = cfg.cache_dir .. '/' .. key .. '.png',
    payload = cfg.cache_dir .. '/' .. key .. '.' .. backend(),
  }
end

-- Build a kitty graphics protocol payload from a PNG file. The protocol
-- chunks base64 data inside APC (`\eG…\e\\`) escapes; first chunk carries the
-- options, subsequent chunks just continue with `m=1`, last chunk uses `m=0`.
-- We constrain footprint with r= and c= so the image scales to fit our cells.
local function build_kitty_payload(png_path)
  local f = io.open(png_path, 'rb')
  if not f then return nil end
  local png = f:read('*all'); f:close()
  if not png or #png == 0 then return nil end
  local b64 = vim.base64.encode(png)

  local parts, chunk_size, i = {}, 4096, 1
  while i <= #b64 do
    local chunk = b64:sub(i, i + chunk_size - 1)
    i = i + chunk_size
    local more = (i <= #b64) and 1 or 0
    local opts
    if #parts == 0 then
      opts = string.format('f=100,a=T,C=1,r=%d,c=%d,m=%d',
                           cfg.cell_rows, cfg.cell_cols, more)
    else
      opts = 'm=' .. more
    end
    parts[#parts + 1] = '\27_G' .. opts .. ';' .. chunk .. '\27\\'
  end
  return table.concat(parts)
end

local function write_stub(path, text, kind)
  local body = (kind == 'block') and ('$\n' .. text .. '\n$\n')
                                  or ('$' .. text .. '$\n')
  local doc = string.format(
    '#set page(width: auto, height: auto, margin: 4pt)\n'
 .. '#set text(size: %s)\n%s', cfg.text_size, body)
  local f = assert(io.open(path, 'w'))
  f:write(doc); f:close()
end

local function cache_payload(path, data)
  local f = io.open(path, 'wb')
  if f then f:write(data); f:close() end
end

local function render(span, on_done)
  local key = key_for(span.text, span.kind)
  local p   = paths_for(key)

  -- Cache hit
  if vim.fn.filereadable(p.payload) == 1 then
    local f = io.open(p.payload, 'rb')
    local data = f:read('*all'); f:close()
    return on_done(key, data)
  end

  write_stub(p.typ, span.text, span.kind)

  vim.system(
    { 'typst', 'compile', '--format', 'png',
      '--ppi', tostring(cfg.ppi), p.typ, p.png },
    { text = true },
    vim.schedule_wrap(function(typst_res)
      if typst_res.code ~= 0 then return end

      if backend() == 'kitty' then
        local payload = build_kitty_payload(p.png)
        if not payload then return end
        cache_payload(p.payload, payload)
        on_done(key, payload)
      else
        vim.system(
          { 'chafa', '--format=sixel',
            '--size=' .. cfg.cell_cols .. 'x' .. cfg.cell_rows,
            '--animate=off', p.png },
          { text = false },
          vim.schedule_wrap(function(chafa_res)
            if chafa_res.code ~= 0 or not chafa_res.stdout then return end
            cache_payload(p.payload, chafa_res.stdout)
            on_done(key, chafa_res.stdout)
          end))
      end
    end))
end

-- ─── /dev/tty emit ────────────────────────────────────────────────────────

local CSI = '\27['

local function tty_write(s)
  local f = io.open('/dev/tty', 'wb')
  if not f then return end
  f:write(s); f:close()
end

local function emit_payload(data)
  local screen_row = vim.fn.screenrow()
  local total_rows = vim.o.lines
  local anchor = math.min(screen_row + 1, total_rows - 1)

  -- Save cursor, move, paint, restore. The host terminal owns this cursor;
  -- nvim's logical cursor is unaffected.
  tty_write(CSI .. 's'
         .. CSI .. anchor .. ';1H'
         .. data
         .. CSI .. 'u')

  state.drawn_rows = {}
  for r = anchor, math.min(anchor + cfg.cell_rows - 1, total_rows) do
    state.drawn_rows[#state.drawn_rows + 1] = r
  end
end

local function clear_drawn()
  if #state.drawn_rows == 0 then return end

  -- Kitty graphics images live in a separate layer above the cell grid; the
  -- grid-clear below won't remove them. Issue an explicit delete-all-visible.
  if backend() == 'kitty' then
    tty_write('\27_Ga=d,d=A;\27\\')
  end

  local out = CSI .. 's'
  for _, r in ipairs(state.drawn_rows) do
    out = out .. CSI .. r .. ';1H' .. CSI .. '2K'
  end
  out = out .. CSI .. 'u'
  tty_write(out)
  state.drawn_rows = {}
  vim.schedule(function() vim.cmd('redraw!') end)
end

-- ─── Tick ─────────────────────────────────────────────────────────────────

local function tick()
  if not cfg.enabled then return end
  if vim.bo.filetype ~= 'typst' then return end

  local buf  = vim.api.nvim_get_current_buf()
  local pos  = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
  local span = find_span(buf, row, col)

  if not span then
    if state.active then
      clear_drawn(); state.active = false; state.current_key = nil
    end
    return
  end

  local key = key_for(span.text, span.kind)
  if state.current_key == key and state.active then return end
  if state.pending then return end

  state.pending = true
  render(span, function(rendered_key, data)
    state.pending = false
    -- Re-check after the async work: cursor may have moved away.
    local p2  = vim.api.nvim_win_get_cursor(0)
    local s2  = find_span(buf, p2[1] - 1, p2[2])
    if not s2 or key_for(s2.text, s2.kind) ~= rendered_key then return end
    clear_drawn()
    emit_payload(data)
    state.active      = true
    state.current_key = rendered_key
  end)
end

local function schedule_tick()
  if timer then timer:stop() end
  timer = vim.defer_fn(function() timer = nil; tick() end, cfg.hold_ms)
end

-- ─── Setup ────────────────────────────────────────────────────────────────

local function check_prereqs()
  local needed = { 'typst' }
  if backend() == 'sixel' then needed[#needed + 1] = 'chafa' end
  local missing = {}
  for _, bin in ipairs(needed) do
    if vim.fn.executable(bin) ~= 1 then missing[#missing + 1] = bin end
  end
  if #missing == 0 then return true end
  cfg.enabled = false
  vim.notify(
    'typst-math-preview disabled (backend=' .. backend() .. '): missing '
 .. table.concat(missing, ', ')
 .. ' on PATH. Install and run :TypstMathPreviewToggle.',
    vim.log.levels.WARN)
  return false
end

local function setup()
  check_prereqs()

  local g = vim.api.nvim_create_augroup('typst_math_preview', { clear = true })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'InsertLeave' }, {
    group = g, pattern = '*.typ',
    callback = schedule_tick,
  })

  vim.api.nvim_create_autocmd({ 'BufLeave', 'WinLeave', 'VimLeavePre' }, {
    group = g, pattern = '*.typ',
    callback = function()
      if state.active then
        clear_drawn(); state.active = false; state.current_key = nil
      end
    end,
  })

  vim.api.nvim_create_user_command('TypstMathPreviewToggle', function()
    if cfg.enabled then
      cfg.enabled = false
      if state.active then
        clear_drawn(); state.active = false; state.current_key = nil
      end
      vim.notify('Typst math preview: off')
    else
      cfg.enabled = true
      if not check_prereqs() then return end   -- check_prereqs flips it off again
      vim.notify('Typst math preview: on')
    end
  end, {})

  vim.api.nvim_create_user_command('TypstMathPreviewClear', function()
    if state.active then
      clear_drawn(); state.active = false; state.current_key = nil
    end
  end, {})

  vim.api.nvim_create_user_command('TypstMathPreviewCacheClear', function()
    vim.fn.delete(cfg.cache_dir, 'rf')
    vim.fn.mkdir(cfg.cache_dir, 'p')
    vim.notify('Typst math preview cache cleared')
  end, {})

  -- Diagnostic: run the full pipeline on the span under the cursor and report
  -- each stage to :messages. Usage: :TypstMathPreviewDebug
  vim.api.nvim_create_user_command('TypstMathPreviewDebug', function()
    local lines = {}
    local function log(s) lines[#lines + 1] = '[typst-math-preview] ' .. s end
    local function flush() vim.notify(table.concat(lines, '\n')) end

    local bk = backend()
    log('backend=' .. bk .. ' enabled=' .. tostring(cfg.enabled)
       .. ' typst=' .. vim.fn.executable('typst')
       .. ' chafa=' .. vim.fn.executable('chafa')
       .. ' ft=' .. vim.bo.filetype
       .. ' TERM=' .. (vim.env.TERM or '?')
       .. ' ZELLIJ=' .. (vim.env.ZELLIJ and 'yes' or 'no'))

    local buf = vim.api.nvim_get_current_buf()
    local pos = vim.api.nvim_win_get_cursor(0)
    local span = find_span(buf, pos[1] - 1, pos[2])
    if not span then
      log('no span at cursor (row=' .. (pos[1] - 1) .. ' col=' .. pos[2] .. ')')
      flush(); return
    end
    log('span kind=' .. span.kind .. ' len=' .. #span.text
       .. ' text=' .. span.text:sub(1, 60))

    local key = key_for(span.text, span.kind)
    local p   = paths_for(key)
    write_stub(p.typ, span.text, span.kind)
    log('stub: ' .. p.typ)

    vim.system(
      { 'typst', 'compile', '--format', 'png',
        '--ppi', tostring(cfg.ppi), p.typ, p.png },
      { text = true },
      vim.schedule_wrap(function(tr)
        log('typst exit=' .. tr.code .. ' stderr=' .. (tr.stderr or ''):sub(1, 200))
        if tr.code ~= 0 then flush(); return end
        log('png size=' .. (vim.fn.getfsize(p.png)) .. ' bytes')

        if bk == 'kitty' then
          local payload = build_kitty_payload(p.png)
          if not payload then log('kitty payload: build failed'); flush(); return end
          log('kitty payload: ' .. #payload .. ' bytes')
          log('first 40 chars: ' .. vim.inspect(payload:sub(1, 40)))
          flush()
          emit_payload(payload)
          state.active = true
          state.current_key = key
        else
          vim.system(
            { 'chafa', '--format=sixel',
              '--size=' .. cfg.cell_cols .. 'x' .. cfg.cell_rows,
              '--animate=off', p.png },
            { text = false },
            vim.schedule_wrap(function(cr)
              log('chafa exit=' .. cr.code .. ' bytes=' .. #(cr.stdout or ''))
              log('first 30 chars: ' .. vim.inspect((cr.stdout or ''):sub(1, 30)))
              flush()
              if cr.code == 0 and cr.stdout and #cr.stdout > 0 then
                emit_payload(cr.stdout)
                state.active = true
                state.current_key = key
              end
            end))
        end
      end))
  end, {})
end

setup()
return {}
