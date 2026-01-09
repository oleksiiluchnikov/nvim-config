# CodeCompanion Configuration Audit

## Executive Summary

Your CodeCompanion configuration is missing several important modules that should be connected to `opts`. This document outlines what's missing and how to extend your arsenal of tools and prompts.

---

## ❌ Missing Configurations

### 1. **Missing in `opts` (Top-Level)**

According to the official config, these should be in the top-level `opts` object but are missing:

```lua
opts = {
    system_prompt = require('plugins.codecompanion.system-prompt'), -- ✅ You have this
    
    -- ❌ MISSING: Log level configuration
    log_level = "INFO", -- or "DEBUG", "TRACE"
    
    -- ❌ MISSING: Language setting
    language = "English",
    
    -- ❌ MISSING: Send code setting
    send_code = true,
}
```

### 2. **Missing Slash Commands in Chat Strategy**

You only have 3 slash commands configured. The defaults include many more:

**You Have:**
- `/buffer`
- `/fetch`
- `/image`

**Missing Slash Commands:**
- `/compact` - Clear chat history with summary
- `/file` - Insert a file into chat
- `/help` - Insert Neovim help content
- `/now` - Insert current timestamp
- `/quickfix` - Insert quickfix entries
- `/rules` - Insert rules from CLAUDE.md, etc.
- `/symbols` - Insert code symbols
- `/terminal` - Insert terminal output

### 3. **Missing Chat Variables**

Variables allow you to reference context in prompts. You're missing all of them:

**Missing Variables:**
- `#buffer` - Reference current buffer
- `#chat` - Reference chat buffer
- `#clipboard` - Reference clipboard
- `#diagnostics` - Reference LSP diagnostics
- `#editor` - Reference editor info
- `#lsp` - Reference LSP symbols
- `#viewport` - Reference visible code

### 4. **Missing Tool Groups**

Tool groups bundle related tools together. The defaults include:

**Available Groups:**
- `full_stack_dev` - Complete development toolset ⭐
- `files` - File operations only

You can enable a group instead of individual tools!

### 5. **Missing Tools**

**You Have:**
- read_file
- create_file
- insert_edit_into_file
- grep_search
- file_search
- cmd_runner
- list_code_usages
- get_changed_files
- delete_file

**Missing Tools:**
- `fetch_webpage` - Fetch and read web content (uses Jina)
- `web_search` - Search the web (uses Tavily)
- `memory` - Store/retrieve info across conversations
- `next_edit_suggestion` - Jump to next edit position

### 6. **Missing Tool Options**

Some of your tools are missing important configuration options:

```lua
-- Example: read_file should have approval settings
['read_file'] = {
    opts = {
        require_approval_before = true,  -- ❌ Missing
        require_cmd_approval = true,     -- ❌ Missing
    },
}
```

### 7. **Missing Inline Strategy Configuration**

You have `inline` strategy but it's minimally configured:

```lua
inline = {
    adapter = vim.g.codecompanion_initial_adapter,
    -- ❌ Missing keymaps for accepting/rejecting inline suggestions
    -- ❌ Missing variables
}
```

### 8. **Missing CMD Strategy Configuration**

Your `cmd` strategy has no options:

```lua
cmd = {
    adapter = vim.g.codecompanion_initial_adapter,
    -- ❌ Missing system_prompt
    -- ❌ Missing opts
}
```

### 9. **Missing Prompt Library Configuration**

You have `prompt_library` pointing to your custom prompts, but missing:

```lua
prompt_library = {
    -- Your custom prompts ✅
    require('plugins.codecompanion.prompt_library').get_prompts(),
    
    -- ❌ Missing markdown directory configuration
    markdown = {
        dirs = {}, -- Add paths to markdown prompt libraries
    },
}
```

### 10. **Missing Rules Configuration**

Rules automatically load project context files (CLAUDE.md, .cursorrules, etc.):

```lua
-- ❌ COMPLETELY MISSING
rules = {
    default = {
        description = "Collection of common files for all projects",
        files = {
            ".clinerules",
            ".cursorrules",
            ".goosehints",
            ".rules",
            ".windsurfrules",
            ".github/copilot-instructions.md",
            "AGENT.md",
            "AGENTS.md",
            { path = "CLAUDE.md", parser = "claude" },
            { path = "CLAUDE.local.md", parser = "claude" },
        },
        is_preset = true,
    },
}
```

### 11. **Missing Background Interaction**

Background interactions run automatically (like generating chat titles):

