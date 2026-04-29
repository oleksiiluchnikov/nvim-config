--- Telescope pickers for AI skills and agents
--- Skills: ~/knowledge/Ai/skills/*/SKILL.md
--- Agents: ~/knowledge/Ai/agents/*.md
--- Uses vault.nvim for frontmatter parsing and telescope infrastructure.

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local entry_display = require('telescope.pickers.entry_display')
local previewers = require('telescope.previewers')

local Note = require('vault.notes.note')

local HOME = os.getenv('HOME')
local AI_ROOT = HOME .. '/knowledge/Ai'
local SKILLS_DIR = AI_ROOT .. '/skills'
local AGENTS_DIR = AI_ROOT .. '/agents'

local M = {}

--- Parse frontmatter data from a vault Note
---@param note table vault.Note
---@return table frontmatter data or empty table
local function get_fm(note)
    local fm = note.data.frontmatter
    if fm and fm.data then
        return fm.data
    end
    return {}
end

--- Scan skills directory and return list of {note, name, description}
---@return table[]
local function scan_skills()
    local results = {}
    local skill_dirs = vim.fn.globpath(SKILLS_DIR, '*', false, true)
    for _, dir in ipairs(skill_dirs) do
        local skill_file = dir .. '/SKILL.md'
        if vim.fn.filereadable(skill_file) == 1 then
            local note = Note(skill_file)
            local fm = get_fm(note)
            table.insert(results, {
                note = note,
                name = fm.name or vim.fn.fnamemodify(dir, ':t'),
                description = fm.description or '',
                kind = 'skill',
            })
        end
    end
    table.sort(results, function(a, b)
        return a.name < b.name
    end)
    return results
end

--- Scan agents directory and return list of {note, name, description}
---@return table[]
local function scan_agents()
    local results = {}
    local agent_files = vim.fn.globpath(AGENTS_DIR, '*.md', false, true)
    for _, file in ipairs(agent_files) do
        if vim.fn.filereadable(file) == 1 then
            local note = Note(file)
            local fm = get_fm(note)
            table.insert(results, {
                note = note,
                name = fm.title or vim.fn.fnamemodify(file, ':t:r'),
                description = fm.description or '',
                kind = 'agent',
            })
        end
    end
    table.sort(results, function(a, b)
        return a.name < b.name
    end)
    return results
end

--- Create a displayer for AI entries
---@param kind string 'skill' or 'agent'
---@return function
local function make_displayer(kind)
    local icon = kind == 'skill' and '󱜚 ' or '󰁥 '
    local displayer = entry_display.create({
        separator = ' ',
        items = {
            { width = 2 },
            { width = 30 },
            { remaining = true },
        },
    })
    return function(entry)
        return displayer({
            { icon, 'Special' },
            { entry.name, 'TelescopeResultsIdentifier' },
            { entry.description, 'TelescopeResultsComment' },
        })
    end
end

--- Create entry maker for AI entries
---@param kind string
---@return function
local function make_entry_maker(kind)
    local display_fn = make_displayer(kind)
    return function(item)
        return {
            value = item,
            ordinal = item.name .. ' ' .. item.description,
            display = display_fn,
            filename = item.note.data.path,
            name = item.name,
            description = item.description,
        }
    end
end

--- Scaffold a new skill
---@param name string
local function create_skill(name)
    local dir = SKILLS_DIR .. '/' .. name
    vim.fn.mkdir(dir, 'p')
    local path = dir .. '/SKILL.md'
    local content = table.concat({
        '---',
        'name: ' .. name,
        'description: ""',
        'license: MIT',
        'compatibility: opencode',
        '---',
        '',
        '## What I do',
        '',
        '## When to use me',
        '',
        '## Instructions',
        '',
    }, '\n')
    vim.fn.writefile(vim.split(content, '\n'), path)
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
end

--- Scaffold a new agent
---@param name string
local function create_agent(name)
    local slug = name:lower():gsub('%s+', '-')
    local path = AGENTS_DIR .. '/' .. slug .. '.md'
    local title = name:sub(1, 1):upper() .. name:sub(2)
    local content = table.concat({
        '---',
        'description: ""',
        'mode: subagent',
        'model: github-copilot/claude-sonnet-4.6',
        'temperature: 0.3',
        'color: "#FFFFFF"',
        'title: ' .. title .. ' (' .. slug .. ')',
        'created: ' .. os.date('%Y%m%d%H%M%S'),
        '---',
        '',
        '## What you do',
        '',
        '## Execution',
        '',
    }, '\n')
    vim.fn.writefile(vim.split(content, '\n'), path)
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
end

--- Delete an AI entry with confirmation
---@param entry table telescope entry
local function delete_entry(entry)
    local item = entry.value
    local path = item.note.data.path
    vim.ui.select({ 'Yes', 'No' }, {
        prompt = 'Delete ' .. item.kind .. ' "' .. item.name .. '"?',
    }, function(choice)
        if choice == 'Yes' then
            if item.kind == 'skill' then
                local dir = vim.fn.fnamemodify(path, ':h')
                vim.fn.delete(dir, 'rf')
            else
                vim.fn.delete(path)
            end
            vim.notify(
                'Deleted ' .. item.kind .. ': ' .. item.name,
                vim.log.levels.INFO
            )
        end
    end)
end

--- Rename an AI entry
---@param entry table telescope entry
local function rename_entry(entry)
    local item = entry.value
    vim.ui.input({
        prompt = 'Rename ' .. item.kind .. ' to: ',
        default = item.name,
    }, function(new_name)
        if not new_name or new_name == '' or new_name == item.name then
            return
        end
        local slug = new_name:lower():gsub('%s+', '-')
        if item.kind == 'skill' then
            local old_dir = vim.fn.fnamemodify(item.note.data.path, ':h')
            local new_dir = SKILLS_DIR .. '/' .. slug
            vim.fn.rename(old_dir, new_dir)
            vim.notify(
                'Renamed skill: ' .. item.name .. ' -> ' .. slug,
                vim.log.levels.INFO
            )
        else
            local new_path = AGENTS_DIR .. '/' .. slug .. '.md'
            vim.fn.rename(item.note.data.path, new_path)
            vim.notify(
                'Renamed agent: ' .. item.name .. ' -> ' .. slug,
                vim.log.levels.INFO
            )
        end
    end)
end

--- Attach common mappings to an AI picker
---@param kind string 'skill' or 'agent'
---@return function
local function attach_mappings(kind)
    return function(prompt_bufnr, map)
        actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if entry then
                vim.cmd('edit ' .. vim.fn.fnameescape(entry.filename))
            end
        end)

        map('i', '<C-n>', function()
            actions.close(prompt_bufnr)
            vim.ui.input({
                prompt = 'New ' .. kind .. ' name: ',
            }, function(name)
                if not name or name == '' then
                    return
                end
                local slug = name:lower():gsub('%s+', '-')
                if kind == 'skill' then
                    create_skill(slug)
                else
                    create_agent(name)
                end
            end)
        end)

        map('i', '<C-d>', function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if entry then
                delete_entry(entry)
            end
        end)

        map('i', '<C-r>', function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if entry then
                rename_entry(entry)
            end
        end)

        return true
    end
end

--- Skills picker
function M.skills(opts)
    opts = opts or {}
    local results = scan_skills()
    pickers
        .new(opts, {
            prompt_title = 'AI Skills',
            finder = finders.new_table({
                results = results,
                entry_maker = make_entry_maker('skill'),
            }),
            sorter = sorters.get_fzy_sorter(),
            previewer = previewers.vim_buffer_cat.new({}),
            attach_mappings = attach_mappings('skill'),
        })
        :find()
end

--- Agents picker
function M.agents(opts)
    opts = opts or {}
    local results = scan_agents()
    pickers
        .new(opts, {
            prompt_title = 'AI Agents',
            finder = finders.new_table({
                results = results,
                entry_maker = make_entry_maker('agent'),
            }),
            sorter = sorters.get_fzy_sorter(),
            previewer = previewers.vim_buffer_cat.new({}),
            attach_mappings = attach_mappings('agent'),
        })
        :find()
end

--- Register keymaps
vim.keymap.set('n', '<leader>As', function()
    M.skills()
end, { silent = true, noremap = true, desc = 'AI Skills' })

vim.keymap.set('n', '<leader>Aa', function()
    M.agents()
end, { silent = true, noremap = true, desc = 'AI Agents' })

--- Register user commands
vim.api.nvim_create_user_command('AISkills', function()
    M.skills()
end, { desc = 'Telescope: AI Skills' })

vim.api.nvim_create_user_command('AIAgents', function()
    M.agents()
end, { desc = 'Telescope: AI Agents' })

return M
