local function ollama_running()
  local uv = vim.uv or vim.loop
  local sock = uv.new_tcp()
  local done, ok = false, false
  sock:connect('127.0.0.1', 11434, function(err)
    ok = err == nil
    done = true
    sock:close()
  end)
  vim.wait(300, function() return done end)
  if not done then pcall(function() sock:close() end) end
  return ok
end

local function pick_ollama_model()
  -- Preference order: env var (comma-separated) overrides default.
  -- First tag in the list that ollama actually has pulled wins.
  local prefs_env = vim.env.NVIM_OPENCODE_MODELS
  local prefs = prefs_env and vim.split(prefs_env, ',', { trimempty = true })
              or { 'gemma4:26b', 'gemma4:e4b' }

  local res = vim.system(
    { 'curl', '-s', '--max-time', '2', 'http://127.0.0.1:11434/api/tags' },
    { text = true }
  ):wait()
  if res.code ~= 0 then return nil, 'failed to query ollama /api/tags' end

  local ok, data = pcall(vim.json.decode, res.stdout)
  if not ok or type(data) ~= 'table' or type(data.models) ~= 'table' then
    return nil, 'malformed response from ollama /api/tags'
  end

  local installed = {}
  for _, m in ipairs(data.models) do installed[m.name] = true end

  for _, tag in ipairs(prefs) do
    tag = vim.trim(tag)
    if installed[tag] then return 'ollama/' .. tag end
  end
  return nil, 'none of [' .. table.concat(prefs, ', ') .. '] are pulled. Try: ollama pull ' .. prefs[1]
end

return {
  'nickjvandyke/opencode.nvim',
  version = '*',
  -- opencode.nvim >= 0.10 dropped require('opencode').setup(); config now
  -- comes from vim.g.opencode_opts (deep-merged with defaults at load).
  init = function()
    vim.g.opencode_opts = {
      server = {
        start = function()
          if not ollama_running() then
            vim.notify(
              'ollama daemon is not running (127.0.0.1:11434 unreachable).\n'
                .. 'Start it: sudo systemctl start ollama   (or: ollama serve)',
              vim.log.levels.WARN,
              { title = 'opencode' }
            )
            return
          end
          local model, err = pick_ollama_model()
          if not model then
            vim.notify('opencode: ' .. err, vim.log.levels.WARN, { title = 'opencode' })
            return
          end
          local stack = require('util.ai_stack')
          stack.hide_others('opencode')
          require('opencode.terminal').open(
            'opencode --port --model ' .. model,
            {
              split = 'right',
              width = stack.width(),
            }
          )
        end,
      },
    }
  end,
  keys = {
    -- @this/@buffer/@diagnostics inject *file location refs*, so opencode
    -- reads from disk. Save the buffer first so the reference points at
    -- current text, not the last-saved version.
    { '<leader>oa', function() pcall(vim.cmd, 'silent! update'); require('opencode').ask('@this: ', { submit = true }) end, mode = { 'n', 'x' }, desc = 'Opencode: ask about this' },
    { '<leader>oA', function() pcall(vim.cmd, 'silent! update'); require('opencode').ask() end,                              mode = { 'n', 'x' }, desc = 'Opencode: ask (blank prompt)' },
    { '<leader>op', function() pcall(vim.cmd, 'silent! update'); require('opencode').select() end,                           mode = { 'n', 'x' }, desc = 'Opencode: pick built-in prompt' },
    { '<leader>ot', function() require('util.ai_stack').hide_others('opencode'); require('opencode').toggle() end,           desc = 'Opencode: toggle window' },
    { '<leader>od', function() pcall(vim.cmd, 'silent! update'); require('opencode').ask('Fix @diagnostics', { submit = true }) end, desc = 'Opencode: fix diagnostics' },
  },
}
