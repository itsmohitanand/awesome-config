return {
  {
    'williamboman/mason.nvim',
    config = function()
      require('mason').setup()
    end
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
    end
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- Install LSP servers via Mason
      require('mason-lspconfig').setup({
        ensure_installed = { 'clangd', 'lua_ls', 'basedpyright', 'stylua' },
      })

      -- Modern nvim 0.11+ LSP configuration using vim.lsp.config

      -- Lua LSP
      vim.lsp.config('lua_ls', {
        cmd = { vim.fn.stdpath('data') .. '/mason/bin/lua-language-server' },
        filetypes = { 'lua' },
        root_markers = { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' },
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { 'vim' } },
            workspace = {
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })

      -- C/C++ LSP
      vim.lsp.config('clangd', {
        cmd = { vim.fn.stdpath('data') .. '/mason/bin/clangd' },
        filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
        root_markers = { '.clangd', '.clang-tidy', '.clang-format', 'compile_commands.json', 'compile_flags.txt', 'configure.ac', '.git' },
        capabilities = capabilities,
      })

      -- Python type checking (basedpyright)
      vim.lsp.config('basedpyright', {
        cmd = { vim.fn.stdpath('data') .. '/mason/bin/basedpyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
        capabilities = capabilities,
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "basic", -- "off" | "basic" | "standard" | "strict"
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      })

      -- Python linting (ruff from virtualenv)
      if vim.fn.executable('ruff') == 1 then
        vim.lsp.config('ruff', {
          cmd = { 'ruff', 'server' },
          filetypes = { 'python' },
          root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
          capabilities = capabilities,
        })
        vim.lsp.enable('ruff')
      end

      -- Enable LSP servers
      vim.lsp.enable({ 'lua_ls', 'clangd', 'basedpyright' })

      -- LSP keybindings (using LspAttach autocmd - the modern way)
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local bufnr = args.buf
          local bufmap = function(mode, lhs, rhs, opts)
            local options = { noremap = true, silent = true, buffer = bufnr }
            if opts then
              options = vim.tbl_extend('force', options, opts)
            end
            vim.keymap.set(mode, lhs, rhs, options)
          end

          bufmap('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to Definition' })
          bufmap('n', 'K', vim.lsp.buf.hover, { desc = 'Show Hover Docs' })
          bufmap('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename Symbol' })
          bufmap('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code Action' })
          bufmap('n', 'gr', vim.lsp.buf.references, { desc = 'Show References' })
          bufmap('i', '<C-k>', vim.lsp.buf.signature_help, { desc = 'Show Signature Help' })
        end,
      })
    end
  },
}
