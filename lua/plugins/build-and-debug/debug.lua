-- Debugging: nvim-dap + UI + Mason Integration
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
      -- 2. Define Adapters (Local codelldb is auto-defined by Mason)
      --    Define Native GDB on Host for Remote Astra Debugging
      -------------------------------------------------------------------------
      dap.adapters.gdb = {
        type = 'executable',
        command = 'gdb',
        args = {
          '--quiet',
          '--interpreter=dap',
          '--nh', -- Do not read ~/.gdbinit (prevents noisy terminal prints from corrupting DAP JSON)
        },
      }

      -------------------------------------------------------------------------
      -- 3. Native Background SSH Tunnel Management (Asynchronous & Non-blocking)
      -------------------------------------------------------------------------
      local tunnel_job_id = nil

      local function cleanup_tunnel()
        if tunnel_job_id then
          vim.fn.jobstop(tunnel_job_id)
          tunnel_job_id = nil
          vim.notify('Astra SSH Tunnel closed.', vim.log.levels.INFO)
        end
      end

      -- Attach listener: Spawns the tunnel *before* connecting
      dap.listeners.before.attach.astra_tunnel = function(session, config)
        -- Only trigger this for our Astra config!
        if config.name ~= 'Astra: Attach to Running Fly-DM' then
          return
        end

        cleanup_tunnel() -- Clean up any stale sessions

        vim.notify('Launching Astra SSH Tunnel & remote gdbserver...', vim.log.levels.INFO)

        tunnel_job_id = vim.fn.jobstart({
          'ssh',
          '-4',
          '-t',
          '-L',
          '1234:127.0.0.1:1234',
          'alex@localhost',
          '-p',
          '22220',
          'sudo gdbserver localhost:1234 --attach $(pgrep fly-dm)',
        }, {
          on_stdout = function(_, data)
            local output = table.concat(data, '\n')
            if output:match '[pP]assword' then
              vim.notify('Astra Tunnel: Password prompt detected! Set up NOPASSWD or SSH keys if it hangs.', vim.log.levels.WARN)
            end
          end,
          on_stderr = function(_, data)
            local err = table.concat(data, '\n')
            if err ~= '' and not err:match 'Connection to .* closed' then
              print('Tunnel Error: ' .. err)
            end
          end,
        })

        -- Give gdbserver/SSH tunnel a split-second to bind before nvim-dap tries to connect
        vim.wait(300)
      end

      -- Auto-cleanup on any termination/disconnect state
      dap.listeners.after.event_terminated.astra_tunnel = cleanup_tunnel
      dap.listeners.after.disconnect.astra_tunnel = cleanup_tunnel

      -------------------------------------------------------------------------
      -- 4. Unified C/C++ configurations
      -------------------------------------------------------------------------
      local cpp_configs = {
        -- 💻 Local Debugging (runs QBS build locally first via Overseer using CodeLLDB)
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
        {
          name = 'Astra: Attach to Running Fly-DM',
          type = 'gdb',
          request = 'launch',
          program = vim.fn.expand '~/dev/unilogon/build/debug/install-root/flydm-plugin/libfly-dm_greet_rtlogon.so',
          cwd = '${workspaceFolder}',

          initCommands = {
            -- Map the path
            'set substitute-path /home/alex/dev/unilogon ' .. vim.fn.expand '~/dev/unilogon',
          },

          targetCommands = {
            -- 1. Connect
            'target remote localhost:1234',
            -- 2. Force GDB to load symbols for the shared library
            'sharedlibrary libfly-dm_greet_rtlogon.so',
            -- 3. Force a re-read of the symbol table
            'info sharedlibrary',
          },
        },
      }

      -- 5. Bind the configurations to both C and C++ filetypes
      dap.configurations.cpp = cpp_configs
      dap.configurations.c = cpp_configs
    end,
  },
}
