return {
  'Vigemus/iron.nvim',
  config = function()
    local iron = require('iron.core')
    local view = require('iron.view')
    local common = require('iron.fts.common')

    iron.setup({
      config = {
        scratch_repl = true,
        repl_definition = {
          python = {
            command = function()
              local venv = vim.env.VIRTUAL_ENV or vim.env.UV_PROJECT_ENVIRONMENT
              local ipython = venv and (venv .. '/bin/ipython') or vim.fn.exepath('ipython')
              if ipython == '' then
                error('ipython not found — activate your uv environment first')
              end
              return { ipython, '--no-autoindent' }
            end,
            format = common.bracketed_paste_python,
            block_dividers = { '# %%', '#%%' },
          },
          sh = {
            command = { 'zsh' },
          },
        },
        repl_open_cmd = view.split.vertical.botright("40%"),
      },
      keymaps = {},
      highlight = {
        italic = true,
      },
      ignore_blank_lines = true,
    })

    -- Iron keymaps, set globally but guarded to avoid errors in non-REPL filetypes
    local iron_fts = { python = true, sh = true, bash = true }
    local function iron_action(modes, lhs, action, desc)
      vim.keymap.set(modes, lhs, function()
        if iron_fts[vim.bo.filetype] then
          action()
        end
      end, { desc = desc })
    end

    iron_action('n', '<leader>rr', function() iron.repl_for(vim.bo.filetype) end, 'Toggle REPL')
    iron_action('n', '<leader>rR', function() iron.repl_restart() end, 'Restart REPL')
    iron_action('n', '<leader>rf', function() iron.send_file() end, 'Send file to REPL')
    iron_action('n', '<leader>rl', function() iron.send_line() end, 'Send line to REPL')
    iron_action('n', '<leader>ri', function() iron.send_interrupt() end, 'Interrupt REPL')
    iron_action('n', '<leader>rq', function() iron.close_repl() end, 'Exit REPL')
    iron_action('n', '<leader>rx', function() iron.clear() end, 'Clear REPL')
    iron_action('n', '<leader>rc', function() iron.send_motion() end, 'Send motion to REPL')
    iron_action('v', '<leader>rc', function() iron.visual_send() end, 'Send visual selection to REPL')
    iron_action('n', '<leader>rp', function() iron.send_paragraph() end, 'Send paragraph to REPL')
    iron_action('n', '<leader>ru', function() iron.send_until_cursor() end, 'Send until cursor to REPL')
    iron_action('n', '<leader>rb', function() iron.send_code_block(false) end, 'Send code block to REPL')
    iron_action('n', '<leader>rj', function() iron.send_code_block(true) end, 'Send code block and move')
    iron_action('n', '<leader>rF', function() iron.focus_on(vim.bo.filetype) end, 'Focus REPL')
    iron_action('n', '<leader>rh', function() iron.hide_repl() end, 'Hide REPL')

    -- Escape terminal mode and jump back to code window, only inside iron REPL buffers
    vim.api.nvim_create_autocmd('TermOpen', {
      callback = function(ev)
        local name = vim.api.nvim_buf_get_name(ev.buf)
        if name:match('ipython') then
          vim.keymap.set('t', '<C-space>', '<C-\\><C-n><C-w>w', { buffer = ev.buf, desc = 'Escape REPL and focus code' })
        end
      end,
    })
  end,
}
