local source = {}

local defaults = {
    kind = 'person',
    label_format = '[[%s - %s]]',
    trigger_character = '@',
}

local function match_query(ctx, trigger)
    local before_cursor = ctx.line:sub(1, ctx.cursor[2])
    local prefix, query = before_cursor:match('(^)%' .. trigger .. '([%w_-]+)$')
    if not query then
        prefix, query = before_cursor:match('(%s)%' .. trigger .. '([%w_-]+)$')
    end
    if not query then
        return nil
    end

    return {
        query = query,
        -- LSP ranges are 0-indexed. Keep leading space, replace only @query.
        start_character = #before_cursor - #query - #trigger,
        line = ctx.cursor[1] - 1,
    }
end

function source.new(opts)
    local self = setmetatable({}, { __index = source })
    self.opts = vim.tbl_deep_extend('force', defaults, opts or {})
    return self
end

function source:get_trigger_characters()
    return { self.opts.trigger_character }
end

function source:get_completions(ctx, callback)
    local match = match_query(ctx, self.opts.trigger_character)
    if not match then
        callback({ items = {}, is_incomplete_forward = true, is_incomplete_backward = true })
        return
    end

    local text = self.opts.label_format:format(self.opts.kind, match.query)
    callback({
        items = {
            {
                label = text,
                labelDetails = { description = 'Person wikilink' },
                kind = require('blink.cmp.types').CompletionItemKind.Reference,
                filterText = self.opts.trigger_character .. match.query .. ' ' .. match.query .. ' ' .. text,
                sortText = '0000',
                textEdit = {
                    newText = text,
                    range = {
                        start = { line = match.line, character = match.start_character },
                        ['end'] = { line = match.line, character = ctx.cursor[2] },
                    },
                },
                insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
            },
        },
        is_incomplete_forward = true,
        is_incomplete_backward = true,
    })
end

return source
