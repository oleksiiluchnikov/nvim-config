# AGENTS.md

This document provides guidelines for automation agents operating within this repository. Follow the instructions below for consistent, efficient, and complaint-free operations.

---

## Build, Lint, and Test Commands

### Build Commands
- **Node.js-based tools:**
  ```bash
  npm install
  npm run build
  ```

- **Python-based tools (e.g., VectorCode):**
  ```bash
  pipx install vectorcode
  pipx upgrade vectorcode
  ```

- **Treesitter setup:**
  ```bash
  nvim --headless -c 'TSUpdate' +qa
  ```

- **Make-based builds:**
  ```bash
  make
  ```

- **Markdown Preview:**
  ```bash
  make build
  ```

### Linting Commands
- **ESLint (JavaScript/TypeScript):**
  ```bash
  eslint . --ext .js,.ts,.jsx,.tsx
  ```

- **Stylelint (CSS/SCSS):**
  ```bash
  stylelint '**/*.{css,scss}'
  ```

### Test Commands
- **Run all tests:**
  ```bash
  npm test
  make test
  ```

- **Run a single test:**
  ```bash
  npm test -- --testPathPattern '<test-name>'
  ```

For Lua-based tests:
- **Command:** `nvim --headless -c "PlenaryBustedDirectory <test-path>" +qa`

---

## Code Style Guidelines

### General
- Use **4 spaces** for indentation.
- Line width limited to **80 characters**.
- Use Unix line endings.
- Prefer **single quotes** for strings.
- Parentheses for function calls are mandatory.

### Formatting
- Run `stylua` for enforcing style:
  ```bash
  stylua .
  ```

`stylua.toml` configuration:
```toml
column_width = 80
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 4
quote_style = "ForceSingle"
call_parentheses = "Always"
[sources_requires]
enabled = false
```

### Imports
- Sort imports alphabetically (even when `stylua` doesn’t require it).

### Naming Conventions
- Files and directories:
  - Use `snake_case` for names.
- Functions:
  - Use `camelCase` for helper/util functions.
  - Use `PascalCase` for exported modules/classes.

### Error Handling
- Use `pcall` for Lua runtime errors.
- Always log meaningful error messages for agent correlation.

---

## Neovim-Specific Details

### Keymaps
- `<leader>ck`: Executes CodeCompanionActions.
- `<leader>cc`: Toggles CodeCompanionChat.

### Plugin Management
- Use **Lazy.nvim** for plugin setups. Reload plugins with:
  ```bash
  :Lazy reload <plugin_name>
  ```

### Debugging CodeCompanion
- Default log-level: **INFO**
- To trace errors effectively:
  ```lua
  require('codecompanion').setup{ log_level = 'TRACE' }
  ```
  Logs are available in `$HOME/.local/share/nvim/logs/`.

---

## Additional Notes
- Always use the appropriate adapter configurations detailed in `init.lua` for Neovim setups.
- Preferred completion engine: `nvim-cmp`
- If modifying Treesitter configurations, ensure backward compatibility with at least two Neovim versions.

Feel free to update this document as the repository evolves.