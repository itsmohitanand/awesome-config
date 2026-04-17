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
        virtual_text = {
          prefix = '●',
          source = 'if_many', -- show linter name only when multiple sources disagree
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { source = true }, -- always show source in the floating window
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
        ensure_installed = { 'clangd', 'lua_ls', 'stylua', 'texlab' },
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

      -- Python linting/formatting (ruff)
      if vim.fn.executable('ruff') == 1 then
        vim.lsp.config('ruff', {
          cmd = { 'ruff', 'server' },
          filetypes = { 'python' },
          root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
          capabilities = capabilities,
          init_options = {
            settings = { lint = { enable = true } },
          },
        })
        vim.lsp.enable('ruff')
      end

      -- Python type checking (ty — install with: uv tool install ty)
      if vim.fn.executable('ty') == 1 then
        local ty_capabilities = vim.tbl_deep_extend('force', capabilities, {
          textDocument = {
            diagnostic = {
              dynamicRegistration = false,
            },
          },
        })
        vim.lsp.config('ty', {
          cmd = { 'ty', 'server' },
          filetypes = { 'python' },
          root_markers = { 'pyproject.toml', 'ty.toml', '.git' },
          capabilities = ty_capabilities,
        })
        vim.lsp.enable('ty')
      end

      -- LaTeX LSP (texlab)
      vim.lsp.config('texlab', {
        cmd = { vim.fn.stdpath('data') .. '/mason/bin/texlab' },
        filetypes = { 'tex', 'plaintex', 'bib' },
        root_markers = { '.latexmkrc', '.git', 'Makefile' },
        capabilities = capabilities,
        settings = {
          texlab = {
            auxDirectory = '.aux',
            bibtexFormatter = 'texlab',
            latexFormatter = 'latexindent',
            latexindent = { modifyLineBreaks = false },
            build = {
              executable = 'latexmk',
              args = { '-pdf', '-interaction=nonstopmode', '-synctex=1', '%f' },
              onSave = false,
            },
            chktex = { onOpenAndSave = true },
            forwardSearch = { executable = 'zathura', args = { '--synctex-forward', '%l:1:%f', '%p' } },
          },
        },
      })

      -- Disable pyright / basedpyright (use ruff + ty instead)
      vim.lsp.enable('pyright', false)
      vim.lsp.enable('basedpyright', false)

      -- Enable LSP servers
      vim.lsp.enable({ 'lua_ls', 'clangd', 'texlab' })

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

          bufmap('n', 'gd', function()
            vim.lsp.buf.definition({
              on_list = function(opts)
                local seen = {}
                local unique = {}
                for _, item in ipairs(opts.items) do
                  local key = item.filename .. ':' .. item.lnum .. ':' .. item.col
                  if not seen[key] then
                    seen[key] = true
                    table.insert(unique, item)
                  end
                end
                if #unique == 1 then
                  local item = unique[1]
                  local bufnr = vim.fn.bufadd(item.filename)
                  vim.fn.bufload(bufnr)
                  vim.api.nvim_set_current_buf(bufnr)
                  vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
                else
                  opts.items = unique
                  vim.fn.setqflist({}, ' ', opts)
                  vim.cmd('copen')
                end
              end,
            })
          end, { desc = 'Go to Definition' })
          bufmap('n', 'K', vim.lsp.buf.hover, { desc = 'Show Hover Docs' })
          bufmap('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Rename Symbol' })
          bufmap('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code Action' })
          bufmap('n', 'gr', vim.lsp.buf.references, { desc = 'Show References' })
          bufmap('i', '<C-k>', vim.lsp.buf.signature_help, { desc = 'Show Signature Help' })
        end,
      })
    end
  },
}
