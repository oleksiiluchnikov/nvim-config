local M = {}

-- ============================================
-- Configuration
-- ============================================

--- @class CreateNoteConfig
--- @field max_title_length number
--- @field show_success_notification boolean
--- @field file_extension string
--- @field prompt_for_name boolean

--- @type CreateNoteConfig
M.config = {
    max_title_length = 120,
    show_success_notification = true,
    file_extension = '.md',
    prompt_for_name = false,
}

-- ============================================
-- Get Vault Root
-- ============================================

--- @return string|nil
local function get_vault_root()
    local ok, vault_config = pcall(require, 'vault.config')
    if ok and vault_config.options and vault_config.options.root then
        return vault_config.options.root
    end
    return nil
end

-- ============================================
-- Get Visual Selection
-- ============================================

--- @class VisualSelection
--- @field text string
--- @field start_line number 0-indexed
--- @field start_col number 0-indexed
--- @field end_line number 0-indexed
--- @field end_col number exclusive end

--- @return VisualSelection|nil
local function get_visual_selection()
    local start_pos = vim.fn.getpos('v')
    local end_pos = vim.fn.getpos('.')

    local srow, scol = start_pos[2], start_pos[3]
    local erow, ecol = end_pos[2], end_pos[3]

    if srow > erow or (srow == erow and scol > ecol) then
        srow, erow = erow, srow
        scol, ecol = ecol, scol
    end

    local lines = {}
    if vim.fn.mode() == 'V' then
        -- Visual Line Mode
        lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
        scol, ecol = 1, #lines[#lines] + 1
    elseif srow == erow then
        lines = { string.sub(vim.fn.getline(srow), scol, ecol - 1) }
    else
        lines = vim.api.nvim_buf_get_text(
            0,
            srow - 1,
            scol - 1,
            erow - 1,
            ecol,
            {}
        )
    end

    local text = table.concat(lines, '\n')

    return {
        text = text,
        start_line = srow - 1,
        start_col = scol - 1,
        end_line = erow - 1,
        end_col = ecol,
    }
end

-- ============================================
-- Sanitize Title for Filename
-- ============================================

--- @param text string
--- @param max_length number
--- @return string|nil
local function sanitize_filename(text, max_length)
    if not text or text == '' then
        return nil
    end

    local sanitized = text
        :gsub('\r\n', ' ')
        :gsub('\n', ' ')
        :gsub('\t', ' ')
        :gsub('%s+', ' ')
        :match('^%s*(.-)%s*$')
        -- cleanup if "#+ " present at start
        :gsub('^#+%s*', '')

    if not sanitized or sanitized == '' then
        return nil
    end

    sanitized = sanitized
        :sub(1, max_length)
        :gsub('[<>:"/\\|?*]', '')
        :gsub('[%c]', '')
        :gsub('%s+', ' ')
        :match('^%s*(.-)%s*$')

    return sanitized ~= '' and sanitized or nil
end

-- ============================================
-- Find Unique Filename
-- ============================================

--- @class FileInfo
--- @field filepath string
--- @field title string
--- @field base_title string
--- @field counter number

--- @param vault_root string
--- @param base_title string
--- @param extension string
--- @return FileInfo|nil
local function find_unique_filename(vault_root, base_title, extension)
    local counter = 0

    while true do
        local title = counter == 0 and base_title
            or (base_title .. ' ' .. counter)
        local filepath = vault_root .. '/' .. title .. extension

        local stat = vim.loop.fs_stat(filepath)
        if not stat then
            return {
                filepath = filepath,
                title = title,
                base_title = base_title,
                counter = counter,
            }
        end

        counter = counter + 1

        if counter > 9999 then
            return nil
        end
    end
end

-- ============================================
-- Create Note File
-- ============================================

--- @param filepath string
--- @param content string
--- @return boolean success
--- @return string|nil error
local function create_note(filepath, content)
    local parent_dir = vim.fn.fnamemodify(filepath, ':h')
    local mkdir_ok = vim.fn.mkdir(parent_dir, 'p')

    if mkdir_ok == 0 then
        return false, 'Failed to create parent directory: ' .. parent_dir
    end

    local lines = vim.split(content, '\n', { plain = true })
    local write_ok = vim.fn.writefile(lines, filepath)

    if write_ok ~= 0 then
        return false, 'Failed to write file: ' .. filepath
    end

    return true
end

-- ============================================
-- Notify LSP about new file
-- ============================================

--- @param filepath string
local function notify_lsp_file_created(filepath)
    local uri = vim.uri_from_fname(filepath)
    for _, client in ipairs(vim.lsp.get_clients({ name = 'marksman' })) do
        client:notify('workspace/didCreateFiles', {
            files = { { uri = uri } },
        })
    end
end

-- ============================================
-- Prompt for Title (Optional, via nui.nvim)
-- ============================================

