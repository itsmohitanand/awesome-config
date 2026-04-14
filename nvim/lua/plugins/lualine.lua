return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VeryLazy',
  config = function()

    -- Active LSP clients for this buffer (e.g. "clangd  ruff")
    local function lsp_clients()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if #clients == 0 then return '' end
      local names = {}
      for _, c in ipairs(clients) do
        table.insert(names, c.name)
      end
      return '󰒋 ' .. table.concat(names, '  ')
    end

    -- Built-in 0.12 LSP progress (shows clangd indexing, ruff scanning, etc.)
    local function lsp_progress()
      local ok, s = pcall(vim.lsp.status)
      return (ok and s ~= '') and ('󱑤 ' .. s) or ''
    end

    -- Python: active virtualenv / conda env
    local function python_env()
      if vim.bo.filetype ~= 'python' then return '' end
      local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_DEFAULT_ENV
      if not venv then return '' end
      return ' ' .. vim.fn.fnamemodify(venv, ':t')
    end

    -- Neorg: active workspace name
    local function neorg_workspace()
      if vim.bo.filetype ~= 'norg' then return '' end
      local ok, neorg = pcall(require, 'neorg')
      if not ok then return '' end
      local dirman = neorg.modules.get_module('core.dirman')
      if not dirman then return '' end
      local ws = dirman.get_current_workspace()
      return ws and ('󱌚 ' .. ws[1]) or ''
    end

    -- Neorg: live word count
    local function neorg_words()
      if vim.bo.filetype ~= 'norg' then return '' end
      return '󰈭 ' .. vim.fn.wordcount().words .. 'w'
    end

    require('lualine').setup({
      options = {
        theme                = 'auto',
        globalstatus         = true,   -- single bar across all splits
        section_separators    = { left = '', right = '' },
        component_separators = { left = '│', right = '│' },
      },

      sections = {
        lualine_a = { 'mode' },

        lualine_b = {
          'branch',
          {
            'diff',
            symbols = { added = ' ', modified = ' ', removed = ' ' },
          },
          {
            'diagnostics',
            symbols = { error = ' ', warn = ' ', hint = ' ', info = ' ' },
          },
        },

        lualine_c = {
          { 'filename', path = 1, symbols = { modified = '●', readonly = '', unnamed = '[No Name]' } },
          python_env,
          neorg_workspace,
        },

        lualine_x = {
          lsp_progress,   -- clangd indexing / ruff scanning etc.
          lsp_clients,
          neorg_words,
          -- encoding / format only shown when non-standard
          { 'encoding',   cond = function() return vim.bo.fileencoding ~= '' and vim.bo.fileencoding ~= 'utf-8' end },
          { 'fileformat', cond = function() return vim.bo.fileformat ~= 'unix' end },
          'filetype',
        },

        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },

      inactive_sections = {
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'location' },
      },
    })
  end,
}
