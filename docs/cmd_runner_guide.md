# CodeCompanion cmd_runner Quick Reference

This file provides quick examples of how to use the `cmd_runner` tool with CodeCompanion in this Neovim configuration workspace.

## What is cmd_runner?

The `cmd_runner` is a CodeCompanion tool that allows the AI assistant to execute shell commands on your system. It runs commands in your current working directory: `/Users/oleksiiluchnikov/.config/nvim`

## How to Use It

Simply ask CodeCompanion to run commands naturally. For example:
- "Run the tests"
- "Check if there are any formatting issues"
- "Show me what plugins are installed"
- "Find all lua files in the plugins directory"

CodeCompanion will automatically use the `cmd_runner` tool to execute the appropriate command.

## Common Command Examples

### Testing
```bash
# Run busted tests
busted

# Run Neovim plugin tests with Plenary
nvim --headless -c "PlenaryBustedDirectory lua/tests {minimal_init = 'tests/minimal_init.lua'}"
```

### Code Formatting & Linting
```bash
# Check Lua formatting
stylua lua/ --check

# Format Lua files
stylua lua/

# Check with luacheck (if installed)
luacheck lua/
```

### Plugin Management
```bash
# Sync all plugins
nvim --headless "+Lazy! sync" +qa

# Clean unused plugins
nvim --headless "+Lazy! clean" +qa

# Update plugins
nvim --headless "+Lazy! update" +qa

# Show plugin status
nvim --headless "+Lazy! show" +qa
```

### File Operations
```bash
# Find all Lua files
fd -e lua

# Find files matching pattern
fd -e lua -e vim

# Find in specific directory
fd . lua/plugins

# Count lines of Lua code
find lua -name "*.lua" -exec wc -l {} + | tail -1
```

### Search Operations
```bash
# Search for text in files
rg "codecompanion"

# Search in specific file types
rg "codecompanion" -t lua

# Search with context
rg "codecompanion" -A 3 -B 3

# Case-insensitive search
rg -i "codecompanion"
```

### Git Operations
```bash
# Check status
git status

# View changes
git diff

# View staged changes
git diff --cached

# Show commit history
git log --oneline -10

# Show files changed
git diff --name-only
```

### System Info
```bash
# Check Neovim version
nvim --version | head -1

# List running Neovim instances
ps aux | grep nvim

# Check shell
echo $SHELL

# Show current directory
pwd

# Disk usage of config
du -sh ~/.config/nvim
```

### Neovim Health Checks
```bash
# Run health checks
nvim --headless -c "checkhealth codecompanion" -c "write! /tmp/health.txt" -c "qa" && cat /tmp/health.txt

# Check LSP health
nvim --headless -c "checkhealth lsp" -c "write! /tmp/health.txt" -c "qa" && cat /tmp/health.txt
```

## Example Conversations with cmd_runner

### Example 1: Formatting Check
**You:** "Check if all my Lua files are properly formatted"

**CodeCompanion:** Uses `cmd_runner` to execute:
```bash
stylua lua/ --check
```
Then reports the results and can offer to fix any issues.

### Example 2: Find and Edit
**You:** "Find all files that use the old vim.cmd syntax and show me"

**CodeCompanion:** 
1. Uses `cmd_runner`: `rg "vim.cmd" -t lua`
2. Uses `read_file` to examine the files
3. Suggests changes and can use `insert_edit_into_file` to fix them

### Example 3: Test and Debug
**You:** "Run the tests and fix any failures"

**CodeCompanion:**
1. Uses `cmd_runner`: `busted`
2. Analyzes the error output
3. Uses `read_file` to check the failing code
4. Uses `insert_edit_into_file` to fix the issues
5. Uses `cmd_runner` again to verify the fix

### Example 4: Plugin Management
**You:** "Update all my plugins and let me know if there are any breaking changes"

**CodeCompanion:**
1. Uses `cmd_runner`: `nvim --headless "+Lazy! update" +qa`
2. Checks for updates
3. Can read plugin documentation or changelogs
4. Reports any potential breaking changes

## History Integration

When you restore a previous chat session:
- All previous `cmd_runner` executions are preserved in the chat
- Command outputs are available as context
- CodeCompanion remembers what was tried before

**Example:**
1. Session 1: "Run tests" → Tests fail
2. Close Neovim
3. Session 2: Restore chat with `<leader>jr`
4. "Let's continue fixing those test failures"
5. CodeCompanion remembers the test output and context

## Safety Features

The `cmd_runner` has built-in safety restrictions:
- ❌ Never runs `rm -rf /` or similar destructive commands
- ⚠️  Warns before any destructive operations
- ✅ Suggests safer alternatives
- 🔒 Only executes when explicitly requested

## Useful Keybindings

- `<leader>j` - Toggle chat (continue previous or start new)
- `<leader>jl` - Open last chat
- `<leader>jr` - Restore saved chat (picker)
- `<C-a>` - Action palette (includes all CodeCompanion actions)
- `ga` (visual) - Add selection to chat

## Tips

1. **Be specific**: "Run stylua on lua/plugins/" is better than "format code"
2. **Combine operations**: "Check formatting, fix issues, then run tests"
3. **Use context**: "Look at the previous error and try a different fix"
4. **Iterate**: Let CodeCompanion run commands, see results, and adjust
5. **Restore sessions**: Long debugging sessions can be saved and continued later

## Advanced Workflows

### Workflow 1: Complete Feature Addition
```
You: "Add support for a new LSP server for Zig"

CodeCompanion will:
1. Search for similar LSP configs (grep_search)
2. Create new plugin file (create_file)
3. Test the config (cmd_runner: nvim --headless)
4. Check for errors
5. Offer to run the LSP server
```

### Workflow 2: Refactoring with Verification
```
You: "Refactor all my plugins to use the new lazy.nvim format"

CodeCompanion will:
1. List all plugin files (file_search)
2. Read each file (read_file)
3. Make changes (insert_edit_into_file)
4. Verify syntax (cmd_runner: lua -l lua/plugins/*)
5. Test loading (cmd_runner: nvim --headless)
```

### Workflow 3: Debugging Configuration
```
You: "My CodeCompanion setup isn't working, help me debug it"

CodeCompanion will:
1. Read the config (read_file)
2. Check health (cmd_runner: checkhealth)
3. Look for errors in logs
4. Suggest fixes
5. Test the changes
```

## Troubleshooting

**Q: Command didn't run?**
A: Make sure you explicitly asked CodeCompanion to run it. Try: "Please run [command]"

**Q: Command failed?**
A: CodeCompanion will show you the error. Ask it to analyze and suggest fixes.

**Q: Can I see command history?**
A: Yes! Scroll up in the chat buffer or restore a previous chat session.

**Q: How do I prevent a command from running?**
A: Tell CodeCompanion "Don't run that" or "Show me what you would run first"

## Resources

- CodeCompanion docs: `:help codecompanion`
- Workspace file: `.codecompanion` (at repo root)
- Config: `lua/plugins/codecompanion.lua`
- Issue tracker: https://github.com/olimorris/codecompanion.nvim/issues
