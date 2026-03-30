-- ~/.config/nvim/lua/plugins/neorg.lua

return {
  'nvim-neorg/neorg',
  lazy = false,
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'pysan3/pathlib.nvim',
    'nvim-neorg/lua-utils.nvim',
  },
  config = function()
    require('neorg').setup({
      load = {
        -- Core modules
        ['core.defaults'] = {},
        ['core.concealer'] = {
          config = {
            icon_preset = 'varied',
          },
        },
        ['core.dirman'] = {
          config = {
            workspaces = {
              notes = '~/.notes/neorg',
              home = '~/.notes/neorg/home',
              office = '~/.notes/neorg/office',
            },
            default_workspace = 'notes',
          },
        },
        ['core.journal'] = {
          config = {
            workspace = 'notes',
          },
        },
        ['core.keybinds'] = {
          config = {
            default_keybinds = true,
            neorg_leader = '<Leader>o',
          },
        },
        ['core.summary'] = {},
        ['core.export'] = {},
        ['core.export.markdown'] = {},
        -- Metadata and timestamps
        ['core.esupports.metagen'] = {
          config = {
            type = 'auto',
            update_date = true,
          },
        },
        -- Keep Neorg's indent module, but do not add extra list indentation.
        ['core.esupports.indent'] = {},
        -- Presenter mode (for presentations)
        ['core.presenter'] = {
          config = {
            zen_mode = 'zen-mode',
          },
        },
        -- UI Calendar
        ['core.ui.calendar'] = {},
        -- Better link management
        ['core.esupports.hop'] = {},
      },
    })

    -- Additional keybindings
    local map = vim.keymap.set

    -- Workspace navigation
    map('n', '<leader>nrw', '<cmd>Neorg workspace<CR>', { desc = '[N]eo[r]g [W]orkspace' })
    map('n', '<leader>nrn', '<cmd>Neorg workspace notes<CR>', { desc = '[N]eo[r]g workspace [N]otes' })
    map('n', '<leader>nrh', '<cmd>Neorg workspace home<CR>', { desc = '[N]eo[r]g workspace [H]ome' })
    map('n', '<leader>nro', '<cmd>Neorg workspace office<CR>', { desc = '[N]eo[r]g workspace [O]ffice' })

    -- Journal
    map('n', '<leader>nrj', '<cmd>Neorg journal today<CR>', { desc = '[N]eo[r]g [J]ournal today' })
    map('n', '<leader>nry', '<cmd>Neorg journal yesterday<CR>', { desc = '[N]eo[r]g journal [Y]esterday' })
    map('n', '<leader>nrt', '<cmd>Neorg journal tomorrow<CR>', { desc = '[N]eo[r]g journal [T]omorrow' })

    -- Index and TOC
    map('n', '<leader>nri', '<cmd>Neorg index<CR>', { desc = '[N]eo[r]g [I]ndex' })
    map('n', '<leader>nrc', '<cmd>Neorg toc<CR>', { desc = '[N]eo[r]g table of [C]ontents' })

    -- Return to previous location
    map('n', '<leader>nrr', '<cmd>Neorg return<CR>', { desc = '[N]eo[r]g [R]eturn' })

    -- Metadata and timestamps (only work in .norg files)
    map('i', '<M-d>', '<cmd>Neorg keybind norg core.tempus.insert-date<CR>', { desc = 'Insert date' })
    map('i', '<M-t>', '<cmd>Neorg keybind norg core.tempus.insert-date-timestamp<CR>', { desc = 'Insert timestamp' })

    -- Link management
    map('n', '<leader>nrl', '<cmd>Neorg keybind norg core.esupports.hop.hop-link<CR>', { desc = '[N]eo[r]g hop [L]ink' })
  end,
}
