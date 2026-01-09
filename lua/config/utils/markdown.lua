local uri = require('config.utils').uri
local M = {}
M.checkbox = {}
-- Optimize string concatenation using table and table.concat
local function concat(...)
    local t = { ... }
    return table.concat(t)
end

M.checkbox.inline_fields_order = {
    'task',
    'project',
    'program',
    'strategy',
    'path',
    'goal',
}

local regex = {}
regex.checkbox = '%[([%s%a])%]'
-- inline field : [field_name::value with anythings]
regex.inline = '%[([%w_]+)::(.*)%]'

-- date format : 2021-11-21 Wed 21:00:12
local date_format = '%Y-%m-%d %a %H:%M:%S'

M.checkbox.checkbox_states = {
    ' ',
    'x',
}

function M.checkbox.find_index(tbl, item)
    for i, v in ipairs(tbl) do
        if v == item then
            return i
        end
    end
    return nil
end

function M.checkbox.construct_inline_field(field, value)
    return string.format('[%s::%s]', field, value)
end

-- Add dataview inline field
function M.checkbox.add_inline_field(line, field, value)
    if M.checkbox.has_inline_field(line, field) then
        return
    end
    local new_line = line
        .. ' '
        .. M.checkbox.construct_inline_field(field, value)
    return new_line
end

-- Remove dataview inline field
function M.checkbox.remove_inline_field(line, key)
    if M.checkbox.has_inline_field(line, key) == false then
        return line
    end
    local new_line = string.gsub(line, regex.inline, '')
    return new_line
end

-- Replace inline field value
function M.checkbox.replace_inline_field_value(line, field, value)
    if M.checkbox.has_inline_field(line, field) == false then
        return line
    end
    local new_line = string.gsub(
        line,
        regex.inline,
        M.checkbox.construct_inline_field(field, value)
    )
    return new_line
end

-- has checkbox
function M.checkbox.has_checkbox(line)
    local has_checkbox = string.find(line, regex.checkbox)
    if has_checkbox == nil then
        return false
    end
    return true
end

-- has inline field wit key
function M.checkbox.has_inline_field(line, key)
    local has_inline_field = string.match(line, '%[' .. key .. '::')
    if has_inline_field == nil then
        return false
    end
    return true
end

-- Toggle checkbox in task line
function M.checkbox.toggle_checkbox()
    local current_line = vim.api.nvim_get_current_line()
    local new_line = current_line

    if not M.checkbox.has_checkbox(current_line) then
        return
    end
    -- Get the current cursor position
    local current_pos = vim.api.nvim_win_get_cursor(0)

    local current_checkbox_state = M.checkbox.get_checkbox_state(current_line)

    -- find current checkbox state in checkbox_states
    local current_checkbox_state_index = M.checkbox.find_index(
        M.checkbox.checkbox_states,
        current_checkbox_state
    )

    -- get the next checkbox state
    local next_checkbox_state_index = current_checkbox_state_index + 1

    -- cycle M.checkbox.checkbox_states
    if next_checkbox_state_index > #M.checkbox.checkbox_states then
        next_checkbox_state_index = 1
    end

    -- get the next checkbox state
    local next_checkbox_state =
        M.checkbox.checkbox_states[next_checkbox_state_index]

    -- if the any next checkbox state
    -- add date_updated field
    if not M.checkbox.has_inline_field(new_line, 'date_updated') then
        new_line = M.checkbox.add_inline_field(
            new_line,
            'date_updated',
            os.date(date_format)
        )
    else
        new_line = M.checkbox.replace_inline_field_value(
            new_line,
            'date_updated',
            os.date(date_ormat)
        )
    end

    -- if the next checkbox state is "x"
    -- add date_completed field
    if next_checkbox_state == 'x' then
        if not M.checkbox.has_inline_field(new_line, 'date_completed') then
            new_line = M.checkbox.add_inline_field(
                new_line,
                'date_completed',
                os.date(date_ormat)
            )
        else
            new_line = M.checkbox.replace_inline_field_value(
                new_line,
                'date_completed',
                os.date(date_format)
            )
        end
    end

    -- if the next checkbox state is "i"
    -- add date_started field
    if next_checkbox_state == 'i' then
        if not M.checkbox.has_inline_field(new_line, 'date_started') then
            new_line = M.checkbox.add_inline_field(
                new_line,
                'date_started',
                os.date(date_format)
            )
        else
            new_line = M.checkbox.replace_inline_field_value(
                new_line,
                'date_started',
                os.date(date_format)
            )
        end
    end

    -- if the next checkbox state is "c"
    -- add date_cancelled field
    if next_checkbox_state == 'c' then
        if not M.checkbox.has_inline_field(new_line, 'date_cancelled') then
            new_line = M.checkbox.add_inline_field(
                new_line,
                'date_cancelled',
                os.date(date_format)
            )
        else
            new_line = M.checkbox.replace_inline_field_value(
                new_line,
                'date_cancelled',
                os.date(date_format)
            )
        end
    end

    -- if the next checkbox state is "a"
    -- add date_archived field
    if next_checkbox_state == 'a' then
        if not M.checkbox.has_inline_field(new_line, 'date_archived') then
            new_line = M.checkbox.add_inline_field(
                new_line,
                'date_archived',
                os.date(date_format)
            )
        else
            new_line = M.checkbox.replace_inline_field_value(
                new_line,
                'date_archived',
                os.date(date_format)
            )
        end
    end

    new_line =
        string.gsub(new_line, regex.checkbox, '[' .. next_checkbox_state .. ']')

    -- replace the current line with the new line and restore the cursor position
    vim.api.nvim_set_current_line(new_line)
    vim.api.nvim_win_set_cursor(0, current_pos)
