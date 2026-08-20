-- NOTE: Plugins can also be configured to run Lua code when they are loaded.
--
-- This is often very useful to both group configuration, as well as handle
-- lazy loading plugins that don't need to be loaded immediately at startup.
--
-- For example, in the following configuration, we use:
--  event = 'VimEnter'
--
-- which loads which-key before all the UI elements are loaded. Events can be
-- normal autocommands events (`:help autocmd-events`).
--
-- Then, because we use the `opts` key (recommended), the configuration runs
-- after the plugin has been loaded as `require(MODULE).setup(opts)`.

local function preset_icon(category, keys, description)
  local desc = (description or ''):lower()

  if desc:find 'run program' then
    return { icon = ' ', color = 'green' }
  elseif desc:find 'indent' then
    return { icon = '󰉶 ', color = 'yellow' }
  elseif desc:find 'delete' then
    return { icon = '󰆴 ', color = 'red' }
  elseif desc:find 'close' or desc:find 'quit' then
    return { icon = '󰅖 ', color = 'red' }
  elseif desc:find 'open' then
    return { icon = '󰐕 ', color = 'green' }
  elseif desc:find 'spell' or desc:find 'word as bad' then
    return { icon = '󰓆 ', color = 'yellow' }
  elseif desc:find 'search' or desc:find 'results' then
    return { icon = ' ', color = 'green' }
  elseif desc:find 'file' or desc:find 'buffer' then
    return { icon = '󰈞 ', color = 'cyan' }
  elseif desc:find 'tab' then
    return { icon = '󰓩 ', color = 'purple' }
  elseif desc:find 'visual' or desc:find 'select' then
    return { icon = '󰒅 ', color = 'purple' }
  elseif desc:find 'uppercase' or desc:find 'lowercase' or desc:find 'case' then
    return { icon = '󰬴 ', color = 'purple' }
  elseif desc:find 'format' then
    return { icon = ' ', color = 'cyan' }
  elseif desc:find 'replace' or desc:find 'change' then
    return { icon = '󰛔 ', color = 'orange' }
  elseif desc:find 'insert' then
    return { icon = '󰏫 ', color = 'yellow' }
  elseif desc:find 'yank' then
    return { icon = '󰆏 ', color = 'green' }
  elseif desc:find 'fold' then
    return { icon = '󰘖 ', color = 'blue' }
  elseif desc:find 'window' or desc:find 'split' or desc:find 'height' or desc:find 'width' or desc:find 'high and wide' then
    return { icon = ' ', color = 'blue' }
  elseif desc:find 'down' then
    return { icon = ' ', color = 'azure' }
  elseif desc:find 'up' then
    return { icon = ' ', color = 'cyan' }
  elseif desc:find 'right' or desc:find 'next' or desc:find 'newer' or desc:find 'last' or desc:find 'end' then
    return { icon = ' ', color = 'azure' }
  elseif desc:find 'left' or desc:find 'prev' or desc:find 'older' or desc:find 'first' or desc:find 'start' or desc:find 'home' then
    return { icon = ' ', color = 'cyan' }
  elseif desc:find 'line' or desc:find 'screen' or desc:find 'cursor' or desc:find 'middle' or desc:find 'center' then
    return { icon = '󰘤 ', color = 'azure' }
  elseif desc:find 'word' then
    return { icon = '󰱼 ', color = 'cyan' }
  elseif desc:find 'method' then
    return { icon = '󰆧 ', color = 'purple' }
  elseif desc:find 'string' then
    return { icon = '󰅳 ', color = 'yellow' }
  elseif desc:find 'block' or desc:find 'group' or desc:find '%(' or desc:find '%[' or desc:find '{' or desc:find '<' then
    return { icon = '󰅩 ', color = 'blue' }
  elseif desc:find 'paragraph' or desc:find 'sentence' then
    return { icon = '󰈙 ', color = 'green' }
  elseif desc:find 'tag' then
    return { icon = '󰌕 ', color = 'orange' }
  elseif category == 'operators' then
    return { icon = '󰆕 ', color = 'orange' }
  elseif category == 'motions' then
    return { icon = '󰁕 ', color = 'blue' }
  elseif category == 'text_objects' then
    return { icon = keys == 'a' and '󰏪 ' or '󰏫 ', color = 'purple' }
  elseif category == 'windows' then
    return { icon = ' ', color = 'blue' }
  elseif category == 'z' then
    return { icon = '󰘖 ', color = 'blue' }
  elseif category == 'nav' then
    return { icon = keys:sub(1, 1) == '[' and ' ' or ' ', color = 'azure' }
  end

  return { icon = '󰁕 ', color = 'blue' }
end

local function builtin_specs()
  local presets = require 'which-key.plugins.presets'
  local specs = {
    { 'g', group = 'Go to', icon = { icon = '󰁔 ', color = 'blue' } },
    { 'z', group = 'Folds / View', icon = { icon = '󰘖 ', color = 'blue' } },
    { '[', group = 'Previous', icon = { icon = ' ', color = 'cyan' } },
    { ']', group = 'Next', icon = { icon = ' ', color = 'azure' } },
  }

  for _, category in ipairs { 'operators', 'motions', 'text_objects', 'windows', 'z', 'nav', 'g' } do
    local preset = presets[category]
    for _, mapping in ipairs(preset) do
      if mapping[1] then
        specs[#specs + 1] = {
          mapping[1],
          mode = mapping.mode or preset.mode,
          desc = mapping.desc,
          group = mapping.group,
          icon = preset_icon(category, mapping[1], mapping.desc or mapping.group),
        }
      end
    end
  end

  return specs
