-- Use local variables to avoid global lookups
local generate_json = function(config)
    config = config or {}
    local item_data = config.item_data or {}
    local icon_base_url = config.icon_base_url
        or 'https://cdn2.iconfinder.com/data/icons/macosxicons/512/'
    local hotkey_query = config.hotkey_query or 'alt+n'

    -- Use table literals for better performance
    local used_hints = {}
    local items = {}

    -- Iterate over item_data using ipairs for better performance
    for i, item in ipairs(item_data) do
        local name = item.name
        local action = item.action
        local hint = item.hint or string.sub(name, 1, 1):lower() -- Use first letter of name as hint if none specified.

        -- Use continue to skip the rest of the loop iteration
        while used_hints[hint] do
            hint = hint .. '\''
            if used_hints[hint] then
                goto continue
            end
        end

        used_hints[hint] = true
        local icon_url = item.icon or icon_base_url .. 'Safari.png'
        local hs_query = 'hs -c \'' .. action .. '\''
        local menu_item = {
            id = i,
            name = name,
            icon = icon_url,
            hint = hint,
            action = {
                kind = 'command',
                query = hs_query,
            },
        }
        table.insert(items, menu_item)
        ::continue::
    end

    local menu_name = config.menu_name or 'Photoshop Layer Management'
    local menu_trigger = {
        hotkey = hotkey_query,
    }
    local menu = {
        name = menu_name,
        triggers = menu_trigger,
        items = items,
        app = '.*Photoshop.*',
    }

    return menu
end

-- Test function
local function test()
    local config = {
        item_data = {
            {
                name = 'New Layer',
                action = 'apps.photoshop.fn.new_layer()',
            },
            {
                name = 'Duplicate Layer',
                action = 'apps.photoshop.fn.duplicate_layer()',
            },
        },
        icon_base_url = 'https://example.com/icons/',
        hotkey_query = 'ctrl+shift+n',
        menu_name = 'Photoshop Actions',
    }

    local menu = generate_json(config)
    P(menu)
    -- print(menu.name) -- Output: Photoshop Actions
    -- print(menu.trigger.query) -- Output: ctrl+shift+n
    -- print(#menu.items) -- Output: 2
end

test()
