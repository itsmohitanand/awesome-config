-- ~/.config/nvim/lua/plugins/dap.lua

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'jay-babu/mason-nvim-dap.nvim',
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    dapui.setup()

    require("mason-nvim-dap").setup({
      ensure_installed = { "codelldb", "python" },
      handlers = {},
    })

    dap.adapters.python = function(cb)
      local venv = vim.env.VIRTUAL_ENV or vim.env.UV_PROJECT_ENVIRONMENT or vim.env.CONDA_PREFIX
      local python = venv and (venv .. "/bin/python") or vim.fn.exepath("python3")
      cb({ type = "executable", command = python, args = { "-m", "debugpy.adapter" } })
    end

    dap.configurations.python = {
      {
        type = "python",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        cwd = function() return vim.fn.getcwd() end,
        env = { PYTHONPATH = function() return vim.fn.getcwd() end },
        pythonPath = function()
          local venv = vim.env.VIRTUAL_ENV or vim.env.UV_PROJECT_ENVIRONMENT or vim.env.CONDA_PREFIX
          if venv then return venv .. "/bin/python" end
          return vim.fn.exepath("python3")
        end,
      },
    }

    vim.fn.sign_define("DapBreakpoint",         { text = "●", texthl = "DiagnosticError",   linehl = "", numhl = "" })
    vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn",    linehl = "", numhl = "" })
    vim.fn.sign_define("DapLogPoint",            { text = "◉", texthl = "DiagnosticInfo",    linehl = "", numhl = "" })
    vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DiagnosticOk",      linehl = "DapStoppedLine", numhl = "" })
    vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DiagnosticError",   linehl = "", numhl = "" })

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end

    local map = vim.keymap.set
    map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
    map("n", "<leader>dc", dap.continue, { desc = "Start/Continue Debugging" })
    map("n", "<leader>di", dap.step_into, { desc = "Step Into" })
    map("n", "<leader>do", dap.step_over, { desc = "Step Over" })
    map("n", "<leader>du", dapui.toggle, { desc = "Toggle Debug UI" })
    map("n", "<leader>dq", function() dap.terminate(); dapui.close() end, { desc = "Quit Debugger" })
  end,
}