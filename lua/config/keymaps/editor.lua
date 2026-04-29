--[[
    Keymaps: Editor
    Window management, project navigation, and general editor bindings.
--]]

-- Window Focus (Fast switching)
vim.keymap.set('n', '<Left>', '<C-w>h', { desc = 'Focus Left' })
vim.keymap.set('n', '<Right>', '<C-w>l', { desc = 'Focus Right' })

local function get_visual_selection_text()
    local mode = vim.fn.visualmode()
    if mode == '\22' then
        return nil, 'Blockwise visual selection not supported.'
    end

    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local srow = start_pos[2] - 1
    local scol = start_pos[3] - 1
    local erow = end_pos[2] - 1
    local ecol = end_pos[3]

    if srow > erow or (srow == erow and scol > ecol) then
        srow, erow = erow, srow
        scol, ecol = end_pos[3] - 1, start_pos[3]
    end

    if mode == 'V' then
        local lines = vim.api.nvim_buf_get_lines(0, srow, erow + 1, false)
        return table.concat(lines, '\n')
    end

    local lines = vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {})
    return table.concat(lines, '\n')
end

local function create_obsidian_clipboard_note_from_selection()
    vim.notify('leader y fired', vim.log.levels.INFO)

    local text, err = get_visual_selection_text()
    if not text or text == '' then
        vim.notify(
            err or 'No visual selection to send to Obsidian.',
            vim.log.levels.WARN
        )
        return
    end

    vim.notify(
        string.format('selection captured (%d chars)', #text),
        vim.log.levels.INFO
    )

    vim.fn.setreg('+', text)
    vim.fn.setreg('*', text)

    local raycast_url =
        'raycast://extensions/marcjulian/obsidian/createClipboardNoteCommand'
    local job = vim.fn.jobstart({ 'open', raycast_url }, { detach = true })

    if job <= 0 then
        vim.notify('Failed to open Raycast Obsidian command.', vim.log.levels.ERROR)
        return
    end

    vim.notify('Sent selection to Obsidian clipboard note.', vim.log.levels.INFO)
end

-- String Preview
vim.keymap.set('n', '<leader>es', function()
    require('config.lib.string_preview').edit_string()
end, { desc = 'Utils: Edit long string in floating window' })

-- Change Directory
vim.keymap.set('n', '<leader>cd', function()
    local root = vim.fn.expand('%:p:h')
    -- Remove oil: prefix from oil.nvim if it exists
    root = root:gsub('^oil://', '')

    if root and root ~= '' then
        vim.cmd('cd ' .. vim.fn.fnameescape(root))
        vim.notify('Changed directory to: ' .. root, vim.log.levels.INFO, {
            timeout = 1500,
        })
    else
        vim.notify(
            'Could not determine a valid root directory.',
            vim.log.levels.WARN,
            {
                timeout = 1500,
            }
        )
    end
end, { desc = 'Project: Change to file directory' })

-- Make Test
vim.keymap.set('n', '<leader>m', function()
    vim.cmd('!make test')
end, { desc = 'Project: Run make test' })

-- URL to Markdown Link
vim.keymap.set('n', '<localleader>at', function()
    require('config.lib.url_title').add_title_to_url()
end, { desc = 'Add title to URL' })

vim.keymap.set('x', '<leader>y', create_obsidian_clipboard_note_from_selection, {
    desc = 'Obsidian: Create clipboard note from selection',
    silent = true,
})

-- ============================================================
-- Helpers for Marksman missing-wikilink handling (used by gf)
-- ============================================================

--- Return the expanded vault root from vault.config, or nil.
--- Falls back to ~/knowledge when vault.config is unavailable.
--- @return string|nil
local function get_vault_root()
    local ok, vault_config = pcall(require, 'vault.config')
    if ok and vault_config.options and vault_config.options.root then
        return vim.fn.expand(vault_config.options.root):gsub('/$', '')
    end
    -- Fallback: use the hardcoded vault location
    local fallback = vim.fn.expand('~/knowledge')
    if vim.fn.isdirectory(fallback) == 1 then
        return fallback
    end
    return nil
end

--- Notify all running Marksman clients that a new file was created so they
--- re-index immediately without requiring a manual :LspRestart.
--- @param filepath string absolute path to the newly-created file
local function notify_marksman_file_created(filepath)
    local uri = vim.uri_from_fname(filepath)
    for _, client in ipairs(vim.lsp.get_clients({ name = 'marksman' })) do
        client:notify('workspace/didCreateFiles', {
            files = { { uri = uri } },
        })
    end
end

--- Extract a `[[wikilink]]` token that the cursor sits inside on the current
--- line.  Returns the inner text (without the `[[` / `]]` delimiters), or nil
--- when the cursor is not inside a wikilink.
--- @return string|nil
local function extract_wikilink_at_cursor()
    local line = vim.api.nvim_get_current_line()
    -- col is 0-indexed; convert to 1-indexed for string operations
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1

    local search_start = 1
    while true do
        local link_start, link_end, inner =
            line:find('%[%[([^%]]+)%]%]', search_start)
        if not link_start then
            break
        end
        -- +2 / -2 because the delimiters are two characters each
        if col >= link_start and col <= link_end then
            return inner
        end
        search_start = link_end + 1
    end
    return nil
end

--- Inspect Marksman diagnostics at the current cursor line and extract the
--- missing wikilink reference.  Marksman reports broken wikilinks in its
--- diagnostic message as the unresolved title/slug; we also read the token
--- under the cursor as a reliable fallback.
--- @return string|nil  the bare wikilink slug (no [[ ]] delimiters)
local function extract_wikilink_from_marksman_diagnostic()
    local bufnr = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed

    local diags = vim.diagnostic.get(bufnr, { lnum = row })
    for _, diag in ipairs(diags) do
        -- Marksman diagnostic source is "marksman"
        if diag.source == 'marksman' then
            -- Message formats observed from Marksman:
            --   "No note with title or path: 'missing-note'"
            --   "Cannot resolve link to 'path/to/missing-note'"
            local inner = diag.message:match('\'([^\']+)\'')
                or diag.message:match('"([^"]+)"')
            if inner then
                return inner
            end
        end
    end

    -- No diagnostic matched; fall back to the [[wikilink]] under the cursor
    return extract_wikilink_at_cursor()
end

--- Core handler: given a bare wikilink slug (e.g. "missing-note" or
--- "subfolder/missing-note"), create the note file inside the vault (if it
--- does not already exist), open it, and notify Marksman so it re-indexes.
--- @param wikilink string  bare slug without [[ ]] delimiters
local function open_or_create_wikilink_note(wikilink)
    local vault_root = get_vault_root()
    if not vault_root then
        vim.notify(
            'gf: Cannot determine vault root for wikilink creation.',
            vim.log.levels.ERROR
        )
        return
    end

    -- Build the absolute path; append .md when the slug has no extension
    local rel_path = wikilink:match('%.[^/]+$') and wikilink
        or (wikilink .. '.md')
    local abs_path = vault_root .. '/' .. rel_path

    -- Ensure parent directory exists
    local parent_dir = vim.fn.fnamemodify(abs_path, ':h')
    if vim.fn.isdirectory(parent_dir) == 0 then
        local mkdir_ok = vim.fn.mkdir(parent_dir, 'p')
        if mkdir_ok == 0 then
            vim.notify(
                'gf: Failed to create directory: ' .. parent_dir,
                vim.log.levels.ERROR
            )
            return
        end
    end

    -- Create the file if it does not yet exist
    local file_existed = vim.fn.filereadable(abs_path) == 1
    if not file_existed then
        -- Seed the file with a minimal H1 heading derived from the slug
        local title = vim.fn.fnamemodify(wikilink, ':t'):gsub('%-', ' ')
        local seed_lines = { '# ' .. title, '' }
        local write_ok = vim.fn.writefile(seed_lines, abs_path)
        if write_ok ~= 0 then
            vim.notify(
                'gf: Failed to write file: ' .. abs_path,
                vim.log.levels.ERROR
            )
            return
        end

        -- Let Marksman know immediately so it picks up the new note
        notify_marksman_file_created(abs_path)

        vim.notify('gf: Created note: ' .. abs_path, vim.log.levels.INFO)
    end

    vim.cmd('edit ' .. vim.fn.fnameescape(abs_path))
end

-- Smart gf: open file or jump to plugin source in lazy.nvim,
-- with added support for Marksman broken-wikilink diagnostics.
vim.keymap.set('n', 'gf', function()
    -- 1. Standard file under cursor ----------------------------------------
    local filepath = vim.fn.expand('<cfile>')
    if vim.fn.filereadable(filepath) == 1 then
        vim.cmd('edit ' .. filepath)
        return
    end

    -- 2. Marksman missing-wikilink diagnostic / [[wikilink]] under cursor ---
    --    Active only in markdown buffers so we don't interfere elsewhere.
    if vim.bo.filetype == 'markdown' then
        local wikilink = extract_wikilink_from_marksman_diagnostic()
        if wikilink then
            open_or_create_wikilink_note(wikilink)
            return
        end
    end

    -- 3. Plugin-slug navigation inside the nvim config plugins/ directory ---
    if
        not vim.fn
            .expand('%:p')
            :match(vim.pesc(vim.fn.stdpath('config') .. '/lua/plugins/'))
    then
        return
    end

    local plugin_slug = nil
    local line = vim.api.nvim_get_current_line()

    for word in line:gmatch('%S+') do
        local match = word:match('^[\'"]?([%w_-]+/[%w_-]+%.%a+)[\'"]?,?$')
        if match then
            plugin_slug = match
            break
        end
    end

    if not plugin_slug then
        vim.notify(
            'No plugin slug found under cursor. Expected format: "author/plugin.nvim".',
            vim.log.levels.WARN
        )
        return
    end

    local plugin_name = plugin_slug:match('/([%w_-]+%.%w+)$')
    if not plugin_name then
        vim.notify(
            'Could not extract plugin name from slug: ' .. plugin_slug,
            vim.log.levels.ERROR
        )
        return
    end

    local full_path = string.format(
        '%s/.local/share/nvim/lazy/%s',
        vim.fn.expand('~'),
        plugin_name
    )

    if vim.fn.isdirectory(full_path) == 1 then
        vim.cmd('edit ' .. full_path)
    else
        vim.notify(
            'Plugin directory not found: ' .. full_path,
            vim.log.levels.ERROR
        )
    end
end)
