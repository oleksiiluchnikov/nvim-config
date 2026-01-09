# CodeCompanion Architecture: History + cmd_runner

## Visual Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         YOUR NEOVIM CONFIG                               │
│                    ~/.config/nvim/.codecompanion                         │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                    WORKSPACE CONTEXT                           │    │
│  │  • Project structure                                           │    │
│  │  • Coding standards                                            │    │
│  │  • Available adapters (GPT, Claude, Gemini)                    │    │
│  │  • Common commands & workflows                                 │    │
│  │  • Integration patterns                                        │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                   │                                      │
│                                   ▼                                      │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                   CODECOMPANION PLUGIN                         │    │
│  │              lua/plugins/codecompanion.lua                     │    │
│  │                                                                │    │
│  │  Keybindings:                                                 │    │
│  │    <leader>j   → Toggle chat                                  │    │
│  │    <leader>jl  → Last chat        ┐                          │    │
│  │    <leader>jr  → Restore chat     │ NEW!                     │    │
│  │    <C-a>       → Action palette   ┘                          │    │
│  │                                                                │    │
│  │  Tools Enabled:                                               │    │
│  │    ✅ cmd_runner                                              │    │
│  │    ✅ read_file                                               │    │
│  │    ✅ insert_edit_into_file                                   │    │
│  │    ✅ grep_search                                             │    │
│  │    ✅ file_search                                             │    │
│  └────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘

                                   │
                                   ▼

┌─────────────────────────────────────────────────────────────────────────┐
│                    CODECOMPANION RUNTIME                                 │
│                                                                          │
│  ┌──────────────────┐         ┌──────────────────┐                     │
│  │  CHAT BUFFER     │         │  HISTORY STORE   │                     │
│  │  (Current)       │◄────────┤  ~/.local/share/ │                     │
│  │                  │  Load   │  nvim/           │                     │
│  │  User: "Run..."  │  ──────►│  codecompanion/  │                     │
│  │  AI: [response]  │  Save   │                  │                     │
│  │  Tool: cmd_runner│         │  • chat_1.json   │                     │
│  │  Output: ...     │         │  • chat_2.json   │                     │
│  └──────────────────┘         │  • chat_3.json   │                     │
│           │                   └──────────────────┘                     │
│           │ Uses Tools                                                  │
│           ▼                                                             │
│  ┌─────────────────────────────────────────────────────────────┐       │
│  │                      TOOL EXECUTOR                          │       │
│  │                                                             │       │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │       │
│  │  │ cmd_runner  │  │  read_file   │  │ insert_edit_... │  │       │
│  │  │             │  │              │  │                 │  │       │
│  │  │ Runs shell  │  │ Reads code   │  │ Modifies code   │  │       │
│  │  │ commands    │  │              │  │                 │  │       │
│  │  └─────────────┘  └──────────────┘  └─────────────────┘  │       │
│  │         │                 │                    │           │       │
│  └─────────┼─────────────────┼────────────────────┼───────────┘       │
│            │                 │                    │                   │
└────────────┼─────────────────┼────────────────────┼───────────────────┘
             │                 │                    │
             ▼                 ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        YOUR SYSTEM                                       │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐     │
│  │   SHELL          │  │   FILE SYSTEM    │  │   FILE SYSTEM    │     │
│  │   /bin/zsh       │  │   Read files     │  │   Write files    │     │
│  │                  │  │                  │  │                  │     │
│  │  $ stylua ...    │  │  config/         │  │  config/         │     │
│  │  $ busted        │  │  plugins/        │  │  plugins/        │     │
│  │  $ git status    │  │  docs/           │  │  docs/           │     │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘     │
│            │                                                            │
│            ▼                                                            │
│  ┌─────────────────────────────────────────────────────────────┐       │
│  │                    COMMAND OUTPUT                           │       │
│  │  Returns to CodeCompanion as context                        │       │
│  └─────────────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────────┘
```

## Workflow: Complete Session Example

```
┌──────────────────────────────────────────────────────────────────────────┐
│ SESSION 1: Initial Debugging (Day 1)                                    │
└──────────────────────────────────────────────────────────────────────────┘

  You: <leader>j                    ┌─────────────────────────────┐
       "Run lua tests"              │  NEW CHAT CREATED           │
                                    │  ID: chat_abc123            │
  AI:  Using cmd_runner             └─────────────────────────────┘
       $ busted lua/tests/                     │
       Output: 3 tests failed                  ▼
                                    ┌─────────────────────────────┐
  You: "Let's fix test 1"           │  HISTORY SAVED              │
  AI:  Reading test file...         │  • User messages            │
       Making changes...             │  • AI responses             │
       [insert_edit_into_file]       │  • cmd_runner outputs       │
                                    │  • Tool executions          │
  You: [close Neovim]               └─────────────────────────────┘
                                               │
                                               │ Persisted
                                               ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ SESSION 2: Continue Debugging (Day 2 or later)                          │
