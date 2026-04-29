local M = {}

-- Get matching lines and their corresponding columns for a given pattern
M.get_matches = function(lang, query)
    local parser = vim.treesitter.get_parser(0, lang)
    if not parser then
        vim.notify('Parser not found for ' .. lang)
        return {}
    end
    -- local query = vim.treesitter.parse_query("YOUR_LANGUAGE_HERE", [[
    --     (inline)
    -- ]])
    local parsed_query = vim.treesitter.query(lang, query)

    local matches = {}

    for _, tree in ipairs(parser:parse()) do
        for _, match in parsed_query:iter_matches(tree:root(), 0) do
            local _, start_row, start_col, end_col = match[1]:range()
            if not matches[start_row + 1] then
                matches[start_row + 1] = {}
            end
            table.insert(matches[start_row + 1], { start_col, end_col })
        end
    end

    return matches
end

-- Clear previous highlights
M.clear_highlights = function(bufnr, namespace)
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
end

-- Highlight matched patterns
M.highlight_matches = function()
    local matches = M._get_matches()
    local bufnr = vim.api.nvim_get_current_buf()
    local namespace = vim.api.nvim_create_namespace('MyCustomHighlightGroup')

    -- Define the highlight group (you can customize the style)
    vim.cmd('highlight MyCustomHighlightGroup guibg=Yellow')

    M.clear_highlights(bufnr, namespace)

    for line_num, cols in pairs(matches) do
        for _, col_range in ipairs(cols) do
            vim.api.nvim_buf_add_highlight(
                bufnr,
                namespace,
                'MyCustomHighlightGroup',
                line_num - 1,
                col_range[1],
                col_range[2]
            )
        end
    end
end

return M
