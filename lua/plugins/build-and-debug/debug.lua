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

      -- Disable blink.cmp in the DAP REPL: blink force-enables itself for the
      -- `dap-repl` filetype by default, which fights with nvim-dap's own
      -- <up>/<down> history navigation and pops up noisy completions while
      -- typing commands like `bt`. `vim.b.completion = false` is blink's own
      -- supported per-buffer opt-out, checked before its dap-repl exception.
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'dap-repl',
        callback = function(args)
          vim.b[args.buf].completion = false
        end,
      })

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

      -- Suppress a harmless console message that gdb's DAP mode prints once
      -- per session: setBreakpoints is processed before the deferred
      -- attach/launch loads the symbol table, so gdb reports the source file
      -- as missing and marks the breakpoint pending. It resolves correctly
      -- once the symbol table loads a moment later; this is just noise.
      dap.defaults.gdb.on_output = function(session, body)
        if body.category ~= 'telemetry' and (body.output:match '^❌️ No source file named ' or body.output:match '^Breakpoint %d+ %(%-source .* %-line %d+%) pending%.') then
          return
        end
        require('dap.repl').append(body.output, '$', { newline = false })
      end

      -------------------------------------------------------------------------
      -- 3. VM Attach: local gdb connects to a remote gdbserver over SSH
      --
      --    Flow:
      --      1. Prompt for the remote PID (only manual input required).
      --      2. Resolve the remote binary path via /proc/<pid>/cmdline (no sudo needed).
      --      3. Locate the matching local binary (same build, same debug info) by
      --         basename under build/*/install-root/**.
      --      4. Launch `ssh -tt vm sudo -n gdbserver --once 0.0.0.0:1234 --attach <pid>`
      --         and wait for it to report readiness (NOT a TCP-connect poll: QEMU's
      --         hostfwd accepts the handshake even when nothing listens yet, so a
      --         plain connect check is a false-positive trap).
      --      5. Only then let gdb's DAP `attach` proceed with `target=localhost:1234`
      --         and `program=<resolved local path>`.
      --
      --    Requires on the VM: `alex ALL=(root) NOPASSWD: /usr/bin/gdbserver` in
      --    /etc/sudoers.d/.
      -------------------------------------------------------------------------
      local ssh_host = 'vm'
      local gdbserver_port = 1234
      local gdbserver_job_id = nil

      local function stop_remote_gdbserver()
        if gdbserver_job_id then
          vim.fn.jobstop(gdbserver_job_id)
          gdbserver_job_id = nil
        end
      end

      -- Resolve the absolute path of the binary backing PID on the VM.
      -- Reads /proc/<pid>/cmdline directly: world-readable, no sudo required.
      local function remote_exe_path(pid)
        local cmd = { 'ssh', ssh_host, "tr '\\0' '\\n' < /proc/" .. pid .. '/cmdline | head -1' }
        local out = vim.fn.system(cmd)
        if vim.v.shell_error ~= 0 or out == '' then
          return nil
        end
        return vim.trim(out)
      end

      -- Find the local binary matching `basename`, restricted to build install
      -- trees so we get the deployed artifact with matching debug info.
      local function local_binary_path(remote_path)
        local basename = vim.fn.fnamemodify(remote_path, ':t')
        local pattern = vim.fn.getcwd() .. '/build/*/install-root/**/' .. basename
        local matches = vim.fn.glob(pattern, false, true)
        for _, path in ipairs(matches) do
          if vim.fn.filereadable(path) == 1 then
            return path
          end
        end
        return nil
      end

      -- Starts gdbserver on the VM attached to `pid`, and blocks (via vim.wait)
      -- until it reports it is listening, or until `timeout_ms` elapses.
      -- Returns true on success.
      local function start_remote_gdbserver(pid, timeout_ms)
        stop_remote_gdbserver()

        local ready = false
        local failed_reason = nil

        gdbserver_job_id = vim.fn.jobstart({
          'ssh',
          '-tt',
          ssh_host,
          'sudo',
          '-n',
          'gdbserver',
          '--once',
          string.format('0.0.0.0:%d', gdbserver_port),
          '--attach',
          tostring(pid),
        }, {
          pty = false,
          on_stdout = function(_, data)
            for _, line in ipairs(data or {}) do
              if line:match 'Listening on port' then
                ready = true
              elseif line:match 'interactive authentication is required' then
                failed_reason = 'sudo requires a password on the VM (check /etc/sudoers.d/ for gdbserver NOPASSWD rule)'
              elseif line:match 'No such process' then
                failed_reason = 'remote PID ' .. pid .. ' does not exist'
              end
            end
          end,
          on_stderr = function(_, data)
            for _, line in ipairs(data or {}) do
              if line ~= '' and not failed_reason then
                failed_reason = line
              end
            end
          end,
          on_exit = function(_, code)
            if not ready and code ~= 0 and not failed_reason then
              failed_reason = 'gdbserver exited early (code ' .. code .. ')'
            end
            gdbserver_job_id = nil
          end,
        })

        vim.wait(timeout_ms, function()
          return ready or failed_reason ~= nil
        end, 50)

        if failed_reason then
          vim.notify('VM gdbserver failed: ' .. failed_reason, vim.log.levels.ERROR)
          stop_remote_gdbserver()
          return false
        end

        if not ready then
          vim.notify('Timed out waiting for gdbserver on the VM', vim.log.levels.ERROR)
          stop_remote_gdbserver()
          return false
        end

        return true
      end

      -- Runs the full prompt -> resolve -> launch sequence.
      -- Returns the resolved local program path, or dap.ABORT on failure.
      local function prepare_vm_attach()
        local pid = vim.fn.input 'Remote PID to attach: '
        if pid == '' or tonumber(pid) == nil then
          vim.notify('VM attach aborted: no valid PID given', vim.log.levels.WARN)
          return dap.ABORT
        end

        local remote_path = remote_exe_path(pid)
        if not remote_path then
          vim.notify('Could not resolve executable for remote PID ' .. pid, vim.log.levels.ERROR)
          return dap.ABORT
        end

        local basename = vim.fn.fnamemodify(remote_path, ':t')
        local program = local_binary_path(remote_path)
        if not program then
          vim.notify('Could not find local binary matching `' .. basename .. '` under build/*/install-root', vim.log.levels.ERROR)
          return dap.ABORT
        end

        vim.notify('Starting gdbserver on VM for PID ' .. pid .. ' (' .. basename .. ')...', vim.log.levels.INFO)
        if not start_remote_gdbserver(pid, 5000) then
          return dap.ABORT
        end

        return program
      end

      -- `target` and `program` are both function-valued config fields, and
      -- nvim-dap evaluates config fields via plain `pairs()` iteration, so
      -- their evaluation order is NOT guaranteed. Run the whole prompt ->
      -- resolve -> launch sequence exactly once (memoized) so whichever field
      -- is evaluated first triggers it, and the other reuses the result.
      -- The memoized result is reset via the config table's `__call`
      -- metamethod below, which nvim-dap invokes once per `dap.run()`,
      -- before any field evaluation (see `prepare_config` in dap.lua).
      local vm_attach_result = nil

      local function run_vm_attach_once()
        if vm_attach_result == nil then
          vm_attach_result = prepare_vm_attach()
        end
        return vm_attach_result
      end

      local function vm_attach_target()
        local program = run_vm_attach_once()
        if program == dap.ABORT then
          return dap.ABORT
        end
        return string.format('localhost:%d', gdbserver_port)
      end

      local function vm_attach_program()
        return run_vm_attach_once()
      end

      local function reset_vm_attach_cache(config)
        vm_attach_result = nil
        return config
      end

      -- Cleanup: stop the remote gdbserver job when the session ends, in case
      -- it is somehow still running (normally --once + gdb detach/disconnect
      -- already makes gdbserver exit on its own).
      dap.listeners.after.event_terminated['vm_attach_cleanup'] = stop_remote_gdbserver
      dap.listeners.after.disconnect['vm_attach_cleanup'] = stop_remote_gdbserver

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
        -- Attach to a process running on the VM.
        -- gdb runs locally (on the host) and connects to a gdbserver started
        -- on the VM over SSH. Only the PID needs to be entered manually; the
        -- matching local binary (with debug info) is resolved automatically.
        setmetatable({
          name = 'VM: Attach to Remote PID',
          type = 'gdb',
          request = 'attach',
          target = vm_attach_target,
          program = vm_attach_program,
        }, { __call = reset_vm_attach_cache }),
      }

      -- 5. Bind the configurations to both C and C++ filetypes
      dap.configurations.cpp = cpp_configs
      dap.configurations.c = cpp_configs
    end,
  },
}