# CodeCompanion Documentation Index

## 📚 Complete Guide to CodeCompanion with History & cmd_runner

Welcome! This directory contains comprehensive documentation for using CodeCompanion in your Neovim configuration, with special focus on **chat history management** and **cmd_runner integration**.

---

## 🚀 Quick Start

**New to CodeCompanion?** Start here:
1. Read: [Cheat Sheet](codecompanion_cheatsheet.md) - Quick reference
2. Try: Press `<leader>j` and ask: "Show me all Lua files"
3. Close Neovim, press `<leader>jr` to restore

**Want to understand how it works?**
- Read: [Architecture](codecompanion_architecture.md) - Visual diagrams
- Read: [Setup Summary](codecompanion_setup_summary.md) - What we built

---

## 📖 Documentation Files

### 1. **[Cheat Sheet](codecompanion_cheatsheet.md)** ⭐ START HERE
   - **What**: Quick reference for keybindings and commands
   - **For**: Daily use, keep this handy
   - **Contains**:
     - Keybindings table
     - Common cmd_runner tasks
     - Example prompts
     - Pro tips
     - Troubleshooting

### 2. **[cmd_runner Guide](cmd_runner_guide.md)**
   - **What**: Complete guide to using cmd_runner tool
   - **For**: Understanding what commands you can run
   - **Contains**:
     - Command examples by category
     - Example conversations
     - History integration patterns
     - Safety features
     - Advanced workflows

### 3. **[Architecture Diagram](codecompanion_architecture.md)**
   - **What**: Visual explanation of how everything connects
   - **For**: Understanding the system design
   - **Contains**:
     - ASCII diagrams
     - Data flow visualization
     - History storage structure
     - Complete workflow examples
     - Integration patterns

### 4. **[Setup Summary](codecompanion_setup_summary.md)**
   - **What**: What we built and how to use it
   - **For**: Understanding your setup
   - **Contains**:
     - Files created/modified
     - Features implemented
     - Usage examples
     - Next steps

---

## 🎯 Use Cases

### I want to...

#### Run Commands
→ Read: [cmd_runner Guide](cmd_runner_guide.md)
→ Quick: Press `<leader>j` and ask "Run [command]"

#### Resume Previous Work
→ Quick: Press `<leader>jr` (restore) or `<leader>jl` (last)
→ Read: [Cheat Sheet](codecompanion_cheatsheet.md) - History section

#### Understand the System
→ Read: [Architecture](codecompanion_architecture.md)
→ See: Visual diagrams and workflows

#### Debug Something
→ Quick: Press `<leader>j` and ask "Help me debug [issue]"
→ Read: [Setup Summary](codecompanion_setup_summary.md) - Example workflows

#### Get Quick Help
→ Read: [Cheat Sheet](codecompanion_cheatsheet.md)
→ Use: Table of keybindings

---

## 🗂️ File Structure

```
~/.config/nvim/
├── .codecompanion                    # Workspace config (loaded by CodeCompanion)
├── lua/plugins/codecompanion.lua     # Plugin configuration
└── docs/
    ├── README.md                     # This file (index)
    ├── codecompanion_cheatsheet.md   # ⭐ Quick reference
    ├── cmd_runner_guide.md           # Command examples
    ├── codecompanion_architecture.md # Visual diagrams
    └── codecompanion_setup_summary.md # What we built
```

---

## 🔑 Key Concepts

### Chat History
- **What**: All your conversations are automatically saved
- **Why**: Never lose context, continue work across sessions
- **How**: Use `<leader>jr` to restore previous chats
- **Where**: Stored in `~/.local/share/nvim/codecompanion/`

### cmd_runner
- **What**: Tool that lets CodeCompanion run shell commands
- **Why**: Verify changes, run tests, explore codebase
- **How**: Just ask naturally: "Run the tests"
- **Safety**: Won't run destructive commands without confirmation

### Workspace File
- **What**: `.codecompanion` at repo root
- **Why**: Provides project context to the AI
- **Contains**: Structure, standards, common commands
- **Loaded**: Automatically by CodeCompanion

### Tools Integration
CodeCompanion has multiple tools that work together:
- `cmd_runner` - Run commands
- `read_file` - Read code
- `insert_edit_into_file` - Modify code
- `grep_search` - Search patterns
- `file_search` - Find files

---

## 📊 Reading Order by Goal

### Goal: Get Started Quickly
1. [Cheat Sheet](codecompanion_cheatsheet.md) - Keybindings
2. Try it: `<leader>j` → "Show me all Lua files"
3. [Setup Summary](codecompanion_setup_summary.md) - Quick examples

### Goal: Understand Completely
1. [Setup Summary](codecompanion_setup_summary.md) - Overview
2. [Architecture](codecompanion_architecture.md) - How it works
3. [cmd_runner Guide](cmd_runner_guide.md) - Deep dive
4. [Cheat Sheet](codecompanion_cheatsheet.md) - Reference

