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
      ensure_installed = { "codelldb" },
      handlers = {},
    })

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
  end,
}