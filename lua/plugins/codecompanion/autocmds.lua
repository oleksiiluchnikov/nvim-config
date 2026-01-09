local group = vim.api.nvim_create_augroup('CodeCompanionHooks', {})

local last_autocmd_time = nil
local function should_notify()
    local cur = os.time()
    if last_autocmd_time == nil or cur - last_autocmd_time > 2 then
        last_autocmd_time = cur
        return true
    end
    return false
end
-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
local function get_context_info(data)
    if not data then
        return ''
    end
    local info = {}

    if data.adapter then
        local name = data.adapter.formatted_name or data.adapter.name
        local model = data.adapter.model
        if name and model then
            table.insert(info, string.format('%s (%s)', name, model))
        elseif name then
            table.insert(info, name)
        end
    end

    if data.strategy then
        table.insert(info, data.strategy)
    end

    return #info > 0 and ' [' .. table.concat(info, ' - ') .. ']' or ''
end

vim.api.nvim_create_autocmd({ 'User' }, {
    pattern = 'CodeCompanionChatCleared',
    group = group,
    callback = function()
        vim.g.codecompanion_attached_prompt_decorator = false
    end,
})

vim.api.nvim_create_autocmd('User', {
    pattern = {
        'CodeCompanionChatDone',
        'CodeCompanionRequestStarted',
        'CodeCompanionRequestFinished',
    },
    callback = function(args)
        if not should_notify() then
            return
        end

        local context_info = get_context_info(args.data)
        local messages = {
            CodeCompanionChatDone = 'Chat ready',
            CodeCompanionRequestStarted = 'Generating...',
            CodeCompanionRequestFinished = 'Completed',
        }

        local msg = messages[args.match]
        if msg then
            vim.notify(
                msg .. context_info,
                vim.log.levels.INFO,
                { title = 'CodeCompanion' }
            )
        end
    end,
})
