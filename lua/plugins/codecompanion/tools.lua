return {
    opts = {
        auto_submit_errors = true,
        auto_submit_success = true,
    },
    -- Tool Groups
    groups = {
        -- Full Stack Developer with Web Search
        ['full_stack_dev'] = {
            description = 'Full stack development with web search capabilities',
            prompt = [[I'm giving you access to ${tools} to help you perform coding tasks.

IMPORTANT CONTEXT:
- Today's date: ]]
                .. os.date('%Y-%m-%d')
                .. [[
- Neovim path: /opt/homebrew/bin/nvim
- Use ripgrep (rg) for fast searching
- Check for Cargo.toml (Rust), package.json (Node.js), go.mod (Go)

When dealing with:
- Latest features, syntax, or APIs (< 2 years old)
- Current best practices or deprecations
- Recent library versions or breaking changes
- Framework updates or new releases
- Security vulnerabilities or patches

You MUST use web_search to verify current information.]],
            tools = {
                'cmd_runner',
                'create_file',
                'delete_file',
                'file_search',
                'get_changed_files',
                'grep_search',
                'insert_edit_into_file',
                'list_code_usages',
                'read_file',
                'web_search',
                'fetch_webpage',
                'memory',
            },
            opts = {
                collapse_tools = true,
            },
        },

        -- Neovim Configuration Expert
        ['neovim_expert'] = {
            description = 'Neovim configuration expert - Lua configs, plugin setup, vim.api',
            prompt = [[I'm giving you access to ${tools} to help with Neovim configuration.

You are a Neovim configuration expert specializing in:
- Neovim 0.12.0+ APIs and features
- Lua configuration patterns
- Plugin development and setup
- vim.api.* functions (prefer over vim.fn where possible)
- Lazy.nvim plugin manager

ENVIRONMENT:
- Neovim: /opt/homebrew/bin/nvim
- Version: 0.12.0
- Config: ~/.config/nvim
- Use Lua patterns (not regex)

WORKFLOW:
1. Search Neovim documentation first (web_search)
2. Check existing config files (read_file, grep_search)
3. Test changes with: nvim --headless -c "..." +qa
4. Prefer vim.api.* over vim.fn.*

PLUGIN RELOAD PROTOCOL:
When you modify plugin configuration files (lua/plugins/*.lua):
1. After making changes, ask: "Would you like me to reload the <plugin_name> plugin? (yes/no)"
2. Wait for user confirmation
3. If confirmed, run: :Lazy reload <plugin_name>
4. Use the exact plugin name from the file (e.g., 'nvim-notify' for notify.lua)
5. Notify success/failure after reload

EXAMPLE:
After editing lua/plugins/notify.lua:
- Ask: "Would you like me to reload the nvim-notify plugin?"
- If yes → run: cmd_runner with ":Lazy reload nvim-notify"

SOURCES:
- :help <topic>
- neovim.io/doc
- cd `~/.local/share/nvim/lazy`
- github.com/neovim/neovim]],
            tools = {
                'cmd_runner',
                'create_file',
                'file_search',
                'grep_search',
                'insert_edit_into_file',
                'read_file',
                'web_search',
                'fetch_webpage',
            },
            opts = {
                collapse_tools = true,
            },
        },

        opts = {
            env = {
                NVIM = '/opt/homebrew/bin/nvim',
            },
        },
    },
    ['grep_search'] = {
        opts = {
            max_results = 100,
            cmd = 'rg', -- Force ripgrep
        },
    },
    ['file_search'] = {
        opts = {
            max_results = 500,
        },
    },
    ['web_search'] = {
        opts = {
            adapter = 'tavily',
            opts = {
                search_depth = 'advanced',
                topic = 'general',
                max_results = 5,
                include_domains = {
                    'neovim.io',
                    'github.com/neovim',
                },
            },
        },
    },
    ['fetch_webpage'] = {
        opts = { adapter = 'jina' },
    },
    ['memory'] = {
        opts = { require_approval_before = true },
    },
}
