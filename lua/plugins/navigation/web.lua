return {
  -- We use "dir" just to satisfy the spec for a local "plugin"
  -- but we use 'config' to actually run the code.
  'url-handler',
  dir = vim.fn.stdpath 'config',
  config = function()
    local function open_url_or_gf()
      local path = vim.fn.expand '<cfile>'

      if path:match 'https?://' or path:match 'www%.' then
        local cmd
        if vim.fn.has 'mac' == 1 then
          cmd = { 'open', path }
        elseif vim.fn.has 'unix' == 1 then
          cmd = { 'xdg-open', path }
        else
          cmd = { 'cmd.exe', '/c', 'start', '', path }
        end
        vim.fn.jobstart(cmd)
      else
        -- Use pcall to prevent the error message from breaking the UI
        -- if the file under cursor simply doesn't exist.
        pcall(vim.cmd, 'normal! gf')
      end
    end

    vim.keymap.set('n', 'gf', open_url_or_gf, {
      desc = 'Open URL or File',
      silent = true,
    })
  end,
}
