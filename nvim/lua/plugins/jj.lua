return {
  'NicolasGB/jj.nvim',
  version = '*',
  dependencies = { 'folke/which-key.nvim' },
  config = function()
    require('jj').setup({
      picker = { snacks = {} },
      diff = { backend = 'native' },
    })
    require('which-key').add({ { '<leader>j', group = 'Jujutsu' } })
  end,
  keys = {
    { '<leader>jl', function() require('jj.cmd').log() end,              desc = 'jj log' },
    { '<leader>js', function() require('jj.cmd').status() end,           desc = 'jj status' },
    { '<leader>jd', function() require('jj.diff').diff_current() end,    desc = 'jj diff' },
    { '<leader>jn', function() require('jj.cmd').new() end,              desc = 'jj new' },
    { '<leader>je', function() require('jj.cmd').describe() end,         desc = 'jj describe' },
    { '<leader>ju', function() require('jj.cmd').undo() end,             desc = 'jj undo' },
    { '<leader>jf', function() require('jj.cmd').fetch() end,            desc = 'jj fetch' },
    { '<leader>jp', function() require('jj.cmd').push() end,             desc = 'jj push' },
    { '<leader>jb', function() require('jj.annotate').line() end,        desc = 'jj blame line' },
    { '<leader>jh', function() require('jj.picker').file_history() end,  desc = 'jj file history' },
  },
}
