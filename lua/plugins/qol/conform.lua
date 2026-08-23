local function has_config_file(bufnr, configs)
  local root = vim.fs.root(bufnr, configs)
  return root ~= nil
end

return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>cf',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = 'Format',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local ft = vim.bo[bufnr].filetype

        -- Only format C/C++ if .clang-format exists
        if ft == 'c' or ft == 'cpp' then
          if not has_config_file(bufnr, { '.clang-format', '.clang-format.yaml', '.clang-format.yml' }) then
            return nil
          end
        end

        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        python = { 'ruff_format', 'ruff_organize_imports' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