└──────────────────────────────────────────────────────────────────────────┘

  You: [open Neovim]
       <leader>jr                    ┌─────────────────────────────┐
                                    │  RESTORE PICKER             │
  Picker shows:                     │  • "Debug tests" (Day 1)    │◄─┐
    • "Debug tests" (yesterday)     │  • "Add plugin" (3 days ago)│  │
    • "Add plugin" (3 days ago)     │  • "Refactor utils" (week)  │  │
    • "Refactor utils" (last week)  └─────────────────────────────┘  │
                                                                      │
  You: [select "Debug tests"]            Loads Full Context ────────┘
                                         Including:
  AI:  "Welcome back! We were              • Previous messages
       debugging test failures.            • Command history
       Last time we fixed 1 of 3           • Tool outputs
       failures. Shall I check             • Error messages
       current status?"                    • Code changes made

  You: "Yes, run tests again"

  AI:  Using cmd_runner             ┌─────────────────────────────┐
       $ busted lua/tests/           │  CONTEXT AVAILABLE:         │
       Output: 2 tests failed        │                             │
       (1 was fixed!)                │  Previous cmd_runner:       │
                                    │  $ busted lua/tests/        │
  You: "Great! Let's fix the next"  │  Output: 3 tests failed     │
                                    │                             │
  AI:  Based on previous patterns...│  Previous fixes:            │
       [Applies similar fix]         │  • test_1.lua modified      │
                                    │  • Pattern identified       │
       $ busted lua/tests/           └─────────────────────────────┘
       Output: All tests passed! ✅

  [Session continues with full context...]
```

## Data Flow Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                          USER INTERACTION                              │
└────────────────────────────────────────────────────────────────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
           ┌────────────┐  ┌────────────┐  ┌────────────┐
           │ New Chat   │  │ Last Chat  │  │ Restore    │
           │ <leader>j  │  │ <leader>jl │  │ <leader>jr │
           └────────────┘  └────────────┘  └────────────┘
                    │              │              │
                    └──────────────┼──────────────┘
                                   ▼
                    ┌──────────────────────────┐
                    │    CODECOMPANION CHAT    │
                    │                          │
                    │  Workspace Context ✓     │
                    │  Chat History ✓          │
                    │  Tools Enabled ✓         │
                    └──────────────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
              ▼                    ▼                    ▼
    ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
    │  cmd_runner     │  │  File Tools     │  │  Search Tools   │
    │                 │  │                 │  │                 │
    │  • Run commands │  │  • read_file    │  │  • grep_search  │
    │  • Get output   │  │  • edit_file    │  │  • file_search  │
    │  • Return to AI │  │  • create_file  │  │  • list_usages  │
    └─────────────────┘  └─────────────────┘  └─────────────────┘
              │                    │                    │
              └────────────────────┼────────────────────┘
                                   ▼
                    ┌──────────────────────────┐
                    │    RESULTS AGGREGATED    │
                    │                          │
                    │  • Command outputs       │
                    │  • File contents         │
                    │  • Search results        │
                    │  • Modifications made    │
                    └──────────────────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────┐
                    │    AI PROCESSES &        │
                    │    RESPONDS              │
                    │                          │
                    │  • Analyzes results      │
                    │  • Suggests next steps   │
                    │  • Makes changes         │
                    │  • Runs verification     │
                    └──────────────────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────┐
                    │    SAVED TO HISTORY      │
                    │                          │
                    │  All interactions,       │
                    │  commands, and outputs   │
                    │  preserved for later     │
                    └──────────────────────────┘
```

## History Storage Structure

