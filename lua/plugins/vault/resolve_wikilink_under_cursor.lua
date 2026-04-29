local M = {}

local function wikilink_under_cursor()
    local line_nr = vim.api.nvim_win_get_cursor(0)[1]
    local col0 = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()

    local search_from = 1
    while true do
        local s, e, inner = line:find('%[%[(.-)%]%]', search_from)
        if not s then
            return nil
        end
        if col0 + 1 >= s and col0 + 1 <= e then
            local slug, rest = inner:match('^([^#|]*)(.*)$')
            if slug and slug ~= '' then
                return {
                    line_nr = line_nr,
                    start_col = s - 1,
                    end_col = e,
                    inner = inner,
                    slug = slug,
                    rest = rest or '',
                }
            end
        end
        search_from = e + 1
    end
end

local function replace_link_at(mark, slug)
    local text = string.format('[[%s%s]]', slug, mark.rest or '')
    vim.api.nvim_buf_set_text(
        0,
        mark.line_nr - 1,
        mark.start_col,
        mark.line_nr - 1,
        mark.end_col,
        { text }
    )
end

local function make_wikilink(slug)
    local Wikilink = require('vault.wikilinks.wikilink')
    return Wikilink({
        raw = slug,
        sources = {},
        suggestions = {},
        target = slug,
    })
end

local function get_mark_or_notify()
    local mark = wikilink_under_cursor()
    if not mark then
        vim.notify('No wikilink under cursor', vim.log.levels.WARN)
        return nil
    end
    return mark
end

local function resolve_target(mark)
    local utils = require('vault.utils')
    local direct_path = utils.slug_to_path(mark.slug)
    if vim.fn.filereadable(direct_path) == 1 then
        return mark.slug, direct_path
    end

    -- Slow fallback: this scans the vault, so only pay it when the direct
    -- Obsidian-style slug path does not exist.  Normal `gf` must stay instant.
    local wikilinks = require('vault.wikilinks')()
    local wikilink = wikilinks.map[mark.slug]
    local slug = (wikilink and wikilink.data and wikilink.data.target)
        or mark.slug
    return slug, utils.slug_to_path(slug)
end

local function ensure_note(slug, path)
    path = path or require('vault.utils').slug_to_path(slug)
    if vim.fn.filereadable(path) == 0 then
        path = require('vault.notes.create').create(slug, { open = false })
    end
    return path
end

function M.resolve_under_cursor()
    local mark = get_mark_or_notify()
    if not mark then
        return
    end

    local wikilink = make_wikilink(mark.slug)

    require('vault.ui.resolve_picker').open({
        wikilink = wikilink,
        prompt_slug = mark.slug,
        include_create = true,
        on_resolve = function(result)
            if result.action == 'skip' then
                return
            end

            local slug = result.slug or result.prompt
            if not slug or slug == '' then
                return
            end

            if result.action == 'create' then
                require('vault.notes.create').create(slug, { open = false })
            end

            replace_link_at(mark, slug)
            vim.cmd('write')
        end,
    })
end

function M.follow_under_cursor(opts)
    opts = opts or {}
    local mark = get_mark_or_notify()
    if not mark then
        return
    end

    local slug, path = resolve_target(mark)
    path = ensure_note(slug, path)
    local cmd = opts.split == 'vertical' and 'vsplit' or 'edit'
    vim.cmd(cmd .. ' ' .. vim.fn.fnameescape(path))
end

function M.rename_wikilink_under_cursor()
    local mark = get_mark_or_notify()
    if not mark then
        return
    end

    local new_slug = vim.fn.input('Rename wikilink to: ', mark.slug)
    new_slug = vim.trim(new_slug or '')
    if new_slug == '' or new_slug == mark.slug then
        return
    end

    replace_link_at(mark, new_slug)
    vim.cmd('write')
end

function M.rename_note_under_cursor()
    local mark = get_mark_or_notify()
    if not mark then
        return
    end

    local old_slug, old_path = resolve_target(mark)
    if vim.fn.filereadable(old_path) == 0 then
        vim.notify('Target note missing: ' .. old_slug, vim.log.levels.WARN)
        return
    end

    local new_slug = vim.fn.input('Rename note to: ', old_slug)
    new_slug = vim.trim(new_slug or '')
    if new_slug == '' or new_slug == old_slug then
        return
    end

    vim.cmd('write')
    local new_path = require('vault.utils').slug_to_path(new_slug)
    local ok, err = pcall(function()
        require('vault.notes.note')({ path = old_path }):move(new_path)
    end)
    if not ok then
        vim.notify(
            'Failed to rename note: ' .. tostring(err):match('[^\n]+'),
            vim.log.levels.ERROR
        )
        return
    end

    replace_link_at(mark, new_slug)
    vim.cmd('write')
end

M._wikilink_under_cursor = wikilink_under_cursor
return M
