--- Custom entry makers for telescope pickers
local M = {}
local make_entry = require('telescope.make_entry')
local displayers = require('plugins.telescope.displayers')

function M.gen_from_live_grep(line)
    local vimgrep_entry = make_entry.gen_from_vimgrep()(line)
    local make_display = displayers.live_grep_display(line)
    vimgrep_entry.display = make_display
    return vimgrep_entry
end

return M
