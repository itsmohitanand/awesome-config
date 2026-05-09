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
          ['<C-\\>'] = function() require('sidekick.cli').focus() end,
        },
      },
    },
  },
  keys = {
    { '<leader>aia', function() require('sidekick.cli').toggle() end,                                    desc = 'Sidekick: toggle CLI' },
    { '<leader>aic', function() require('sidekick.cli').toggle({ name = 'claude', focus = true }) end,   desc = 'Sidekick: toggle Claude' },
    { '<leader>aig', function() require('sidekick.cli').toggle({ name = 'gemini', focus = true }) end,   desc = 'Sidekick: toggle Gemini' },
    { '<leader>ais', function() require('sidekick.cli').select() end,                                    desc = 'Sidekick: select CLI tool' },
    { '<leader>aid', function() require('sidekick.cli').close() end,                                     desc = 'Sidekick: detach session' },
    { '<leader>ait', function() require('sidekick.cli').send({ msg = '{this}' }) end, mode = { 'n', 'x' }, desc = 'Sidekick: send this' },
    { '<leader>aif', function() require('sidekick.cli').send({ msg = '{file}' }) end,                    desc = 'Sidekick: send file' },
    { '<leader>aiv', function() require('sidekick.cli').send({ msg = '{selection}' }) end, mode = 'x',   desc = 'Sidekick: send visual selection' },
    { '<leader>aip', function() require('sidekick.cli').prompt() end, mode = { 'n', 'x' },               desc = 'Sidekick: select prompt' },
  },
}
