local function dap_continue()
  require("dap").continue()
end
local function dap_step_over()
  require("dap").step_over()
end
local function dap_step_into()
  require("dap").step_into()
end
local function dap_step_out()
  require("dap").step_out()
end

return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<F5>", dap_continue, desc = "Debug Continue" },
      { "<F10>", dap_step_over, desc = "Debug Step Over" },
      { "<F11>", dap_step_into, desc = "Debug Step Into" },
      { "<F12>", dap_step_out, desc = "Debug Step Out" },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      { "<leader>dc", dap_continue, desc = "Debug continue" },
      { "<leader>ds", dap_step_over, desc = "Debug step over" },
      { "<leader>di", dap_step_into, desc = "Debug step into" },
      { "<leader>do", dap_step_out, desc = "Debug step out" },
      {
        "<leader>dr",
        function()
          require("dap").repl.open()
        end,
        desc = "Open debug REPL",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate debug session",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "Run last debug session",
      },
      {
        "<leader>dh",
        function()
          require("dap.ui.widgets").hover()
        end,
        desc = "Debug hover",
      },
      {
        "<leader>dp",
        function()
          require("dap.ui.widgets").preview()
        end,
        desc = "Debug preview",
      },
      {
        "<leader>df",
        function()
          local widgets = require("dap.ui.widgets")
          widgets.centered_float(widgets.frames)
        end,
        desc = "Debug frames",
      },
      {
        "<leader>dv",
        function()
          local widgets = require("dap.ui.widgets")
          widgets.centered_float(widgets.scopes)
        end,
        desc = "Debug variables/scopes",
      },
    },
    config = function()
      local dap = require("dap")
      local filetypes = require("config.filetypes")

      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })

      -- js-debug-adapter is installed via mason-tool-installer. Mason adds its bin dir to PATH,
      -- so the shim is available as a bare command. The ${port} token is resolved by nvim-dap
      -- at session start; the server-type adapter is more robust than executable-type across
      -- upstream vscode-js-debug build changes.
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "js-debug-adapter",
          args = { "${port}" },
        },
      }

      local js_ts_configs = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch Node file",
          program = "${file}",
          cwd = "${workspaceFolder}",
        },
        {
          -- tsx is not universally installed; this config fails fast with a clear
          -- "executable not found" message when tsx is absent, which is intentional.
          type = "pwa-node",
          request = "launch",
          name = "Launch TS (tsx)",
          runtimeExecutable = "tsx",
          args = { "${file}" },
          cwd = "${workspaceFolder}",
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach to process",
          processId = require("dap.utils").pick_process,
          port = 9229,
          cwd = "${workspaceFolder}",
        },
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug Jest test file",
          runtimeExecutable = "node",
          runtimeArgs = { "--experimental-vm-modules" },
          args = { "${workspaceFolder}/node_modules/.bin/jest", "--testPathPattern", "${file}", "--no-coverage" },
          cwd = "${workspaceFolder}",
        },
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug Vitest test file",
          runtimeExecutable = "node",
          args = { "${workspaceFolder}/node_modules/.bin/vitest", "run", "${file}" },
          cwd = "${workspaceFolder}",
        },
      }

      for _, lang in ipairs(filetypes.JS_TS) do
        dap.configurations[lang] = js_ts_configs
      end
    end,
  },
}
