local pickers = require('vault.pickers')

local M = {}
local search = {}

function search.tags()
    pickers.tags()
end

function search.tasks()
    pickers.tasks()
end

function search.notes()
    pickers.notes({})
end

function search.dates()
    pickers.dates()
end

function search.today_date()
    local today = os.date('%Y-%m-%d')
    if not today or type(today) ~= 'string' then
        error('invalid argument: must be a string: ' .. vim.inspect(today))
    end
    pickers.dates({ start_date = today, end_date = today })
end

function search.notes_with_type()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_zettel()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Zettel' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_project()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Project' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_task()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Task' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_event()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Event' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_workflow()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Workflow' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_person()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Person' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_action()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Action' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_location()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Location' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_meta_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Meta' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_snippet_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Snippet' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_value_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Value' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_aspiriation_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Aspiration' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_path_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Path' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_idea_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Idea' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_goal_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Goal' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_hardware_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Hardware' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_journal_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Journal' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_daily_journal_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/journal' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_weekly_journal_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Journal/Weekly' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_monthly_journal_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Journal/Monthly' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_yearly_journal_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Journal/Yearly' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_status()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'status' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_todo_status()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'status/TODO' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_in_progress_status()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'status/IN-PROGRESS' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_done_status()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'status/DONE' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_in_review_status()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'status/IN-REVIEW' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_archived_status()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'status/ARCHIVED' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_on_hold_status()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'status/ON-HOLD' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_deprecated_status()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'status/DEPRECATED' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_active_status()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'status/ACTIVE' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_seeding_status()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'status/SEEDING' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_with_software_tag()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            include = { 'type/Software' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = false,
        }),
    })
end

function search.notes_without_type()
    pickers.notes({
        notes = require('vault.notes')():filter({
            search_term = 'tags',
            exclude = { 'type' },
            match_opt = 'startswith',
            mode = 'all',
            case_sensitive = true,
        }),
    })
end

M.search = search

return M
