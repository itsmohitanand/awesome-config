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
        repl_open_cmd = view.bottom("30%"),
      },
      keymaps = {},
      highlight = {
        italic = true,
      },
      ignore_blank_lines = true,
    })

    -- Iron keymaps, set globally but guarded to avoid errors in non-REPL filetypes
    local iron_fts = { python = true, sh = true, bash = true }
    local function iron_keymap(modes, lhs, rhs, desc)
      vim.keymap.set(modes, lhs, function()
        if iron_fts[vim.bo.filetype] then
          vim.cmd(rhs)
        end
      end, { desc = desc })
    end
    local function iron_action(modes, lhs, action, desc)
      vim.keymap.set(modes, lhs, function()
        if iron_fts[vim.bo.filetype] then
          action()
        end
      end, { desc = desc })
    end

    iron_keymap('n', '<leader>rr', 'IronRepl', 'Toggle REPL')
    iron_keymap('n', '<leader>rR', 'IronRestart', 'Restart REPL')
    iron_keymap('n', '<leader>rf', 'IronSendFile', 'Send file to REPL')
    iron_keymap('n', '<leader>rl', 'IronSendLine', 'Send line to REPL')
    iron_keymap('n', '<leader>ri', 'IronInterrupt', 'Interrupt REPL')
    iron_keymap('n', '<leader>rq', 'IronExit', 'Exit REPL')
    iron_keymap('n', '<leader>rx', 'IronClear', 'Clear REPL')
    iron_action({'n', 'v'}, '<leader>rc', function() iron.send_motion() end, 'Send motion/visual to REPL')
    iron_action('n', '<leader>rp', function() iron.send_paragraph() end, 'Send paragraph to REPL')
    iron_action('n', '<leader>ru', function() iron.send_until_cursor() end, 'Send until cursor to REPL')
    iron_action('n', '<leader>rb', function() iron.send_code_block() end, 'Send code block to REPL')
    iron_action('n', '<leader>rj', function() iron.send_code_block_and_move() end, 'Send code block and move')
    vim.keymap.set('n', '<leader>rF', '<cmd>IronFocus<cr>', { desc = 'Focus REPL' })
    vim.keymap.set('n', '<leader>rh', '<cmd>IronHide<cr>', { desc = 'Hide REPL' })
  end,
}
