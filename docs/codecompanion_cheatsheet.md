# CodeCompanion Cheat Sheet

## Quick Reference for History & cmd_runner

### Keybindings

| Key | Mode | Action |
|-----|------|--------|
| `<leader>j` | n, v | Toggle CodeCompanion chat (resume last or new) |
| `<leader>jl` | n | Open **last** chat |
| `<leader>jr` | n | **Restore** chat (picker with all saved chats) |
| `<C-a>` | n, v | Action palette (all CodeCompanion actions) |
| `ga` | v | Add visual selection to chat |
| `<leader>x` | v | Add code to chat buffer |

### Commands

```vim
" Chat Management
:CodeCompanionChat Toggle          " Resume last or create new
:CodeCompanionChat Last             " Open most recent chat
:lua require('codecompanion').restore()  " Browse all saved chats
:CodeCompanionChat Add              " Add current buffer to chat

" Other Actions
:CodeCompanionActions               " Open action palette
:CodeCompanion                      " Inline assistant
```

### Common cmd_runner Tasks

#### Testing
```bash
busted                              # Run Lua tests
busted lua/tests/specific_spec.lua  # Run specific test
```

#### Formatting
```bash
stylua lua/ --check                 # Check formatting
stylua lua/                         # Format all Lua files
stylua lua/plugins/                 # Format specific directory
```

#### Plugin Management
```bash
nvim --headless "+Lazy! sync" +qa   # Sync all plugins
nvim --headless "+Lazy! clean" +qa  # Clean unused plugins
nvim --headless "+Lazy! update" +qa # Update all plugins
```

#### File Operations
```bash
fd -e lua                           # Find all Lua files
fd . lua/plugins                    # Find in specific dir
find lua -name "*.lua" | wc -l      # Count Lua files
```

#### Search
```bash
rg "pattern"                        # Search in all files
rg "pattern" -t lua                 # Search in Lua files
rg -i "pattern"                     # Case-insensitive search
rg "pattern" -A 3 -B 3              # Show context
```

#### Git
```bash
git status                          # Check status
git diff                            # View changes
git log --oneline -10               # Recent commits
```

### Example Prompts

#### Starting Fresh
```
"Run all tests and show me any failures"
"Check if my Lua files are properly formatted"
"Find all files that use the old vim.cmd syntax"
"Show me which plugins are currently installed"
```

#### Continuing Work (After Restore)
```
"Let's continue where we left off"
"What were we working on?"
"Run the same command as before"
"Apply the same fix to the other files"
```

#### Iterative Workflows
```
"Run tests, if any fail, help me fix them"
"Check formatting, fix issues, then verify"
"Find all TODOs, help me prioritize and fix them"
"Update all plugins and check for breaking changes"
```

### History Workflow

#### Save & Restore Pattern
```
Session 1:
  <leader>j              → Start new chat
  "Run tests"            → AI uses cmd_runner
  [work on fixes]
  [close Neovim]

Session 2:
  <leader>jr             → Restore chat picker
  [select previous]
  "Continue debugging"   → AI has full context
  [complete the work]
```

### Pro Tips

#### 1. Descriptive First Messages
```
✅ Good: "Debug failing tests in lua/tests/utils_spec.lua"
❌ Bad:  "help"
```

#### 2. Let AI Verify Changes
```
You: "Fix the formatting"
AI:  [makes changes]
     [automatically runs] stylua lua/
     "All files now formatted correctly!"
```

#### 3. Use Workspace Context
```
You: "Following our coding standards, refactor this function"
AI:  [reads .codecompanion workspace file]
     [applies project-specific patterns]
```

#### 4. Combine Multiple Operations
```
"Check git status, stage all lua files, and show me the diff"
"Find all deprecation warnings, fix them, and run tests"
"Format all code, run linter, commit if clean"
```

#### 5. Save Long Sessions
```
Working on complex refactor? Don't worry!
  • Chat history auto-saves
  • All cmd_runner outputs preserved
  • Can restore and continue anytime
  • Context never lost
```

