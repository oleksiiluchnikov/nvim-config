local entry_display = require('telescope.pickers.entry_display')
local displayers = {}

function displayers.live_grep_display(entry)
    local filename, row, col, text =
        string.match(entry, '([^:]+):(%d+):(%d+):(.*)')
    local cwd = vim.uv.cwd()
    local bufwidth = vim.api.nvim_get_option('columns') - 4
    local relative_path = filename:gsub(cwd, '.')
    local filename_length = relative_path:len()
    local location = string.format('%s:%s', row, col)

    local text_length = text:len()
    local location_length = location:len()
    local text_width = bufwidth - filename_length - location_length
    if text_length > text_width then
        text = text:sub(1, text_width) .. '...'
    end

    local displayer = entry_display.create({
        separator = ' ',
        items = {
            { width = filename_length },
            { width = text_width },
            { width = location_length },
        },
    })
    return displayer({
        { relative_path, 'TelescopeResultsIdentifier' },
        { text, 'TelescopeResultsLineNr' },
        { location, '@text.todo' },
    })
end
return displayers
