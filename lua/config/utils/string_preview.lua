-- lua/config/string_preview.lua
-- Better string editing for long config strings

local M = {}

-- Get the string node under cursor using Tree-sitter
local function get_string_at_cursor()
    local ts_utils = require('nvim-treesitter.ts_utils')
    local node = ts_utils.get_node_at_cursor()

    if not node then
        return nil
    end

    -- Walk up the tree to find a string node
    while node do
        local node_type = node:type()
        if node_type == 'string_content' or node_type == 'string' then
            local start_row, start_col, end_row, end_col = node:range()
            local lines =
                vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)

            -- Handle multiline strings
            if #lines > 1 then
                -- Remove opening quotes from first line
                lines[1] = lines[1]:sub(start_col + 1)
                -- Remove closing quotes from last line
                lines[#lines] = lines[#lines]:sub(1, end_col)

                return {
                    content = lines,
                    range = { start_row, start_col, end_row, end_col },
                    is_multiline = true,
                }
            else
                -- Single line string
                local content = lines[1]:sub(start_col + 2, end_col - 1) -- Remove quotes
                return {
                    content = { content },
                    range = { start_row, start_col, end_row, end_col },
                    is_multiline = false,
                }
            end
        end
        node = node:parent()
    end

    return nil
end

-- Open string in a floating preview window
function M.preview_string()
    local string_data = get_string_at_cursor()

    if not string_data then
        vim.notify('No string found under cursor', vim.log.levels.WARN)
        return
    end

    -- Create floating window
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = ' String Preview (Press <CR> to save, q to cancel) ',
        title_pos = 'center',
    })

    -- Set content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, string_data.content)

    -- Detect and set filetype for syntax highlighting
    local content_str = table.concat(string_data.content, '\n')
    if content_str:match('^#') or content_str:match('\n#') then
        vim.bo[buf].filetype = 'markdown'
    elseif
        content_str:match('^%s*SELECT') or content_str:match('^%s*select')
    then
        vim.bo[buf].filetype = 'sql'
    end

    vim.bo[buf].modifiable = true
    vim.bo[buf].buftype = 'acwrite'

    -- Store original buffer and range
    local orig_buf = vim.api.nvim_get_current_buf()
    local orig_range = string_data.range

    -- Save handler
    local function save_changes()
        local new_content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        -- Format back into a Lua string
        local formatted
        if #new_content == 1 then
            -- Single line - use simple quotes
            formatted =
                { string.format('"%s"', new_content[1]:gsub('"', '\\"')) }
        else
            -- Multi-line - use [[ ]]
            formatted = { '[[' }
            vim.list_extend(formatted, new_content)
            table.insert(formatted, ']]')
        end

        -- Replace in original buffer
        vim.api.nvim_buf_set_lines(
            orig_buf,
            orig_range[1],
            orig_range[3] + 1,
            false,
            formatted
        )

        vim.notify('String updated!', vim.log.levels.INFO)
        vim.api.nvim_win_close(win, true)
    end

    -- Keymaps
    vim.keymap.set('n', '<CR>', save_changes, { buffer = buf, silent = true })
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })

    -- Auto-save on write
    vim.api.nvim_create_autocmd('BufWriteCmd', {
        buffer = buf,
        callback = save_changes,
    })
end

-- Quick toggle for current string
function M.edit_string()
    M.preview_string()
end

return M
