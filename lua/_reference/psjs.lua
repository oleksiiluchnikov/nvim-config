-- "Run" to run jsx script in photoshop
vim.api.nvim_create_user_command('RunPhotoshop', function()
    -- local cmd =
    --     'silent exec \'!osascript -e "tell application \\"Adobe Photoshop 2023\\"  to do javascript of file \\"%s\\""\''
    local cmd =
        'silent exec \'!heyps -a ps -e "do javascript of file \\"%s\\""\''
    cmd = string.format(cmd, vim.fn.expand('%:p'))
    vim.cmd(cmd)
end, {})

-- "RunPhotoshopScript" to run current file in Photoshop
vim.api.nvim_create_user_command('RunPsScript', function()
    local photoshop_name = vim.fn.system('hs -c \'apps.photoshop.name\'')
    -- execute_osascript('\'tell application ' .. photoshop_name .. 'to do javascript of file "%"\'')
    vim.fn.system(
        'osascript -e \'tell application '
            .. photoshop_name
            .. ' to do javascript of file "%"\''
    )
end, {
    nargs = 1,
    complete = function()
        local app_scripts_dir =
            vim.fn.system('hs -c \'apps.photoshop.paths.scripts\'')
        -- Reursively find all files in app_scripts_dir
        -- mdfind -onlyin app_scripts_dir "kMDItemFSName == '*.*' && kMDItemKind != 'Folder'"
        local paths = vim.fn.system('find ' .. app_scripts_dir)
        -- Split files by newlines
        local paths_table = vim.split(paths, '\n')
        -- Remove directories
        local files = {}
        for _, path in pairs(paths_table) do
            if vim.fn.isdirectory(path) == 0 then
                -- Remove app_scripts_dir from start of path
                local file = string.sub(path, string.len(app_scripts_dir) + 1)
                if file ~= '' then
                    -- Remove app_scripts_dir from path
                    table.insert(files, file)
                end
            end
        end
        return files
    end,
})
