-- Debugging: nvim-dap + UI + Mason Integration
return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'jay-babu/mason-nvim-dap.nvim',
      'stevearc/overseer.nvim', -- integrates with DAP via preLaunchTask
    },
    config = function()
      local dap_ok, dap = pcall(require, 'dap')
      local dapui_ok, dapui = pcall(require, 'dapui')
      if not (dap_ok and dapui_ok) then
        return
      end

      require('mason-nvim-dap').setup {
        automatic_installation = true,
        -- Ensure 'cpptools' is installed alongside 'codelldb' for standard GDB remote debugging
        ensure_installed = { 'codelldb', 'cpptools' },
        handlers = {
          function(config)
            require('mason-nvim-dap').default_handler(config)
          end,
          codelldb = function(config)
            require('mason-nvim-dap').default_handler(config)
          end,
          cpptools = function(config)
            require('mason-nvim-dap').default_handler(config)
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

      -- C++ configurations (supports both local builds & VM-based debugging)
      dap.configurations.cpp = {
        -- 💻 1. Local Debugging (runs QBS build locally first via Overseer)
        {
          name = 'Local: Debug with build',
          type = 'codelldb',
          request = 'launch',
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/build/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          preLaunchTask = 'build', -- 🧠 Triggers your Overseer local build target before launching
        },

        -- 🌐 2. Remote Debugging (Attaches directly to gdbserver running on your QEMU VM)
        {
          name = 'Remote GDB: Attach to VM',
          type = 'cppdbg',
          request = 'launch', -- 'launch' is required by cppdbg to initialize remote target commands
          MIMode = 'gdb',
          miDebuggerServerAddress = function()
            return vim.fn.input('VM IP & Port: ', '192.168.122.1:1234')
          end,
          cwd = '${workspaceFolder}',
          program = function()
            -- Map the local debug symbols binary to the remote VM instructions
            return vim.fn.input('Local path to executable (for symbols): ', vim.fn.getcwd() .. '/build/', 'file')
          end,
          setupCommands = {
            {
              text = '-enable-pretty-printing',
              description = 'Enable GDB pretty printing',
              ignoreFailures = false,
            },
          },
        },
      }

      -- Keymaps (<leader>d…)
      local map = function(lhs, rhs, desc)
        vim.keymap.set('n', lhs, rhs, { desc = 'DAP: ' .. desc })
      end

      map('<leader>db', dap.toggle_breakpoint, 'Toggle Breakpoint')
      map('<leader>dc', dap.continue, 'Start / Continue Debug')
      map('<leader>do', dap.step_over, 'Step Over')
      map('<leader>di', dap.step_into, 'Step Into')
      map('<leader>du', dap.step_out, 'Step Out')
      map('<leader>dr', dap.restart, 'Restart Session')
      map('<leader>dq', dap.terminate, 'Quit Debugger')
    end,
  },
}