end

return {
  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = function()
      return {
        -- delay between pressing a key and opening which-key (milliseconds)
        -- this setting is independent of vim.opt.timeoutlen
        delay = function(ctx)
          return ctx.keys:find '^<leader>' and 0 or 300
        end,
        triggers = {
          { '<auto>', mode = 'nixsotc' },
          { 'g', mode = { 'n', 'x' } },
          { 'z', mode = { 'n', 'x' } },
          { '[', mode = { 'n', 'x' } },
          { ']', mode = { 'n', 'x' } },
          { '<c-w>', mode = { 'n', 'x' } },
        },
        defer = function(ctx)
          return ctx.mode == 'V' or ctx.mode == '<C-V>'
        end,
        icons = {
          -- set icon mappings to true if you have a Nerd Font
          mappings = vim.g.have_nerd_font,
          rules = {
            { pattern = 'harpoon', icon = '󱡅 ', color = 'cyan' },
            { pattern = 'overseer', icon = '󰑮 ', color = 'orange' },
            { pattern = 'dap', icon = ' ', color = 'red' },
            { pattern = 'build', icon = ' ', color = 'orange' },
            { pattern = 'run', icon = ' ', color = 'green' },
            { pattern = 'undo', icon = ' ', color = 'yellow' },
            { pattern = '%f[%a]ai', icon = '󰚩 ', color = 'purple' },
          },
          group = '',
          -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
          -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
          keys = vim.g.have_nerd_font and {} or {
            Up = '<Up> ',
            Down = '<Down> ',
            Left = '<Left> ',
            Right = '<Right> ',
            C = '<C-…> ',
            M = '<M-…> ',
            D = '<D-…> ',
            S = '<S-…> ',
            CR = '<CR> ',
            Esc = '<Esc> ',
            ScrollWheelDown = '<ScrollWheelDown> ',
            ScrollWheelUp = '<ScrollWheelUp> ',
            NL = '<NL> ',
            BS = '<BS> ',
            Space = '<Space> ',
            Tab = '<Tab> ',
            F1 = '<F1>',
            F2 = '<F2>',
            F3 = '<F3>',
            F4 = '<F4>',
            F5 = '<F5>',
            F6 = '<F6>',
            F7 = '<F7>',
            F8 = '<F8>',
            F9 = '<F9>',
            F10 = '<F10>',
            F11 = '<F11>',
            F12 = '<F12>',
          },
        },

        -- Document existing key chains
        spec = {
          builtin_specs(),
          { '<leader>c', group = 'Code', icon = { icon = ' ', color = 'orange' }, mode = { 'n', 'x' } },
          { '<leader>d', group = 'Debug / Document', icon = { icon = ' ', color = 'red' } },
          { '<leader>e', icon = { icon = '󰙅 ', color = 'green' } },
          { '<leader>r', group = 'Rename', icon = { icon = '󰑕 ', color = 'cyan' } },
          { '<leader>rn', icon = { icon = '󰑕 ', color = 'cyan' } },
          { '<leader>s', group = 'Search', icon = { icon = ' ', color = 'blue' } },
          { '<leader>sh', icon = { icon = '󰋖 ', color = 'cyan' } },
          { '<leader>sk', icon = { icon = ' ', color = 'purple' } },
          { '<leader>sf', icon = { icon = '󰈞 ', color = 'azure' } },
          { '<leader>ss', icon = { icon = ' ', color = 'blue' } },
          { '<leader>sw', icon = { icon = '󰱼 ', color = 'yellow' } },
          { '<leader>sg', icon = { icon = '󰊄 ', color = 'green' } },
          { '<leader>sd', icon = { icon = '󱖫 ', color = 'red' } },
          { '<leader>sr', icon = { icon = '󰑐 ', color = 'orange' } },
          { '<leader>s.', icon = { icon = '󰋚 ', color = 'yellow' } },
          { '<leader>s/', icon = { icon = '󰈭 ', color = 'green' } },
          { '<leader>sn', icon = { icon = ' ', color = 'green' } },
          { '<leader>q', icon = { icon = '󰒡 ', color = 'red' } },
          { '<leader>/', icon = { icon = '󰈭 ', color = 'green' } },
          { '<leader><leader>', icon = { icon = '󰈔 ', color = 'cyan' } },
          { '<leader>w', group = 'Workspace', icon = { icon = '󰖲 ', color = 'blue' } },
          { '<leader>t', group = 'Toggle', icon = { icon = ' ', color = 'yellow' } },
          { '<leader>h', group = 'Git Hunk', icon = { icon = '󰊢 ', color = 'orange' }, mode = { 'n', 'v' } },
          { '<leader>i', group = 'AI', icon = { icon = '󰚩 ', color = 'purple' }, mode = { 'n', 'x' } },
          { '<leader>o', group = 'Run / Tasks', icon = { icon = ' ', color = 'red' }, mode = { 'n', 'x' } },
          { '<leader>1', desc = 'Harpoon 1–5', icon = { icon = '󱡅 ', color = 'cyan' } },
          { '<leader>2', hidden = true },
          { '<leader>3', hidden = true },
          { '<leader>4', hidden = true },
          { '<leader>5', hidden = true },
        },
      }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
