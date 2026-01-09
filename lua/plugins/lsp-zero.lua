return {
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        dependencies = {
            'neovim/nvim-lspconfig',
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'netmute/ctags-lsp.nvim',
            'folke/lazydev.nvim',
        },
        config = function()
            -- Suppress lspconfig deprecation warnings until migration is stable
            local original_deprecate = vim.deprecate
            vim.deprecate = function(
                name,
                alternative,
                version,
                plugin,
                backtrace
            )
                -- Suppress only lspconfig-related deprecation warnings
                if
                    name
                    and (
                        name:match('lspconfig')
                        or name:match('lsp%.start_client')
                    )
                then
                    return
                end
                return original_deprecate(
                    name,
                    alternative,
                    version,
                    plugin,
                    backtrace
                )
            end

            -- 1. INITIAL SETUP
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_lspconfig()

            local mason = require('mason')
            local mason_lspconfig = require('mason-lspconfig')

            -- Configure diagnostics globally
            vim.diagnostic.config({
                virtual_text = {
                    spacing = 4,
                    prefix = '●',
                },
                signs = true,
                update_in_insert = false,
                underline = true,
                severity_sort = true,
                float = {
                    border = 'rounded',
                    source = 'always',
                    header = '',
                    prefix = '',
                    focusable = false,
                },
            })

            -- Configure diagnostic signs
            local signs = {
                { name = 'DiagnosticSignError', text = '' },
                { name = 'DiagnosticSignWarn', text = '' },
                { name = 'DiagnosticSignHint', text = '󰌵' },
                { name = 'DiagnosticSignInfo', text = '' },
            }

            for _, sign in ipairs(signs) do
                vim.fn.sign_define(sign.name, {
                    texthl = sign.name,
                    text = sign.text,
                    numhl = '',
                })
            end

            mason.setup({
                ui = {
                    border = 'rounded',
                    icons = {
                        package_installed = '✓',
                        package_pending = '➜',
                        package_uninstalled = '✗',
                    },
                },
            })

            -- 2. CUSTOM HELPERS
            local user_info_cache
            local function get_user_info()
                if not user_info_cache then
                    user_info_cache = {
                        username = vim.fn.system('whoami'):gsub('[\n\r]', ''),
                        fullname = vim.fn
                            .system('git config --get user.name')
                            :gsub('[\n\r]', ''),
                        email = vim.fn
                            .system('git config --get user.email')
                            :gsub('[\n\r]', ''),
                    }
                end
                return user_info_cache
            end

            local function is_my_spoon(file_path)
                local info = get_user_info()
                local content = vim.fn.readfile(file_path)

                for _, line in ipairs(content) do
                    -- Check author lines
                    for _, identifier in ipairs({
                        info.username,
                        info.fullname,
                        info.email,
                    }) do
                        if
                            line:match(
                                '^%w+%.author%s*=%s*.*' .. vim.pesc(identifier)
                            )
                        then
                            return true
                        end
                    end
                    -- Check spoonPath
                    if
                        line:match(
                            'spoonPath = ".*'
                                .. vim.pesc(info.username)
                                .. '.*"'
                        )
                    then
                        return true
                    end
                end

                return false
            end

            local function filter_spoon_diagnostics(err, result, ctx, cfg)
                if not result then
                    return
                end

                local spoon_path_pattern = '^file.*%.spoon.*$'
                if result.uri:match(spoon_path_pattern) then
                    if not result.uri:match('^.*init%.lua$') then
                        return
                    end
                    local file_path = vim.uri_to_fname(result.uri)
                    if is_my_spoon(file_path) then
                        return vim.lsp.handlers['textDocument/publishDiagnostics'](
                            err,
                            result,
                            ctx,
                            cfg
                        )
                    end
                    return
                end
                return vim.lsp.handlers['textDocument/publishDiagnostics'](
                    err,
                    result,
                    ctx,
                    cfg
                )
            end

            local function filter_trash_notes(err, result, ctx, cfg)
                if not result then
                    return
                end

                if result.uri:match('.*%.trash/.*') then
                    result.diagnostics = vim.tbl_filter(function(d)
                        return not string.find(d.source or '', '%.trash/')
                    end, result.diagnostics)
                end
                vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, cfg)
            end

            -- 3. CAPABILITIES SETUP
            local capabilities = vim.lsp.protocol.make_client_capabilities()

            -- Add completion capabilities
            local cmp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
            if cmp_ok then
                capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
            end

            -- Add folding capabilities for nvim-ufo
            capabilities.textDocument.foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
            }

            -- 4. MAIN ON_ATTACH
            local on_attach_lsp = function(client, bufnr)
                -- Optional: notify when LSP attaches
                -- vim.notify(
                --     string.format('LSP [%s] attached', client.name),
                --     vim.log.levels.INFO
                -- )

                -- Inlay Hints
                if client.supports_method('textDocument/inlayHint') then
                    local ok, hints = pcall(require, 'lsp-inlayhints')
                    if ok then
                        hints.on_attach(client, bufnr)
                    end
                end

                -- Formatting
                pcall(function()
                    if package.loaded['lsp-format'] then
                        require('lsp-format').on_attach(client, bufnr)
                    end
                end)

                vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
                local opts = { buffer = bufnr, noremap = true, silent = true }

                -- Diagnostics
                vim.keymap.set(
                    'n',
                    '<leader>e',
                    vim.diagnostic.open_float,
                    vim.tbl_extend(
                        'force',
                        opts,
                        { desc = 'open diagnostics float' }
                    )
                )

                vim.keymap.set(
                    'n',
                    '<leader>q',
                    vim.diagnostic.setloclist,
                    vim.tbl_extend('force', opts, { desc = 'set loclist' })
                )

                -- Trouble Integration (with better error handling)
                vim.keymap.set(
                    'n',
                    '[d',
                    function()
                        local trouble_ok, trouble = pcall(require, 'trouble')
                        if trouble_ok and trouble.is_open() then
                            trouble.prev({ skip_groups = true, jump = true })
                        else
                            vim.diagnostic.jump({ count = -1, float = true })
                        end
                    end,
                    vim.tbl_extend('force', opts, { desc = 'prev diagnostic' })
                )

                vim.keymap.set(
                    'n',
                    ']d',
                    function()
                        local trouble_ok, trouble = pcall(require, 'trouble')
                        if trouble_ok and trouble.is_open() then
                            trouble.next({ skip_groups = true, jump = true })
                        else
                            vim.diagnostic.jump({ count = 1, float = true })
                        end
                    end,
                    vim.tbl_extend('force', opts, { desc = 'next diagnostic' })
                )

                -- Custom Search Definition (FIXED - no global cwd change)
                vim.keymap.set(
                    'n',
                    '<leader>gd',
                    function()
                        local root_dir = vim.lsp.buf.list_workspace_folders()[1]
                            or vim.fn.getcwd()
                        local current_search = vim.fn.expand('<cword>')

                        if
                            type(current_search) == 'string'
                            and current_search ~= ''
                            and not current_search:find('\n')
                        then
                            require('telescope.builtin').grep_string({
                                cwd = root_dir,
                                search = current_search,
                                word_match = '-w', -- This is correct for ripgrep
                                only_sort_text = true,
                                path_display = { 'truncate' },
                            })
                        end
                    end,
                    vim.tbl_extend('force', opts, { desc = 'find definitions' })
                )

                vim.keymap.set(
                    'v',
                    '<leader>gd',
                    function()
                        local root_dir = vim.lsp.buf.list_workspace_folders()[1]
                            or vim.fn.getcwd()

                        -- Get visual selection properly
                        vim.cmd('normal! "vy')
                        local current_search = vim.fn.getreg('v')

                        if
                            type(current_search) == 'string'
                            and current_search ~= ''
                            and not string.find(current_search, '\n')
                        then
                            require('telescope.builtin').grep_string({
                                cwd = root_dir,
                                search_dirs = { root_dir },
                                default_text = current_search,
                                word_match = '-w',
                                path_display = { 'smart' },
                                initial_mode = 'normal',
                            })
                        end
                    end,
                    vim.tbl_extend('force', opts, { desc = 'find definitions' })
                )

                -- Standard LSP Keys
                vim.keymap.set(
                    'n',
                    'gD',
                    vim.lsp.buf.declaration,
                    vim.tbl_extend('force', opts, { desc = 'goto declaration' })
                )

                vim.keymap.set(
                    'n',
                    'gd',
                    vim.lsp.buf.definition,
                    vim.tbl_extend('force', opts, { desc = 'goto definition' })
                )

                vim.keymap.set(
                    'n',
                    'gt',
                    vim.lsp.buf.type_definition,
                    vim.tbl_extend(
                        'force',
                        opts,
                        { desc = 'goto type definition' }
                    )
                )

                vim.keymap.set(
                    'n',
                    'K',
                    function()
                        vim.lsp.buf.hover()
                    end,
                    vim.tbl_extend(
                        'force',
                        opts,
                        { desc = 'hover documentation' }
                    )
                )

                vim.keymap.set(
                    'n',
                    'gi',
                    vim.lsp.buf.implementation,
                    vim.tbl_extend(
                        'force',
                        opts,
                        { desc = 'goto implementation' }
                    )
                )

                vim.keymap.set(
                    'n',
                    '<C-k>',
                    vim.lsp.buf.signature_help,
                    vim.tbl_extend('force', opts, { desc = 'signature help' })
                )

                vim.keymap.set(
                    'n',
                    '<leader>wa',
                    vim.lsp.buf.add_workspace_folder,
                    vim.tbl_extend(
                        'force',
                        opts,
                        { desc = 'add workspace folder' }
                    )
                )

                vim.keymap.set(
                    'n',
                    '<leader>wr',
                    vim.lsp.buf.remove_workspace_folder,
                    vim.tbl_extend(
                        'force',
                        opts,
                        { desc = 'remove workspace folder' }
                    )
                )

                vim.keymap.set(
                    'n',
                    '<leader>wl',
                    function()
                        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                    end,
                    vim.tbl_extend(
                        'force',
                        opts,
                        { desc = 'list workspace folders' }
                    )
                )

                vim.keymap.set(
                    'n',
                    '<leader>rn',
                    vim.lsp.buf.rename,
                    vim.tbl_extend('force', opts, { desc = 'rename symbol' })
                )

                vim.keymap.set(
                    { 'n', 'v' },
                    '<leader>ca',
                    vim.lsp.buf.code_action,
                    vim.tbl_extend('force', opts, { desc = 'code action' })
                )

                vim.keymap.set(
                    'n',
                    'gr',
                    function()
                        require('telescope.builtin').lsp_references({
                            default_text = vim.fn.expand('<cword>'),
                            include_declaration = false,
                        })
                    end,
                    vim.tbl_extend('force', opts, { desc = 'find references' })
                )

                vim.keymap.set('n', '<leader>f', function()
                    vim.lsp.buf.format({ async = true })
                end, vim.tbl_extend(
                    'force',
                    opts,
                    { desc = 'format buffer' }
                ))

                -- Document Highlight
                if client.supports_method('textDocument/documentHighlight') then
                    local group = vim.api.nvim_create_augroup(
                        'LspDocumentHighlight',
                        { clear = false }
                    )
                    vim.api.nvim_clear_autocmds({
                        buffer = bufnr,
                        group = group,
                    })
                    vim.api.nvim_create_autocmd(
                        { 'CursorHold', 'CursorHoldI' },
                        {
                            group = group,
                            buffer = bufnr,
                            callback = vim.lsp.buf.document_highlight,
                        }
                    )
                    vim.api.nvim_create_autocmd(
                        { 'CursorMoved', 'CursorMovedI' },
                        {
                            group = group,
                            buffer = bufnr,
                            callback = vim.lsp.buf.clear_references,
                        }
                    )
                end
            end

            vim.opt.signcolumn = 'yes'

            -- 5. HANDLERS
            mason_lspconfig.setup({
                ensure_installed = {
                    'lua_ls',
                    'bashls',
                    'marksman',
                    'ts_ls',
                },
                handlers = {
                    -- Default handler using native vim.lsp
                    function(server_name)
                        require('lspconfig')[server_name].setup({
                            on_attach = on_attach_lsp,
                            capabilities = capabilities,
                        })
                    end,

                    -- BASH
                    bashls = function()
                        require('lspconfig').bashls.setup({
                            on_attach = on_attach_lsp,
                            capabilities = capabilities,
                            cmd_env = {
                                GLOB_PATTERN = '*@(.sh|.inc|.bash|.command)',
                            },
                            filetypes = { 'sh', 'zsh', 'bash', 'shell' },
                        })
                    end,

                    -- LUA
                    lua_ls = function()
                        require('lspconfig').lua_ls.setup({
                            capabilities = capabilities,
                            root_dir = function(fname)
                                local util = require('lspconfig.util')
                                return util.root_pattern(
                                    '.git',
                                    '.luarc.json',
                                    '.luarc.jsonc',
                                    '.luacheckrc',
                                    'stylua.toml',
                                    'selene.toml'
                                )(fname) or util.find_git_ancestor(
                                    fname
                                ) or vim.fn.getcwd()
                            end,
                            on_attach = function(client, bufnr)
                                on_attach_lsp(client, bufnr)

                                -- Lua-specific cursor behavior
                                local group = vim.api.nvim_create_augroup(
                                    'LspLua',
                                    { clear = true }
                                )
                                vim.api.nvim_create_autocmd('InsertLeave', {
                                    buffer = bufnr,
                                    group = group,
                                    callback = function()
                                        local line =
                                            vim.api.nvim_win_get_cursor(0)[1]
                                        if line ~= vim.b.last_line then
                                            vim.cmd('normal! zz')
                                            vim.b.last_line = line
                                            if vim.fn.getline(line) == '' then
                                                local column =
                                                    vim.fn.getcurpos()[5]
                                                vim.fn.cursor({ line, column })
                                            end
                                        end
                                    end,
                                })
                            end,
                            handlers = {
                                ['textDocument/publishDiagnostics'] = filter_spoon_diagnostics,
                            },
                            on_init = function(client)
                                -- Hammerspoon integration
                                local path = client.workspace_folders
                                        and client.workspace_folders[1].name
                                    or vim.fn.getcwd()

                                if path:match('hammerspoon') then
                                    local library = client.config.settings.Lua.workspace.library
                                        or {}
                                    table.insert(
                                        library,
                                        vim.fn.expand(
                                            '~/.config/hammerspoon/Spoons/EmmyLua.spoon/annotations'
                                        )
                                    )
                                    client.config.settings.Lua.workspace.library =
                                        library
                                    client.notify(
                                        'workspace/didChangeConfiguration',
                                        {
                                            settings = client.config.settings,
                                        }
                                    )
                                end
                            end,
                            settings = {
                                Lua = {
                                    completion = {
                                        displayContext = 1,
                                        callSnippet = 'Replace',
                                    },
                                    diagnostics = {
                                        enable = true,
                                        globals = {
                                            'vim',
                                            'use',
                                            'hs',
                                            'describe',
                                            'it',
                                            'before_each',
                                            'after_each',
                                        },
                                        disable = { 'missing-fields' },
                                    },
                                    format = { enable = false },
                                    hint = { enable = true },
                                    runtime = {
                                        version = 'LuaJIT',
                                        path = vim.split(package.path, ';'),
                                        pathStrict = true,
                                    },
                                    workspace = {
                                        library = {
                                            vim.env.VIMRUNTIME,
                                            vim.fn.stdpath('config') .. '/lua',
                                        },
                                        checkThirdParty = false,
                                        maxPreload = 10000,
                                        preloadFileSize = 10000,
                                    },
                                    telemetry = { enable = false },
                                },
                            },
                        })
                    end,

                    -- MARKSMAN
                    -- marksman = function()
                    --     require('lspconfig').marksman.setup({
                    --         on_attach = on_attach_lsp,
                    --         capabilities = capabilities,
                    --         handlers = {
                    --             ['textDocument/publishDiagnostics'] = filter_trash_notes,
                    --         },
                    --         filetypes = { 'markdown', 'markdown.mdx' },
                    --     })
                    -- end,

                    -- MARKSMAN
                    marksman = function()
                        local function expand_brace_glob(glob)
                            if type(glob) ~= 'string' or not glob:find('{') then
                                return { glob }
                            end
                            local alts = {}
                            -- extract inside braces (handles only the first {...} group; that's what's used by marksman)
                            local inside = glob:match('{(.-)}')
                            if not inside then
                                return { glob }
                            end
                            alts = vim.split(inside, ',')
                            local res = {}
                            for _, alt in ipairs(alts) do
                                local g = glob:gsub('{(.-)}', alt)
                                table.insert(res, g)
                            end
                            return res
                        end

                        local function sanitize_fileops(cap)
                            if not cap or type(cap) ~= 'table' then
                                return
                            end
                            local fo =
                                vim.tbl_get(cap, 'workspace', 'fileOperations')
                            if not fo or type(fo) ~= 'table' then
                                return
                            end

                            for op_name, reg in pairs(fo) do
                                -- reg should be a registration table with a `filters` field (lowercase)
                                if
                                    reg
                                    and type(reg) == 'table'
                                    and reg.filters
                                    and type(reg.filters) == 'table'
                                then
                                    local new_filters = {}
                                    for _, filt in ipairs(reg.filters) do
                                        local pat = filt.pattern
                                        if
                                            pat
                                            and type(pat.glob) == 'string'
                                            and pat.glob:find('{')
                                        then
                                            local expanded =
                                                expand_brace_glob(pat.glob)
                                            for _, g in ipairs(expanded) do
                                                -- shallow copy the filter and replace the glob
                                                local copy = vim.deepcopy(filt)
                                                copy.pattern = copy.pattern
                                                    or {}
                                                copy.pattern.glob = g
                                                table.insert(new_filters, copy)
                                            end
                                        else
                                            table.insert(new_filters, filt)
                                        end
                                    end
                                    -- replace filters in-place
                                    reg.filters = new_filters
                                end
                            end
                        end

                        require('lspconfig').marksman.setup({
                            on_attach = on_attach_lsp,
                            capabilities = capabilities,
                            handlers = {
                                ['textDocument/publishDiagnostics'] = filter_trash_notes,
                            },
                            filetypes = { 'markdown', 'markdown.mdx' },

                            -- sanitize marksman's advertised fileOperation globs to avoid brace syntax
                            on_init = function(client, _)
                                sanitize_fileops(client.server_capabilities)
                                -- return true to indicate init succeeded (lspconfig convention)
                                return true
                            end,
                        })
                    end,

                    -- CLANGD
                    clangd = function()
                        local clangd_capabilities = vim.deepcopy(capabilities)
                        clangd_capabilities.offsetEncoding = { 'utf-16' }

                        require('lspconfig').clangd.setup({
                            on_attach = on_attach_lsp,
                            capabilities = clangd_capabilities,
                            handlers = {
                                ['textDocument/publishDiagnostics'] = filter_trash_notes,
                            },
                            cmd = {
                                'clangd',
                                '--background-index',
                                '--clang-tidy',
                                '--header-insertion=iwyu',
                                '--completion-style=detailed',
                                '--function-arg-placeholders',
                            },
                        })
                    end,

                    -- TYPESCRIPT
                    ts_ls = function()
                        require('lspconfig').ts_ls.setup({
                            on_attach = on_attach_lsp,
                            capabilities = capabilities,
                            settings = {
                                typescript = {
                                    inlayHints = {
                                        includeInlayParameterNameHints = 'all',
                                        includeInlayFunctionParameterTypeHints = true,
                                        includeInlayVariableTypeHints = true,
                                        includeInlayPropertyDeclarationTypeHints = true,
                                        includeInlayFunctionLikeReturnTypeHints = true,
                                        includeInlayEnumMemberValueHints = true,
                                    },
                                },
                                javascript = {
                                    inlayHints = {
                                        includeInlayParameterNameHints = 'all',
                                        includeInlayFunctionParameterTypeHints = true,
                                        includeInlayVariableTypeHints = true,
                                        includeInlayPropertyDeclarationTypeHints = true,
                                        includeInlayFunctionLikeReturnTypeHints = true,
                                        includeInlayEnumMemberValueHints = true,
                                    },
                                },
                            },
                        })
                    end,

                    -- SVELTE
                    svelte = function()
                        require('lspconfig').svelte.setup({
                            on_attach = on_attach_lsp,
                            capabilities = capabilities,
                            on_init = function(client)
                                client.server_capabilities.semanticTokensProvider =
                                    nil
                            end,
                            settings = {
                                svelte = {
                                    plugin = {
                                        html = {
                                            completions = {
                                                enable = true,
                                                emmet = false,
                                            },
                                        },
                                    },
                                },
                            },
                        })
                    end,

                    -- RUST
                    rust_analyzer = function()
                        require('lspconfig').rust_analyzer.setup({
                            on_attach = function(client, bufnr)
                                on_attach_lsp(client, bufnr)

                                -- Rust-specific keymaps
                                local rust_tools_ok =
                                    pcall(require, 'rust-tools')
                                if rust_tools_ok then
                                    local rt = require('rust-tools')
                                    vim.keymap.set(
                                        'n',
                                        '<C-space>',
                                        rt.hover_actions.hover_actions,
                                        {
                                            buffer = bufnr,
                                            desc = 'rust hover actions',
                                        }
                                    )
                                    vim.keymap.set(
                                        'n',
                                        '<Leader>ga',
                                        rt.code_action_group.code_action_group,
                                        {
                                            buffer = bufnr,
                                            desc = 'rust code actions',
                                        }
                                    )
                                end

                                -- Auto-show diagnostics on cursor hold
                                vim.api.nvim_create_autocmd('CursorHold', {
                                    buffer = bufnr,
                                    callback = function()
                                        vim.diagnostic.open_float(nil, {
                                            focus = false,
                                            scope = 'cursor',
                                        })
                                    end,
                                })
                            end,
                            capabilities = capabilities,
                            settings = {
                                ['rust-analyzer'] = {
                                    assist = { importMergeBehaviour = 'full' },
                                    cargo = {
                                        loadOutDirsFromCheck = true,
                                        buildScripts = { enable = true },
                                        allFeatures = true,
                                    },
                                    procMacro = { enable = true },
                                    checkOnSave = {
                                        command = 'clippy',
                                        allFeatures = true,
                                    },
                                },
                            },
                        })
                    end,

                    -- PYTHON (Ruff)
                    ruff = function()
                        require('lspconfig').ruff.setup({
                            on_attach = on_attach_lsp,
                            capabilities = capabilities,
                            init_options = {
                                settings = {
                                    args = {},
                                    fixAll = true,
                                    organizeImports = true,
                                },
                            },
                        })
                    end,

                    -- ESLINT
                    eslint = function()
                        require('lspconfig').eslint.setup({
                            on_attach = function(client, bufnr)
                                -- Disable formatting - let prettier handle it
                                client.server_capabilities.documentFormattingProvider =
                                    false
                                client.server_capabilities.semanticTokensProvider =
                                    nil
                                on_attach_lsp(client, bufnr)

                                -- Auto-fix on save
                                vim.api.nvim_create_autocmd('BufWritePre', {
                                    buffer = bufnr,
                                    command = 'EslintFixAll',
                                })
                            end,
                            capabilities = capabilities,
                            settings = {
                                workingDirectory = { mode = 'auto' },
                            },
                        })
                    end,
                },
            })

            -- 6. MANUAL SETUP (Harper)
            local harper_available = vim.fn.executable('harper-ls') == 1
            if harper_available then
                require('lspconfig').harper_ls.setup({
                    handlers = {
                        ['textDocument/publishDiagnostics'] = filter_trash_notes,
                    },
                    on_attach = on_attach_lsp,
                    capabilities = capabilities,
                    settings = {
                        ['harper-ls'] = {
                            userDictPath = os.getenv('XDG_CONFIG_HOME')
                                .. '/harper-ls/dictionary.txt',
                            linters = {
                                SpellCheck = true,
                                SpelledNumbers = false,
                                AnA = true,
                                SentenceCapitalization = false,
                                UnclosedQuotes = true,
                                LongSentences = true,
                                RepeatedWords = true,
                            },
                            diagnosticSeverity = 'hint',
                            dialect = 'American',
                        },
                    },
                    filetypes = { 'markdown', 'text', 'gitcommit' },
                })
            end

            -- 7. LSP STATUS
            local lsp_status_ok, lsp_status = pcall(require, 'lsp-status')
            if lsp_status_ok then
                lsp_status.register_progress()
                -- Add status to capabilities if using it
                capabilities = vim.tbl_extend(
                    'keep',
                    capabilities,
                    lsp_status.capabilities
                )
                lsp_status.config = {
                    select_symbol = function(cursor_pos, symbol)
                        if symbol.valueRange then
                            local value_range = {
                                ['start'] = {
                                    character = 0,
                                    line = vim.fn.byte2line(
                                        symbol.valueRange[1]
                                    ),
                                },
                                ['end'] = {
                                    character = 0,
                                    line = vim.fn.byte2line(
                                        symbol.valueRange[2]
                                    ),
                                },
                            }
                            return require('lsp-status.util').in_range(
                                cursor_pos,
                                value_range
                            )
                        end
                    end,
                }
            end
        end,
    },
}