```lua
-- ❌ COMPLETELY MISSING
interactions = {
    background = {
        adapter = {
            name = "copilot",
            model = "gpt-4.1",
        },
        chat = {
            callbacks = {
                ["on_ready"] = {
                    actions = {
                        "interactions.background.builtin.chat_make_title",
                    },
                    enabled = true,
                },
            },
        },
    },
}
```

---

## ✅ Recommended Full Configuration

Here's what your complete configuration should look like:

### Top-Level Structure

```lua
require('codecompanion').setup({
    -- 1. Global Options
    opts = {
        system_prompt = require('plugins.codecompanion.system-prompt'),
        log_level = "INFO",
        language = "English",
        send_code = true,
    },

    -- 2. Strategies (chat, inline, cmd)
    strategies = { ... },
    
    -- 3. Display Settings
    display = { ... },
    
    -- 4. Adapters
    adapters = { ... },
    
    -- 5. Prompt Library
    prompt_library = { ... },
    
    -- 6. Rules (NEW - should add)
    rules = { ... },
})
```

---

## 🚀 Quick Wins - Priority Additions

### Priority 1: Enable Full Stack Dev Tool Group

Instead of enabling individual tools, use the pre-configured group:

```lua
strategies = {
    chat = {
        adapter = vim.g.codecompanion_initial_adapter,
        
        tools = {
            opts = {
                auto_submit_errors = true,
                auto_submit_success = true,
            },
            -- Use the full_stack_dev group instead of individual tools
            groups = {
                ["full_stack_dev"] = {
                    enabled = true,
                },
            },
        },
    },
}
```

### Priority 2: Add Missing Slash Commands

```lua
slash_commands = {
    ['buffer'] = { keymaps = { modes = { i = '<C-b>' } }, opts = { provider = 'telescope' } },
    ['fetch'] = { keymaps = { modes = { i = '<C-f>' } } },
    ['image'] = { keymaps = { modes = { i = '<C-i>' } }, opts = { dirs = { '~/Documents/Screenshots' } } },
    
    -- Add these:
    ['file'] = { keymaps = { modes = { i = '<C-p>' } }, opts = { provider = 'telescope' } },
    ['help'] = { opts = { provider = 'telescope' } },
    ['rules'] = {},
    ['symbols'] = { opts = { provider = 'telescope' } },
},
```

### Priority 3: Add Rules for Auto-Context Loading

```lua
rules = {
    default = {
        description = "Project context files",
        files = {
            "CLAUDE.md",
            ".cursorrules",
            ".github/copilot-instructions.md",
        },
        is_preset = true,
    },
}
```

### Priority 4: Add Web Tools

```lua
tools = {
    -- ... existing tools ...
    
    ['fetch_webpage'] = {
        opts = {
            adapter = "jina",
        },
    },
    ['web_search'] = {
        opts = {
            adapter = "tavily",
            opts = {
                search_depth = "advanced",
                max_results = 5,
            },
        },
    },
}
```

---

## 📊 Configuration Coverage

| Module | Status | Priority |
|--------|--------|----------|
| **opts.system_prompt** | ✅ Added | - |
| **opts.log_level** | ❌ Missing | Medium |
| **opts.language** | ❌ Missing | Low |
| **strategies.chat.tools** | ⚠️ Partial | High |
| **strategies.chat.slash_commands** | ⚠️ Partial | High |
| **strategies.chat.variables** | ❌ Missing | Medium |
| **strategies.inline** | ⚠️ Minimal | Medium |
| **strategies.cmd** | ⚠️ Minimal | Low |
| **rules** | ❌ Missing | High |
| **background interactions** | ❌ Missing | Low |
| **prompt_library.markdown** | ❌ Missing | Low |

---

## 🎯 Next Steps

1. **Immediate**: Enable `full_stack_dev` tool group
2. **High Priority**: Add rules configuration for auto-context
3. **High Priority**: Add missing slash commands (`/file`, `/rules`, `/symbols`)
4. **Medium Priority**: Configure web tools (`fetch_webpage`, `web_search`)
5. **Optional**: Add background interactions for auto-titles
6. **Optional**: Add variables support

---

## 📝 Notes

- The `full_stack_dev` group includes all the tools you manually configured
- Rules automatically load project context without manual `/file` commands
- Web tools require API keys (Jina for fetch, Tavily for search)
- Background interactions use additional API calls

---

**Generated**: 2026-01-08
**Based On**: CodeCompanion v13.x config.lua
