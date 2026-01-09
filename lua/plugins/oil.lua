-- [oil.nvim](https://github.com/stevearc/oil.nvim)
-- oil.nvim is a file manager for Neovim, written in Lua.
-- taken from https://github.com/goolord/alpha-nvim/blob/b6f4129302db197a7249e67a90de3f2b676de13e/lua/alpha.lua#L570
-- stylua: ignore start
local function should_skip_oil()
  -- don't start when opening a file
  if vim.fn.argc() > 0 then return true end

  -- Do not open oil if the current buffer has any lines (something opened explicitly).
  local lines = vim.api.nvim_buf_get_lines(0, 0, 2, false)
  if #lines > 1 or (#lines == 1 and lines[1]:len() > 0) then return true end

  -- Skip when there are several listed buffers.
  for _, buf_id in pairs(vim.api.nvim_list_bufs()) do
    local bufinfo = vim.fn.getbufinfo(buf_id)
    if bufinfo.listed == 1 and #bufinfo.windows > 0 then
      return true
    end
  end

  -- Handle nvim -M
  if not vim.o.modifiable then return true end

  ---@diagnostic disable-next-line: undefined-field
  for _, arg in pairs(vim.v.argv) do
    -- whitelisted arguments (always open)
    if arg == "--startuptime" then return false end

    -- blacklisted arguments (always skip)
    if arg == "-b"
      or arg == "-c" or vim.startswith(arg, "+")
      or arg == "-S"
    then
      return true
    end
  end

  -- base case: don't skip
  return false
end
-- stylua: ignore end

return {
    {
        'stevearc/oil.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons', -- optional, for file icons
        },
        lazy = false, -- load at startup so we can decide to open Oil immediately

        -- Quick access mapping; keep your style
        keys = {
            { '<C-n>', '<cmd>Oil<cr>', desc = 'Open parent directory' },
            -- Also mirror your previous choices (optional):
            {
                '-',
                '<CMD>Oil<CR>',
                desc = 'Open parent directory (current window)',
            },
            {
                '<leader>-',
                function()
                    require('oil').toggle_float()
                end,
                desc = 'Oil (float)',
            },
        },

        init = function()
            -- Keep Ex command alias for muscle memory
            vim.api.nvim_create_user_command('Ex', function()
                require('oil').open()
            end, {
                desc = 'Open the current directory in a new window',
            })
        end,

        config = function()
            require('oil').setup({
                -- General UX
                default_file_explorer = true, -- replace netrw
                restore_win_options = true,
                skip_confirm_for_simple_edits = true, -- avoid prompts for simple ops
                delete_to_trash = true, -- safer deletes (requires trash-cli on Linux)
                prompt_save_on_select_new_entry = false,

                -- Speed/clarity
                -- columns = { 'icon', 'permissions', 'size', 'mtime' }, -- informative, adjust as you like
                use_default_keymaps = true,

                keymaps = {
                    -- Keep your overrides
                    ['<C-h>'] = false,
                    ['<M-h>'] = 'actions.select_split',

                    -- Fast navigation extras (optional; remove if you have your own)
                    ['<C-s>'] = 'actions.select_vsplit',
                    ['<C-v>'] = 'actions.select_vsplit',
                    ['<C-x>'] = 'actions.select_split',
                    ['<C-t>'] = 'actions.select_tab',
                    ['q'] = 'actions.close',
                    ['.'] = 'actions.cd', -- jump into directory as cwd
                    ['~'] = 'actions.tcd', -- set tab-local cwd
                    ['H'] = 'actions.toggle_hidden', -- toggle dotfiles
                    ['g.'] = 'actions.toggle_hidden',
                    ['gr'] = 'actions.refresh',
                    gs = {
                        callback = function()
                            local oil = require('oil')
                            -- get the current directory
                            local prefills = { paths = oil.get_current_dir() }

                            local ok, grug_far = pcall(require, 'grug-far')
                            if not ok then
                                vim.notify('grug-far not found', vim.log.levels.ERROR)
                                return
                            end

                            -- instance check
                            if not grug_far.has_instance('explorer') then
                                grug_far.open({
                                    instanceName = 'explorer',
                                    prefills = prefills,
                                    staticTitle = 'Find and Replace from Explorer',
                                })
                            else
                                local instance = grug_far.get_instance('explorer')
                                if instance then
                                    instance:open()
                                    -- updating the prefills without clearing the search and other fields
                                    instance:update_input_values(prefills, false)
                                end
                            end
                        end,
                        desc = 'oil: Search in directory',
                    },
                },

                view_options = {
                    show_hidden = true, -- see dotfiles by default
                    natural_order = true, -- sort like humans expect
                    case_insensitive = true,
                    sort = {
                        { 'type', 'asc' }, -- dirs first
                        { 'name', 'asc' },
                    },
                    -- Hide noisy folders from the list (still accessible if you cd)
                    -- is_always_hidden = function(name, _)
                    --     return name == '.git'
                    -- end,
                },

                float = {
                    padding = 1,
                    max_width = 100,
                    max_height = 30,
                    border = 'rounded',
                    win_options = {
                        winblend = 0, -- no transparency for crisp UI
                    },
                },

                win_options = {
                    signcolumn = 'no',
                },

                -- Git integration
                git = {
                    enable = true,
                    ignore = false, -- hide files per .gitignore
                    -- Optional performance tweak: you can disable live status to speed up on huge repos
                    add_signs = true,
                    show_ignored = true,
                },

                -- Performance: rely on Neovim’s async I/O; avoid extra work
                watch_for_changes = true,
                cleanup_delay_ms = 50,
            })

            -- Auto-open logic
            if not should_skip_oil() then
                -- Open parent directory of current working dir in current window
                -- Alternatives:
                --   vim.cmd('Oil --float')
                --   require('oil').open(vim.loop.cwd()) -- explicit path
                vim.cmd('Oil')
            end
        end,
    },
}