end

-- Sort inline fields in task line according to the order in M.checkbox.inline_fields
function M.checkbox.sort_inline_fields(line)
    -- Sort the dataview inline fields according to the sort order, else order alphabetically
    local new_line = line
    local inline_fields = {}
    local inline_fields_ordered = {}
    local line_sorted = ''
    for field in string.gmatch(line, regex.inline) do
        table.insert(inline_fields, field)
    end
    for _, field in ipairs(M.checkbox.inline_fields_order) do
        for _, inline_field in ipairs(inline_fields) do
            if string.match(inline_field, field) then
                table.insert(inline_fields_ordered, inline_field)
            end
        end
    end
    for _, inline_field in ipairs(inline_fields) do
        if not vim.tbl_contains(inline_fields_ordered, inline_field) then
            table.insert(inline_fields_ordered, inline_field)
        end
    end
    for _, inline_field in ipairs(inline_fields_ordered) do
        line_sorted = line_sorted .. ' ' .. inline_field
    end
    return line_sorted
end

-- Get checkbox state
function M.checkbox.get_checkbox_state(line)
    if not M.checkbox.has_checkbox(line) then
        return nil
    end
    local checkbox_state = string.match(line, regex.checkbox)
    if checkbox_state == nil then
        return nil
    end
    return checkbox_state
end

-- M.checkbox.project.checkbox_states = {" ", "x", "i", "c", "a"}
-- M.checkbox.task.checkbox_states = {" ", "x"}

-- Get the task
function M.checkbox.get_task(line) --> string
    -- local task = string.match(line, regex.task)
    -- if task == nil then
    return nil
end

-- return task
-- end

-- Set checkbox state
function M.checkbox.set_multi_checkbox_state(target, state)
    -- if target not assigned, set to current line
    if target == nil then
        target = vim.api.nvim_get_current_line()
        -- if target is a number, set to line number
    elseif type(target) == 'number' then
        target = vim.api.nvim_buf_get_lines(0, target - 1, target, false)[1]
        -- if target is a multiline string, apply to each line
    elseif string.find(target, '\n') then
        target = vim.split(target, '\n')
    elseif string.match(target, '^%s*$') then
        target = { target }
    end
    if type(target) ~= 'table' then
        target = { target }
    end
    for _, line in ipairs(target) do
        local new_line = line
        if M.checkbox.has_checkbox(line) then
            new_line = string.gsub(line, regex.checkbox, '[' .. state .. ']')
        end
        vim.api.nvim_set_current_line(new_line)
    end
end

-- Set checkbox state
function M.checkbox.set_checkbox_state(line, state)
    local new_line = line
    if not M.checkbox.has_checkbox(line) then
        return line
    end
    new_line = string.gsub(new_line, regex.checkbox, '[' .. state .. ']')
    return new_line
end

-- Use early returns to avoid unnecessary computations
local function convert_to_markdown_link()
    vim.cmd('normal! yiW')
    local url = tostring(vim.fn.getreg(''))
    if not url or url == '' then
        vim.notify('No URL found under the cursor')
        return
    end

    if not uri.is_valid_url(url) then
        vim.notify(concat(url, ' doesn\'t look like a URL'))
        return
    end

    -- Fetch the title of the URL.
    local title = uri.fetch_title(url)
    if title ~= '' then
        local link = concat('[', title, '](', url, ')')
        vim.fn.setreg('', link)
        vim.cmd('normal! viWp')
    else
        print('Title not found for link')
    end
end

vim.api.nvim_create_user_command('ToMarkdownLink', convert_to_markdown_link, {
    nargs = 0,
})
