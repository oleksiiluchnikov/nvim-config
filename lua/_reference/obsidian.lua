--- Optimize the code by using early returns and short-circuit evaluation
--- @param bufnr number Buffer handle
--- @return nil
local function replace_dataview_query(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local has_frontmatter = lines[1] == '---'
    local start_line = has_frontmatter and 1 or 0

    --- Early return if there are no lines
    if #lines == 0 then
        return nil
    end

    local matched_lines = {} ---@type string[]
    local non_matched_lines = {} ---@type string[]

    --- Use short-circuit evaluation to avoid unnecessary iterations
    for i = start_line + 1, #lines do
        local line = lines[i]
        if line:match('^[a-z_-]+::.*$') then
            table.insert(matched_lines, line)
        else
            table.insert(non_matched_lines, line)
        end
    end

    --- Avoid unnecessary table operations if there are no matched lines
    if #matched_lines == 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        return nil
    end

    --- Optimize the frontmatter handling
    local result_lines = {}
    if has_frontmatter then
        table.insert(result_lines, lines[1])
        for i = 1, #matched_lines do
            table.insert(result_lines, start_line + i, matched_lines[i])
        end
        for i = start_line + 1, #non_matched_lines do
            table.insert(
                result_lines,
                i + #matched_lines,
                non_matched_lines[i - start_line]
            )
        end
    else
        for i = 1, #matched_lines do
            table.insert(result_lines, i, matched_lines[i])
        end
        for i = 1, #non_matched_lines do
            table.insert(result_lines, i + #matched_lines, non_matched_lines[i])
        end
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, result_lines)

    return nil
end

vim.api.nvim_create_user_command('RDvQuery', replace_dataview_query, {})
