-- Debugging: nvim-dap + UI + Mason Integration
local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:match '@?(.*[/\\])', ':h')

return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
      'jay-babu/mason-nvim-dap.nvim',
      'stevearc/overseer.nvim',
    },
    keys = {
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'DAP: Toggle Breakpoint',
      },
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = 'DAP: Start / Continue',
      },
      {
        '<leader>do',
        function()
          require('dap').step_over()
        end,
        desc = 'DAP: Step Over',
      },
      {
        '<leader>di',
        function()
          require('dap').step_into()
        end,
        desc = 'DAP: Step Into',
      },
      {
        '<leader>du',
        function()
          require('dap').step_out()
        end,
        desc = 'DAP: Step Out',
      },
      {
        '<leader>dr',
        function()
          require('dap').restart()
        end,
        desc = 'DAP: Restart Session',
      },
      {
        '<leader>dq',
        function()
          require('dap').terminate()
        end,
        desc = 'DAP: Quit Debugger',
      },
      {
        '<leader>dv',
        function()
          require('dapui').toggle()
        end,
        desc = 'DAP UI: Toggle Windows',
      },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      -- 1. Setup Mason-DAP (Only manage codelldb now!)
      require('mason-nvim-dap').setup {
        automatic_installation = true,
        ensure_installed = { 'codelldb' },
        handlers = {
          function(config)
            require('mason-nvim-dap').default_setup(config)
          end,
        },
      }

      dapui.setup()

      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close()
      end

      -------------------------------------------------------------------------
      -- 2. Define Adapters
      -------------------------------------------------------------------------
      dap.adapters.gdb = {
        type = 'executable',
        command = 'gdb',
        args = {
          '--quiet',
          '--interpreter=dap',
          '--nh',
        },
      }

      -- Remote SSH gdb: runs gdb on the remote host via SSH
      -- GDB itself attaches to the remote process by PID, no gdbserver needed
      dap.adapters.ssh_gdb = {
        type = 'executable',
        command = plugin_dir .. '/ssh-gdb-wrapper.sh',
        args = {
          '--nx', -- No .gdbinit files at all
          '-nh', -- Do not read ~/.gdbinit
        },
      }

      -------------------------------------------------------------------------
      -- 3. Remote SSH gdb listener
      -------------------------------------------------------------------------
      dap.listeners.before.attach.ssh_gdb = function(session, config)
        if config.adapter ~= 'ssh_gdb' then
          return
        end

        vim.notify('Attaching to remote PID ' .. config.pid .. '...', vim.log.levels.INFO)
      end

      -------------------------------------------------------------------------
      -- 4. Unified C/C++ configurations
      -------------------------------------------------------------------------
      local cpp_configs = {
        -- Local Debugging (runs QBS build locally first via Overseer using CodeLLDB)
        {
          name = 'Local: Debug with build',
          type = 'codelldb',
          request = 'launch',
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/build/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          preLaunchTask = 'build',
        },
        -- Debug a process on the remote SSH host
        -- GDB runs on the remote, attaches by PID, loads symbols from remote binary
        {
          name = 'SSH: Attach to Remote PID',
          type = 'ssh_gdb',
          request = 'launch',
          pid = function()
            return tonumber(vim.fn.input('Remote PID to attach: ')) or 0
          end,
          cwd = '/',
        },
      }

      -- 5. Bind the configurations to both C and C++ filetypes
      dap.configurations.cpp = cpp_configs
      dap.configurations.c = cpp_configs
    end,
  },
}