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
            command = { 'ipython', '--no-autoindent' },
            format = common.bracketed_paste_python,
            block_dividers = { '# %%', '#%%' },
          },
          sh = {
            command = { 'zsh' },
          },
        },
        repl_open_cmd = view.bottom(40),
      },
      keymaps = {
        toggle_repl = '<leader>rr',
        restart_repl = '<leader>rR',
        send_motion = '<leader>rc',
        visual_send = '<leader>rc',
        send_file = '<leader>rf',
        send_line = '<leader>rl',
        send_paragraph = '<leader>rp',
        send_until_cursor = '<leader>ru',
        send_code_block = '<leader>rb',
        send_code_block_and_move = '<leader>rj',
        interrupt = '<leader>ri',
        exit = '<leader>rq',
        clear = '<leader>rx',
      },
      highlight = {
        italic = true,
      },
      ignore_blank_lines = true,
    })

    vim.keymap.set('n', '<leader>rF', '<cmd>IronFocus<cr>', { desc = 'Focus REPL' })
    vim.keymap.set('n', '<leader>rh', '<cmd>IronHide<cr>', { desc = 'Hide REPL' })
  end,
}
