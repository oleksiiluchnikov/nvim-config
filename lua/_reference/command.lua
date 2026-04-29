local M = {}
function M.osascript(script)
    local command = string.format('osascript -e \'%s\'', script)
    vim.cmd(string.format('!%s', command))
end
return M
