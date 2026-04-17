return {
  'yetone/avante.nvim',
  event  = 'VeryLazy',
  version = false,
  build  = 'make',
  opts = {
    provider = 'codex',
    acp_providers = {
      ['codex'] = {
        command = 'npx',
        args    = { '@zed-industries/codex-acp' },
        env     = {
          NODE_NO_WARNINGS = '1',
          OPENAI_API_KEY   = os.getenv('AVANTE_OPENAI_API_KEY'),
        },
      },
    },
    mappings = {
      ask     = '<leader>ava',
      edit    = '<leader>ave',
      refresh = '<leader>avr',
      focus   = '<leader>avf',
      toggle  = { default = '<leader>avt' },
      submit  = { normal = '<CR>', insert = '<CR>' },
    },
  },
  keys = {
    { '<leader>avp', '<cmd>AvanteSwitchProvider<cr>', desc = 'Switch provider' },
  },
  config = function(_, opts)
    require('avante').setup(opts)
    -- Sidebar bg matches Normal so there's no purple/grey tint
    vim.api.nvim_set_hl(0, 'AvanteSidebarNormal', { link = 'Normal' })
    -- Dark diff colours tuned to poimandres palette
    vim.api.nvim_set_hl(0, 'DiffAdd',    { bg = '#1a3320' })
    vim.api.nvim_set_hl(0, 'DiffDelete', { bg = '#3d1a1a' })
    vim.api.nvim_set_hl(0, 'DiffChange', { bg = '#1a2840' })
    vim.api.nvim_set_hl(0, 'DiffText',   { bg = '#2a4060', bold = true })
    -- Avante's "to be deleted" default is light pink — replace with dark red
    vim.api.nvim_set_hl(0, 'AvanteToBeDeleted',                 { bg = '#3d1a1a', strikethrough = true })
    vim.api.nvim_set_hl(0, 'AvanteToBeDeletedWOStrikethrough',  { bg = '#3d1a1a' })
  end,
  dependencies = {
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'echasnovski/mini.icons',
    {
      'HakonHarnes/img-clip.nvim',
      event = 'VeryLazy',
      opts  = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name  = false,
          drag_and_drop         = { insert_mode = true },
        },
      },
    },
  },
}