```
~/.local/share/nvim/codecompanion/
├── chats/
│   ├── chat_20231210_143022.json    ← Session 1 (with cmd_runner history)
│   ├── chat_20231210_153045.json    ← Session 2 (with cmd_runner history)
│   └── chat_20231209_091234.json    ← Session 3 (with cmd_runner history)
│
└── metadata.json                     ← Index of all chats

Each chat file contains:
{
  "id": "chat_20231210_143022",
  "created_at": "2023-12-10T14:30:22Z",
  "updated_at": "2023-12-10T14:45:10Z",
  "messages": [
    {
      "role": "user",
      "content": "Run the tests"
    },
    {
      "role": "assistant",
      "content": "I'll run the tests using cmd_runner...",
      "tool_calls": [
        {
          "type": "cmd_runner",
          "cmd": "busted lua/tests/",
          "output": "3 tests failed...",  ← Preserved!
          "exit_code": 1
        }
      ]
    },
    ...
  ],
  "workspace": "~/.config/nvim"
}
```

## Key Benefits Visualization

```
┌────────────────────────────────────────────────────────────────────────┐
│                     WITHOUT HISTORY + cmd_runner                       │
└────────────────────────────────────────────────────────────────────────┘

  Session 1:                       Session 2 (later):
  ┌─────────────┐                 ┌─────────────┐
  │ "Run tests" │                 │ "Run tests" │ ◄─ Starting from scratch
  │ Output: ... │                 │ Output: ... │    No context
  │ "Fix error" │                 │ "What error?"│   AI doesn't remember
  │ [changes]   │                 │             │
  └─────────────┘                 └─────────────┘
       ❌ Context lost                 ❌ No previous knowledge

┌────────────────────────────────────────────────────────────────────────┐
│                      WITH HISTORY + cmd_runner                         │
└────────────────────────────────────────────────────────────────────────┘

  Session 1:                       Session 2 (restored):
  ┌─────────────┐                 ┌─────────────────────────┐
  │ "Run tests" │────────────────►│ "Continue debugging"    │
  │ Output: ... │     Saved       │ ✅ Knows previous tests │
  │ "Fix error" │     Context     │ ✅ Sees past errors     │
  │ [changes]   │                 │ ✅ Remembers fixes tried│
  └─────────────┘                 │ ✅ Suggests next step   │
       ✅ Full history             └─────────────────────────┘
          preserved                     ✅ Intelligent continuation
```

## Integration Example: Complete Workflow

```
USER TASK: "Fix all test failures in my Neovim config"

┌─────────────────────────────────────────────────────────────────────┐
│ Step 1: Initial Assessment                                          │
│ ─────────────────────────────────────────────────────────────────   │
│ You: <leader>j "Run all tests and show me what's failing"          │
│                                                                     │
│ AI uses:                                                            │
│   1. workspace context → knows test command is `busted`            │
│   2. cmd_runner → $ busted lua/tests/                              │
│   3. Analyzes output                                               │
│                                                                     │
│ Result: "Found 3 failing tests. Let's fix them one by one."       │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 2: Fix First Test                                              │
│ ─────────────────────────────────────────────────────────────────   │
│ AI uses:                                                            │
│   1. read_file → check failing test                                │
│   2. grep_search → find related code                               │
│   3. insert_edit_into_file → make fix                              │
│   4. cmd_runner → $ busted lua/tests/test_1_spec.lua               │
│                                                                     │
│ Result: "Fixed! 2 tests remaining."                                │
│ Status: All saved to history ✓                                     │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
                    [Close Neovim - Go for coffee ☕]
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 3: Continue Later (History Restored)                           │
│ ─────────────────────────────────────────────────────────────────   │
│ You: <leader>jr [select "Fix test failures"]                       │
│                                                                     │
│ AI: "Welcome back! We fixed test_1. Still have test_2 and test_3  │
│      failing. Shall I continue?"                                   │
│                                                                     │
│ Context Available:                                                 │
│   ✓ Previous test output                                           │
│   ✓ First fix applied                                              │
│   ✓ Pattern identified                                             │
│   ✓ Commands run                                                   │
│                                                                     │
│ AI continues fixing remaining tests with full context...           │
└─────────────────────────────────────────────────────────────────────┘
```

This architecture enables **persistent, context-aware AI assistance** that remembers your work and can continue where you left off!