--- @param default_title string
--- @param callback fun(title: string)
local function prompt_for_title(default_title, callback)
    local Input = require('nui.input')
    local title_input = Input({
        position = '50%',
        size = { width = 50 },
        border = {
            style = 'rounded',
            text = {
                top = ' Enter Note Title ',
                top_align = 'center',
            },
        },
        buf_options = {
            modifiable = true,
            readonly = false,
            filetype = 'text',
            buftype = 'prompt',
            swapfile = false,
            bufhidden = 'wipe',
        },
        win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        },
    })

    title_input:mount()

    local title_result = nil
    title_input:on('submit', function(value)
        title_result = value
        title_input:unmount()
    end)
    title_input:on('close', function()
        title_input:unmount()
    end)

    vim.wait(10000, function()
        return not title_input:is_mounted()
    end, 100)

    if title_result and title_result ~= '' then
        local prompted_title = sanitize_filename(
            title_result,
            M.config.max_title_length
        )
        if prompted_title and prompted_title ~= '' then
            callback(prompted_title)
        else
            vim.notify(
                'Prompted title is invalid, using default title',
                vim.log.levels.WARN
            )
            callback(default_title)
        end
    else
        vim.notify(
            'No title entered, using default title',
            vim.log.levels.INFO
        )
        callback(default_title)
    end
end

-- ============================================
-- Main Entry Point
-- ============================================

function M.create()
    -- Get vault root
    local vault_root = get_vault_root()
    if not vault_root then
        vim.notify(
            'Could not determine vault root. Ensure vault.config is configured.',
            vim.log.levels.ERROR
        )
        return
    end

    vault_root = vault_root:gsub('/$', '')

    -- Validate vault exists
    local vault_stat = vim.loop.fs_stat(vault_root)
    if not vault_stat or vault_stat.type ~= 'directory' then
        vim.notify(
            string.format(
                'Vault root does not exist or is not a directory: %s',
                vault_root
            ),
            vim.log.levels.ERROR
        )
        return
    end

    -- Get visual selection
    local selection = get_visual_selection()
    if not selection then
        vim.notify('No valid text selected', vim.log.levels.WARN)
        return
    end

    vim.notify(
        string.format('Visual selection: %s', vim.inspect(selection)),
        vim.log.levels.DEBUG
    )

    -- Validate non-empty
    if selection.text:match('^%s*$') then
        vim.notify(
            'Selection contains only whitespace',
            vim.log.levels.WARN
        )
        return
    end

    -- Extract first line for title
    local first_line =
        vim.split(selection.text, '\n', { plain = true })[1]
    if not first_line or first_line:match('^%s*$') then
        vim.notify(
            'First line is empty, cannot generate title',
            vim.log.levels.WARN
        )
        return
    end

    -- Generate sanitized title
    local base_title =
        sanitize_filename(first_line, M.config.max_title_length)
    if not base_title then
        vim.notify(
            'Could not generate valid filename from first line',
            vim.log.levels.WARN
        )
        return
    end

    -- ============================================
    -- Finalize note creation
    -- ============================================
    local function finalize(title)
        -- Find unique filename
        local file_info = find_unique_filename(
            vault_root,
            title,
            M.config.file_extension
        )
        if not file_info then
            vim.notify(
                'Could not find unique filename after 9999 attempts',
                vim.log.levels.ERROR
            )
            return
        end

        vim.notify(
            string.format(
                'Creating note at: %s',
                vim.inspect(file_info)
            ),
            vim.log.levels.DEBUG
        )

        -- Create note file
        local success, err = create_note(file_info.filepath, selection.text)
        if not success then
            vim.notify(
                string.format(
                    'Failed to create note: %s',
                    err or 'unknown error'
                ),
                vim.log.levels.ERROR
            )
            return
        end

        -- Notify marksman LSP so it indexes the new file immediately
        notify_lsp_file_created(file_info.filepath)

        -- Replace selection with wikilink
        local wikilink = string.format('[[%s]]', file_info.title)

        vim.notify(
            'Replacing selection with wikilink: ' .. wikilink,
            vim.log.levels.DEBUG
        )

        -- Use feedkeys to preserve registers
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes(
                'c' .. wikilink .. '<Esc>',
                true,
                false,
                true
            ),
            'n',
            false
        )

        -- Success notification
        if M.config.show_success_notification then
            local msg = file_info.counter > 0
                    and string.format(
                        'Created note: "%s" (variant %d)',
                        file_info.base_title,
                        file_info.counter
                    )
                or string.format('Created note: "%s"', file_info.title)

            vim.notify(msg, vim.log.levels.INFO)
        end
    end

    -- Prompt or use default title
    if M.config.prompt_for_name then
        prompt_for_title(base_title, finalize)
    else
        finalize(base_title)
    end
end

return M
