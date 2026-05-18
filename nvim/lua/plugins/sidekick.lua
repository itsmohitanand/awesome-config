return {
  'folke/sidekick.nvim',
  event = 'VeryLazy',
  opts = {
    nes = { enabled = false },
    cli = {
      mux = {
        enabled = true,
        backend = 'zellij',
      },
      win = {
        keys = {
          ['<c-q>'] = false,  -- disable (zellij reserved)
          ['<c-p>'] = false,  -- disable (zellij reserved)
          ['<M-\\>'] = function() require('sidekick.cli').focus() end,
        },
      },
    },
  },
  keys = {
    { '<M-\\>',       function() require('sidekick.cli').focus() end, mode = { 'n', 'x' },               desc = 'Sidekick: focus CLI' },
    { '<M-\\>',       [[<C-\><C-n><C-w>p]],                            mode = 't',                       desc = 'Sidekick: back to editor' },
    { '<leader>ska', function() require('sidekick.cli').toggle() end,                                    desc = 'Sidekick: toggle CLI' },
    { '<leader>skc', function() require('sidekick.cli').toggle({ name = 'claude', focus = true }) end,   desc = 'Sidekick: toggle Claude' },
    { '<leader>skg', function() require('sidekick.cli').toggle({ name = 'gemini', focus = true }) end,   desc = 'Sidekick: toggle Gemini' },
    { '<leader>sko', function() require('sidekick.cli').toggle({ name = 'codex', focus = true }) end,    desc = 'Sidekick: toggle Codex' },
    { '<leader>sks', function() require('sidekick.cli').select() end,                                    desc = 'Sidekick: select CLI tool' },
    { '<leader>skd', function() require('sidekick.cli').close() end,                                     desc = 'Sidekick: detach session' },
    { '<leader>skt', function() require('sidekick.cli').send({ msg = '{this}' }) end, mode = { 'n', 'x' }, desc = 'Sidekick: send this' },
    { '<leader>skf', function() require('sidekick.cli').send({ msg = '{file}' }) end,                    desc = 'Sidekick: send file' },
    { '<leader>skv', function() require('sidekick.cli').send({ msg = '{selection}' }) end, mode = 'x',   desc = 'Sidekick: send visual selection' },
    { '<leader>skp', function() require('sidekick.cli').prompt() end, mode = { 'n', 'x' },               desc = 'Sidekick: select prompt' },
  },
}
