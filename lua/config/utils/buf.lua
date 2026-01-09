local M = {}
function M.has_words_before()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0
        and vim.api
                .nvim_buf_get_lines(0, line - 1, line, true)[1]
                :sub(col, col)
                :match('%s')
            == nil
end

--- Get start and end lines for code selection
--- ```lua
--- local start_line, end_line = get_selection_lines()
--- assert(start_line >= 1)
--- if end_line ~= nil then
---    assert(end_line >= start_line)
--- end
--- ```
--- @return integer start_line
--- @return integer end_line # Can be nil if no selection
function M.get_selection_lines()
    local _, lnum_start, _, _, _ = unpack(vim.fn.getpos('\'<'))
    local _, lnum_end, _, _, _ = unpack(vim.fn.getpos('\'>'))
    return lnum_start, lnum_end
end

-- Cache the result of expensive function calls
function M.move_to_mark_and_center(args)
    local buf = args.buf
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local line_count = vim.api.nvim_buf_line_count(buf)

    -- Use short-circuit evaluation to avoid unnecessary checks
    if mark[1] > 0 and mark[1] <= line_count then
        vim.cmd('normal! g`"zz') -- move cursor to mark and center screen
    end
end
--- Get the current visual selection formatted for Markdown.
--- ```lua
--- local selection_in_fences = get_visual_selection_Markdown(
---    'lua',
---    vim.api.nvim_get_current_buf(),
---    start_line,
---    end_line
--- )
---
--- assert(selection_in_fences:match('^```lua\n'))
--- assert(selection_in_fences:match('\n```$'))
--- ```
--- @param filetype string The filetype of the current buffer
--- @param bufnr integer The buffer number of the current buffer
--- @param start_line integer The starting line number of the selection
--- @param end_line integer The ending line number of the selection
--- @return string selection in fenced markdown code block.
function M.get_visual_selection_markdown(filetype, bufnr, start_line, end_line)
    ---@type string[]
    local range_text =
        vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
    ---@type string
    local selection = table.concat(range_text, '\n')
    ---@type string
    local selection_in_fences =
        string.format('```%s\n%s\n```', filetype, selection)
    return selection_in_fences
end

--- Get the current visual selection.
--- ```lua
--- local selection = get_visual_selection()
--- assert(selection:match('^%w+://'))
--- ```
--- @return string
function M.get_visual_selection()
    local _, lnum_start, col_start = unpack(vim.fn.getpos('v')) -- start of visual selection
    local _, lnum_end, col_end = unpack(vim.fn.getpos('.')) -- end of visual selection
    local range_text = vim.api.nvim_buf_get_text(
        0,
        lnum_start,
        col_start,
        lnum_end,
        col_end,
        {}
    )
    local selection = table.concat(range_text, '\n')
    return selection
end
--- Jump to next line with same indentation level
--- @param down boolean
--- @param ignore string[]
--- @return boolean
function M.jump_to_next_line_with_same_indent(down, ignore)
    local lnum = vim.fn.line('.')
    local max_lines = vim.fn.line('$')
    local target_indent

    local ignore_set = {}
    for _, v in ipairs(ignore) do
        ignore_set[v] = true
    end

    ---@param line_content string
    ---@return number
    local function get_indentation_level(line_content)
        local spaces = line_content:match('^(%s*)')
        return #spaces
    end

    ---@param line_content string
    ---@return boolean
    local function starts_with_ignore(line_content)
        for pattern in pairs(ignore_set) do
            if line_content:match('^%s*' .. pattern .. '%S*') then
                return true
            end
        end
        return false
    end

    local curr_line_content = vim.fn.getline(lnum)

    -- If the current line is empty, try to find the next non-empty line's indentation as the target_indent
    if curr_line_content:match('^%s*$') then
        local temp_lnum = down and (lnum + 1) or (lnum - 1)
        while
            temp_lnum > 0
            and temp_lnum <= max_lines
            and vim.fn.getline(temp_lnum):match('^%s*$')
        do
            temp_lnum = down and (temp_lnum + 1) or (temp_lnum - 1)
        end
        if temp_lnum <= 0 or temp_lnum > max_lines then
            return true -- Reached the top or bottom without finding a non-empty line
        end
        curr_line_content = vim.fn.getline(temp_lnum)
        lnum = temp_lnum
    end

    local first_char_pos = curr_line_content:find('[A-Za-z_]')
    if first_char_pos then
        target_indent = get_indentation_level(curr_line_content)
    else
        return true -- No valid indentation level found in current line
    end

    -- Define the direction for the loop increment
    local increment = down and 1 or -1

    -- Start searching from the next/previous line
    lnum = lnum + increment

    while (not down and lnum > 0) or (down and lnum <= max_lines) do
        local line_content = vim.fn.getline(lnum)
        local new_first_char_pos = line_content:find('[A-Za-z_]')
        if new_first_char_pos then
            local current_indent = get_indentation_level(line_content)
            if
                current_indent == target_indent
                and not starts_with_ignore(line_content)
            then
                vim.api.nvim_win_set_cursor(0, { lnum, new_first_char_pos - 1 })
                break
            end
        end
        lnum = lnum + increment
    end

    return true
end

return M
