return {
    {
        'folke/snacks.nvim',
        opts = {
            image = {},
            -- notifier = {
            --   style = "minimal",
            -- },
            dashboard = {
                preset = {
                    header = 'NVIM ' .. require('config.utils').version(),
          -- stylua: ignore
          ---@type snacks.dashboard.Item[]
          keys = {
            { icon = " ", key = "n", desc = "new file", action = ":ene | startinsert" },
            { icon = " ", key = "r", desc = "recent files", action = ":lua Snacks.picker.recent({ filter = { cwd = true }})" },
            { icon = " ", key = "s", desc = "restore session", section = "session" },
            { icon = " ", key = "f", desc = "find file", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "o", desc = "smart open", action = ":lua Snacks.picker.smart()" },
            { icon = " ", key = "g", desc = "find text", action = function()
                if vim.g.lazyvim_picker == "telescope" then
                  require("plugins.telescope.filter_grep").filter_grep()
                else
                  Snacks.dashboard.pick("live_grep")
                end
              end,
            },
            { icon = " ", key = "c", desc = "config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})", },
            { icon = "󰒲 ", key = "l", desc = "lazy", action = ":Lazy" },
            { icon = " ", key = "x", desc = "lazy extras", action = ":LazyExtras" },
            { icon = " ", key = "t", desc = "terminal", action = function()
              vim.cmd[[
                terminal
                only
                startinsert
              ]]
            end },
            { icon = " ", key = "d", desc = "database", action = ":ene | DBUI" },
            { icon = "󱋊 ", key = "a", desc = "ai chat", action = function()
                vim.cmd("CodeCompanionChat")
                vim.schedule(function()
                  vim.cmd("only")
                  vim.defer_fn(function()
                    vim.cmd("startinsert")
                  end, 30)
                end)
              end },
            { icon = " ", key = "q", desc = "quit", action = ":qa" },
          },
                },
            },
            zen = {
                toggles = {
                    dim = false,
                    git_signs = false,
                    diagnostics = false,
                    inlay_hints = false,
                },
                win = {
                    style = {
                        width = 100,
                        backdrop = { transparent = false, blend = 99 },
                    },
                },
            },
            terminal = {
                auto_insert = false,
                start_insert = false,
                win = {
                    style = {
                        wo = {
                            winhighlight = 'Normal:Normal',
                        },
                    },
                },
            },
            indent = { enabled = false, only_scope = true, only_current = true },
            input = {},
            picker = {
                enabled = vim.g.lazyvim_picker == 'snacks',
                layout = { preset = 'noborder' },
                layouts = {
                    noborder = {
                        layout = {
                            box = 'horizontal',
                            title = '{title}',
                            title_pos = 'center',
                            backdrop = 60,
                            width = 0.9,
                            height = 0.9,
                            border = 'none',
                            {
                                box = 'vertical',
                                border = 'right',
                                {
                                    win = 'input',
                                    height = 1,
                                    border = 'none',
                                    title = '{title} {live} {flags}',
                                    title_pos = 'center',
                                },
                                {
                                    win = 'list',
                                    title = ' Results ',
                                    title_pos = 'center',
                                    border = 'none',
                                },
                            },
                            {
                                win = 'preview',
                                title = '{preview:Preview}',
                                width = 0.60,
                                border = 'none',
                                title_pos = 'center',
                            },
                        },
                    },
                },
                ui_select = true,
                matcher = {
                    sort_empty = false, -- sort results when the search string is empty
                    cwd_bonus = true, -- give bonus for matching files in the cwd
                    frecency = true, -- frecency bonus
                    history_bonus = true, -- give more weight to chronological order
                },
                sort = {
                    fields = { 'score:desc' },
                },
                formatter = {
                    file = {
                        filename_first = true, -- display filename before the file path
                    },
                },
                jump = {
                    jumplist = true, -- save the current position in the jumplist
                    tagstack = true, -- save the current position in the tagstack
                    reuse_win = true, -- reuse an existing window if the buffer is already open
                    close = true, -- close the picker when jumping/editing to a location (defaults to true)
                    match = true, -- jump to the first match position. (useful for `lines`)
                },
                win = {
                    preview = {
                        wo = {
                            foldcolumn = '0',
                            number = false,
                            relativenumber = false,
                            signcolumn = 'no',
                        },
                    },
                    input = {
                        keys = {
                            ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
                            ['<c-cr>'] = { 'close', mode = { 'n', 'i' } },
                            ['<c-j>'] = { 'history_back', mode = { 'n', 'i' } },
                            ['<c-k>'] = {
                                'history_forward',
                                mode = { 'n', 'i' },
                            },
                            ['<c-/>'] = { 'toggle_focus', mode = { 'n', 'i' } },
                            ['<c-i>'] = { 'toggle_focus', mode = { 'n', 'i' } },
              -- stylua: ignore start
              ["<c-u>"] = { function() vim.cmd("normal! dd") end, mode = { "n", "i" }, },
              ["<c-a>"] = { function() vim.cmd([[normal! ^i]]) end, mode = { "n", "i" }, },
              ["<c-e>"] = { function() vim.cmd([[normal! A]]) vim.api.nvim_input("<right>") end, mode = { "n", "i" }, },
                            -- stylua: ignore end
                            ['<c-s-a>'] = 'select_all',
                            ['<c-s-u>'] = {
                                'list_scroll_up',
                                mode = { 'i', 'n' },
                            },
                        },
                    },
                    list = {
                        keys = {
                            ['o'] = 'confirm',
                            ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
                            ['<c-cr>'] = { 'close', mode = { 'n', 'i' } },
                            ['<c-o>'] = { 'confirm', mode = { 'n', 'i' } },
                            ['<c-^>'] = { 'confirm', mode = { 'n', 'i' } },
                            ['<c-i>'] = { 'toggle_focus', mode = { 'n', 'i' } },
                            ['<c-/>'] = { 'toggle_focus', mode = { 'n', 'i' } },
                            ['s'] = { 'edit_split' },
                            ['S'] = { 'edit_vsplit' },
                            ['<leader><leader>'] = 'close',
                        },
                    },
                },
                sources = {
                    symbols = {
                        layout = { preset = 'noborder' },
                    },
                    explorer = {
                        win = {
                            list = {
                                keys = {
                                    ['o'] = 'confirm',
                                    ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
                                    ['<c-cr>'] = {
                                        'close',
                                        mode = { 'n', 'i' },
                                    },
                                    ['<c-o>'] = {
                                        'confirm',
                                        mode = { 'n', 'i' },
                                    },
                                    ['<c-^>'] = {
                                        'confirm',
                                        mode = { 'n', 'i' },
                                    },
                                    ['<c-i>'] = {
                                        'toggle_focus',
                                        mode = { 'n', 'i' },
                                    },
                                    ['<c-/>'] = {
                                        'toggle_focus',
                                        mode = { 'n', 'i' },
                                    },
                                    ['s'] = { 'edit_split' },
                                    ['S'] = { 'edit_vsplit' },
                                    ['<leader><leader>'] = 'close',
                                },
                            },
                        },
                    },
                },
            },
        },
        keys = {
            -- -- stylua: ignore start
            -- { "<c-cr>", function() Snacks.picker.resume() end, desc = "Resume", mode = { "n", "i" } },
            -- { "<leader><cr>", function() Snacks.picker.resume() end, desc = "Resume" },
            -- { "<leader>r", function() Snacks.picker.recent({ filter = { cwd = true }}) end, desc = "Recent (cwd)" },
            -- { "<leader>R", function() Snacks.picker.recent() end, desc = "Recent (Global)" },
            -- { "<leader>/", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
            -- { "<leader>ff", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
            -- { "<leader>fF", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
            -- { "<leader>fr", function() Snacks.picker.recent({ filter = { cwd = true }}) end, desc = "Recent (cwd)" },
            -- { "<leader>fR", LazyVim.pick("oldfiles"), desc = "Recent" },
            -- { "<leader>j", function() Snacks.picker.jumps() end, desc = "Jumps" },
            -- { "<leader><leader>", function() Snacks.picker.smart() end, desc = "Smart" },
            -- { "<leader>fl", function() Snacks.picker.files({ cwd = vim.fn.stdpath("data") }) end, desc = "Open local nvim data directory", },
            -- { "<M-z>", function() Snacks.zen.zoom() end, desc = "Zen Zoom" },
            -- { "<M-s-z>", function() Snacks.zen.zen() end, desc = "Zen" },
            -- stylua: ignore end
        },
    },
}