### Slash Commands (In Chat)

| Command | Shortcut | Description |
|---------|----------|-------------|
| `/buffer` | `<C-b>` | Add buffer to context |
| `/fetch` | `<C-f>` | Fetch webpage content |
| `/help` | - | Search Neovim help |
| `/image` | `<C-i>` | Add image to chat |

### Storage Locations

```
Workspace:  ~/.config/nvim/.codecompanion
Config:     ~/.config/nvim/lua/plugins/codecompanion.lua
History:    ~/.local/share/nvim/codecompanion/
Docs:       ~/.config/nvim/docs/
```

### Quick Troubleshooting

#### Chat not opening?
```
:CodeCompanion     " Try inline first
:messages          " Check for errors
:checkhealth codecompanion
```

#### Command didn't run?
```
• Make sure you explicitly asked ("please run...")
• Check cmd_runner tool is enabled (it is in your config)
• Look at chat buffer for error messages
```

#### Can't find old chat?
```
<leader>jr         " Open restore picker
                   " Shows all saved chats
                   " Select one to restore
```

#### Tool outputs not showing?
```
In your config, tools are enabled with auto_submit_errors = true
This means errors are automatically fed back to the AI
Outputs should appear in the chat buffer
```

### Advanced Patterns

#### Pattern 1: Test-Driven Development
```
1. <leader>j "Write a test for [feature]"
2. AI creates test file
3. "Run the test" → cmd_runner: busted
4. "Implement the feature"
5. "Run test again" → Verify ✅
```

#### Pattern 2: Refactoring with Verification
```
1. <leader>j "Refactor [file] to use modern Lua APIs"
2. AI makes changes
3. Automatically runs: stylua [file]
4. "Run any affected tests"
5. "Check for breaking changes"
```

#### Pattern 3: Debugging Workflow
```
1. <leader>j "Debug [issue]"
2. AI runs diagnostic commands
3. Analyzes output
4. Suggests fixes
5. Verifies fixes work
6. [Close Neovim]
7. [Later] <leader>jr → Continue debugging
```

#### Pattern 4: Documentation Generation
```
1. "Generate docs for all functions in [file]"
2. AI reads file structure
3. Creates documentation
4. "Add examples from tests" → reads test files
5. "Verify formatting" → runs stylua
```

### Safety Features

cmd_runner will **refuse** to run:
- `rm -rf /` or similar destructive commands
- Commands without explicit user request
- Unrecognized dangerous patterns

cmd_runner will **warn** before:
- Deleting files
- Modifying system configs
- Running sudo commands

### Integration with Other Plugins

#### With Telescope
```
• Action palette uses Telescope
• Buffer slash command uses Telescope picker
• File selection in chat context
```

#### With Mini.diff
```
• Inline changes show diffs
• Visual comparison of modifications
• Configured in your setup
```

#### With Gitsigns
```
• Can reference git hunks
• Stage/unstage integration
• Blame information available
```

### Performance Tips

1. **Lazy load chats** - Only restore when needed
2. **Use last chat** - Faster than browsing history
3. **Clear old chats** - Manually delete if too many
4. **Specific commands** - Clear prompts → faster execution
5. **Combine operations** - One prompt for multiple tasks

### Resources

| Resource | Location |
|----------|----------|
| Workspace Config | `.codecompanion` |
| cmd_runner Guide | `docs/cmd_runner_guide.md` |
| Architecture | `docs/codecompanion_architecture.md` |
| Summary | `docs/codecompanion_setup_summary.md` |
| Plugin Config | `lua/plugins/codecompanion.lua` |

### Quick Start

```vim
" 1. Start a chat
<leader>j

" 2. Try a simple command
"Show me all Lua files in the plugins directory"

" 3. Close Neovim, then reopen

" 4. Restore the chat
<leader>jr

" 5. Continue the conversation
"Now find the ones that mention 'telescope'"

" Done! You now understand history + cmd_runner
```

---

**Print this and keep it handy!** 🚀
