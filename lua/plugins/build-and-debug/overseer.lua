return {
  {
    'stevearc/overseer.nvim',

    -- Keymaps
    keys = {
      { '<leader>ob', '<cmd>OverseerRun build<CR>', desc = 'Overseer Build Project' },
      {
        '<leader>or',
        function()
          require('overseer').run_task { name = 'run' }
        end,
        desc = 'Overseer Run Project',
      },
      { '<leader>ot', '<cmd>OverseerToggle<CR>', desc = 'Overseer Toggle Task Panel' },
    },

    config = function()
      local ok, overseer = pcall(require, 'overseer')
      if not ok then
        return
      end

      -- Global Overseer setup
      overseer.setup {
        dap = true, -- Enables DAP integration (essential for preLaunchTask mapping)
        templates = { 'builtin' },
        strategy_defaults = {
          terminal = {
            border = 'rounded',
            width = 80,
            height = 20,
            winblend = 10,
            relative = 'editor',
            row = math.floor(vim.o.lines / 4),
            col = math.floor(vim.o.columns / 4),
          },
        },
        task_list = {
          open = 'quickfix', -- Keeps task status lists bound to Quickfix
          float = {
            border = 'rounded',
            width = 80,
            height = 20,
            winblend = 10,
            relative = 'editor',
            row = math.floor(vim.o.lines / 4),
            col = math.floor(vim.o.columns / 4),
          },
        },
      }

      -- Dynamic Host CPU Detection

      local function get_nproc()
        local core_ok, cores = pcall(function()
          return vim.loop.cpu_info() and #vim.loop.cpu_info() or 1
        end)
        return core_ok and cores or 1
      end

      -- Detect build system
      local function detect_build_system()
        if #vim.fn.glob '*.qbs' > 0 then
          return 'qbs'
        end
        if vim.fn.filereadable 'Makefile' == 1 then
          return 'make'
        end
        if vim.fn.filereadable 'CMakeLists.txt' == 1 then
          return 'cmake'
        end
        if vim.fn.filereadable 'Cargo.toml' == 1 then
          return 'cargo'
        end
        if vim.fn.filereadable 'go.mod' == 1 then
          return 'go'
        end
        return nil
      end

      local function detect_build_command()
        local sys = detect_build_system()
        if sys == 'qbs' then
          return { 'qbs', 'build', 'config:debug' }
        end
        if sys == 'make' then
          return { 'make', '-j' .. get_nproc() }
        end
        if sys == 'cmake' then
          return { 'cmake', '--build', 'build' }
        end
        if sys == 'cargo' then
          return { 'cargo', 'build' }
        end
        if sys == 'go' then
          return { 'go', 'build', '.' }
        end
        return { 'echo', 'No build system detected' }
      end

      local function detect_run_command()
        local sys = detect_build_system()
        if sys == 'qbs' then
          return { 'qbs', 'run' }
        end
        if sys == 'make' then
          return vim.fn.filereadable './main' == 1 and { './main' } or { 'make', 'run' }
        elseif sys == 'cmake' then
          return { './build/main' }
        elseif sys == 'cargo' then
          return { 'cargo', 'run' }
        elseif sys == 'go' then
          return { 'go', 'run', 'cmd/app/main.go' }
        end
        return { 'echo', 'No runnable target detected' }
      end

      -- Templates
      overseer.register_template {
        name = 'build',
        builder = function()
          return { cmd = detect_build_command(), use_pty = false }
        end,
        components = { 'default', 'on_output_quickfix', 'on_result_diagnostics' },
      }

      overseer.register_template {
        name = 'run',
        builder = function()
          return { cmd = detect_run_command(), use_pty = false }
        end,
        components = { 'default', 'on_output_quickfix', 'on_result_diagnostics' },
      }

      local function run_project()
        overseer.run_template { name = 'run' }
      end

      -- Notifications
      vim.api.nvim_create_autocmd('User', {
        pattern = 'OverseerTaskStarted',
        callback = function()
          vim.notify('🔧 Task started...', vim.log.levels.INFO)
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        pattern = 'OverseerTaskCompleted',
        callback = function()
          vim.notify('✅ Task finished', vim.log.levels.INFO)
        end,
      })
    end,
  },
}