### Goal: Debug Issues
1. [Cheat Sheet](codecompanion_cheatsheet.md) - Troubleshooting section
2. [cmd_runner Guide](cmd_runner_guide.md) - Safety & errors
3. Ask CodeCompanion: `<leader>j` → "Help me debug [issue]"

### Goal: Master Advanced Workflows
1. [Architecture](codecompanion_architecture.md) - Workflow examples
2. [cmd_runner Guide](cmd_runner_guide.md) - Advanced workflows
3. Experiment with long debugging sessions + restore

---

## 🎓 Learning Path

### Level 1: Beginner (Day 1)
- [ ] Read: [Cheat Sheet](codecompanion_cheatsheet.md) keybindings
- [ ] Try: `<leader>j` and ask a simple question
- [ ] Learn: How to restore chats (`<leader>jr`)

### Level 2: Intermediate (Week 1)
- [ ] Read: [cmd_runner Guide](cmd_runner_guide.md) examples
- [ ] Try: Ask CodeCompanion to run tests
- [ ] Practice: Restore a previous chat and continue

### Level 3: Advanced (Month 1)
- [ ] Read: [Architecture](codecompanion_architecture.md) diagrams
- [ ] Try: Multi-step workflows (test → fix → verify)
- [ ] Master: Long debugging sessions across days

---

## 💡 Pro Tips

### Daily Workflow
```
Morning:
  <leader>jr          → Restore yesterday's work
  "Let's continue"    → Pick up where you left off

During Development:
  <leader>j           → Toggle chat for quick questions
  "Run tests"         → Verify changes
  "Check formatting"  → Ensure style compliance

End of Day:
  [close Neovim]      → History auto-saves, no action needed
```

### Best Practices
1. **Start with descriptive messages** - "Debug X" not just "help"
2. **Let history accumulate** - Long sessions = better context
3. **Use workspace context** - Reference coding standards
4. **Combine tools** - Let AI read, modify, and verify
5. **Trust the safety features** - cmd_runner won't do dangerous things

---

## 🛠️ Configuration Files

### Your Current Setup
- **Workspace**: `.codecompanion` (9.1K)
- **Config**: `lua/plugins/codecompanion.lua`
- **Keybindings**:
  - `<leader>j` - Toggle chat
  - `<leader>jl` - Last chat (NEW!)
  - `<leader>jr` - Restore chat (NEW!)
  - `<C-a>` - Action palette

### Available Adapters
- `copilot_claude45` - Default for chat (Claude Sonnet 4.5)
- `copilot_gpt` - Default for inline (GPT-5.1)
- `copilot_gemini25pro` - Gemini 2.5 Pro
- And more... (see `.codecompanion` for full list)

---

## ❓ FAQ

**Q: Where is chat history stored?**
A: `~/.local/share/nvim/codecompanion/` (persists across sessions)

**Q: How do I find old chats?**
A: Press `<leader>jr` to open a picker with all saved chats

**Q: Can CodeCompanion run any command?**
A: Yes, but with safety restrictions (no `rm -rf /`, etc.)

**Q: Do I need to save chats manually?**
A: No, all chats auto-save continuously

**Q: What if I close Neovim mid-conversation?**
A: Just restore the chat later with `<leader>jr`

**Q: Can I delete old chats?**
A: Yes, manually delete files from `~/.local/share/nvim/codecompanion/`

**Q: Does history include command outputs?**
A: Yes! All cmd_runner outputs are preserved in chat history

**Q: Can I use this across different projects?**
A: Yes, history can be workspace-specific via the `.codecompanion` file

---

## 🔗 Quick Links

### Documentation
- [Cheat Sheet](codecompanion_cheatsheet.md)
- [cmd_runner Guide](cmd_runner_guide.md)
- [Architecture](codecompanion_architecture.md)
- [Setup Summary](codecompanion_setup_summary.md)

### Configuration
- Workspace: `~/.config/nvim/.codecompanion`
- Plugin: `~/.config/nvim/lua/plugins/codecompanion.lua`
- History: `~/.local/share/nvim/codecompanion/`

### External
- [CodeCompanion GitHub](https://github.com/olimorris/codecompanion.nvim)
- [Neovim Docs](https://neovim.io/doc/)
- Your Config: `~/.config/nvim/`

---

## 🎉 You're All Set!

Everything is configured and documented. Here's your first task:

1. Press `<leader>j`
2. Ask: "Explain what tools you have available"
3. Close Neovim
4. Reopen and press `<leader>jr`
5. Select the chat and ask: "What did we discuss?"

**Welcome to persistent, context-aware AI assistance!** 🚀

---

*Last updated: December 10, 2024*
*Created for: ~/.config/nvim configuration*
*CodeCompanion version: Latest with tools enabled*
