-- ~/.config/nvim/ftplugin/markdown.lua
-- Ensure these apply only to markdown buffers
vim.bo.textwidth = 80

-- Safely add formatoptions flags we want
local function add_fo(flag)
    if not vim.bo.formatoptions:find(flag, 1, true) then
        vim.bo.formatoptions = vim.bo.formatoptions .. flag
    end
end

add_fo('t') -- auto-wrap text when typing past textwidth
add_fo('q') -- allow formatting with gq/gw
add_fo('c') -- auto-wrap comments (optional)

-- Visual wrapping (doesn't change file)
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.breakindent = true
