return {
    {
        'ThePrimeagen/99',
        cmd = { 'AI99Open', 'AI99Search', 'AI99Vibe', 'AI99Tutorial', 'AI99Put' },
        keys = {
            {
                '<leader>js',
                function()
                    require('99').search()
                end,
                desc = '99 search',
                mode = 'n',
            },
            {
                '<leader>jb',
                function()
                    require('99').vibe()
                end,
                desc = '99 vibe',
                mode = 'n',
            },
            {
                '<leader>jt',
                function()
                    require('99').tutorial()
                end,
                desc = '99 tutorial',
                mode = 'n',
            },
            {
                '<leader>jo',
                function()
                    require('99').open()
                end,
                desc = '99 open last result',
                mode = 'n',
            },
            {
                '<leader>jx',
                function()
                    require('99').stop_all_requests()
                end,
                desc = '99 stop requests',
                mode = 'n',
            },
            {
                '<leader>jv',
                function()
                    require('99').visual()
                end,
                desc = '99 transform selection',
                mode = 'v',
            },
            {
                '<leader>ji',
                function()
                    vim.cmd('AI99Put')
                end,
                desc = '99 put at cursor',
                mode = 'n',
            },
            {
                '<leader>jm',
                function()
                    require('99.extensions.telescope').select_model()
                end,
                desc = '99 select model',
                mode = 'n',
            },
            {
                '<leader>jp',
                function()
                    require('99.extensions.telescope').select_provider()
                end,
                desc = '99 select provider',
                mode = 'n',
            },
        },
        opts = function()
            local cwd = vim.uv.cwd() or vim.fn.getcwd()
            local basename = vim.fs.basename(cwd)

            local _99 = require('99')
            local PiProvider = setmetatable({}, { __index = _99.Providers.BaseProvider })

            function PiProvider._build_command(_, query, context)
                local script = table.concat({
                    'tmp=$1; model=$2; query=$3',
                    'unset NVIM NVIM_LISTEN_ADDRESS',
                    'pi --print --no-session --model "$model" "$query" &',
                    'pid=$!',
                    'for _ in $(seq 1 180); do',
                    '  if [ -s "$tmp" ]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; exit 0; fi',
                    '  if ! kill -0 "$pid" 2>/dev/null; then wait "$pid"; code=$?; [ -s "$tmp" ] && exit 0 || exit "$code"; fi',
                    '  sleep 1',
                    'done',
                    'kill "$pid" 2>/dev/null || true',
                    'wait "$pid" 2>/dev/null || true',
                    '[ -s "$tmp" ] && exit 0 || exit 124',
                }, '\n')

                return {
                    'bash',
                    '-lc',
                    script,
                    '99-pi',
                    context.tmp_file,
                    context.model,
                    query,
                }
            end

            function PiProvider._get_provider_name()
                return 'PiProvider'
            end

            function PiProvider._get_default_model()
                return 'openai-codex/gpt-5.5'
            end

            function PiProvider.fetch_models(callback)
                vim.system({ 'pi', '--list-models' }, { text = true }, function(obj)
                    vim.schedule(function()
                        if obj.code ~= 0 then
                            callback(nil, 'Failed to fetch models from pi')
                            return
                        end

                        local models = {}
                        for _, line in ipairs(vim.split(obj.stdout, '\n', { trimempty = true })) do
                            local id = line:match('^%s*([^%s]+)')
                            if id and id ~= '' and id ~= 'Provider' and not id:match('^[-=]+$') then
                                table.insert(models, id)
                            end
                        end
                        callback(models, nil)
                    end)
                end)
            end

            _99.Providers.PiProvider = PiProvider

            return {
                logger = {
                    level = _99.INFO,
                    path = '/tmp/' .. basename .. '.99.debug',
                    print_on_error = true,
                },
                tmp_dir = './tmp',
                md_files = {
                    'AGENT.md',
                    'AGENTS.md',
                    'CLAUDE.md',
                },
                completion = {
                    source = 'blink',
                    custom_rules = {
                        vim.fn.expand('~/.config/pi/agent/skills'),
                    },
                    files = {
                        enabled = true,
                    },
                },
                provider = _99.Providers.PiProvider,
                model = _99.Providers.PiProvider._get_default_model(),
            }
        end,
        config = function(_, opts)
            local _99 = require('99')
            _99.setup(opts)

            local function run_99_put(user_prompt)
                local buf = vim.api.nvim_get_current_buf()
                local cursor = vim.api.nvim_win_get_cursor(0)
                local row, col = cursor[1] - 1, cursor[2]
                local file = vim.api.nvim_buf_get_name(buf)
                local ft = vim.bo[buf].filetype
                local start_row = math.max(0, row - 30)
                local end_row = math.min(vim.api.nvim_buf_line_count(buf), row + 80)
                local context = table.concat(vim.api.nvim_buf_get_lines(buf, start_row, end_row, false), '\n')
                local tmp = vim.fn.tempname()
                local model = _99.get_model()
                local query = table.concat({
                    'You are implementing code for insertion at the current cursor position.',
                    'Write ONLY the text to insert into TEMP_FILE. No markdown fences. No commentary.',
                    '<TEMP_FILE>' .. tmp .. '</TEMP_FILE>',
                    '<FILE>' .. file .. '</FILE>',
                    '<FILETYPE>' .. ft .. '</FILETYPE>',
                    '<CURSOR_LINE>' .. cursor[1] .. '</CURSOR_LINE>',
                    '<CURSOR_COLUMN>' .. (col + 1) .. '</CURSOR_COLUMN>',
                    '<SURROUNDING_CONTEXT>',
                    context,
                    '</SURROUNDING_CONTEXT>',
                    '<USER_PROMPT>',
                    user_prompt,
                    '</USER_PROMPT>',
                }, '\n')
                local script = table.concat({
                    'tmp=$1; model=$2; query=$3',
                    'unset NVIM NVIM_LISTEN_ADDRESS',
                    'pi --print --no-session --model "$model" "$query" >/dev/null &',
                    'pid=$!',
                    'for _ in $(seq 1 180); do',
                    '  if [ -s "$tmp" ]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; exit 0; fi',
                    '  if ! kill -0 "$pid" 2>/dev/null; then wait "$pid"; code=$?; [ -s "$tmp" ] && exit 0 || exit "$code"; fi',
                    '  sleep 1',
                    'done',
                    'kill "$pid" 2>/dev/null || true',
                    'wait "$pid" 2>/dev/null || true',
                    '[ -s "$tmp" ] && exit 0 || exit 124',
                }, '\n')

                vim.notify('99 put: generating…')
                vim.system({ 'bash', '-lc', script, '99-put', tmp, model, query }, { text = true }, function(obj)
                    vim.schedule(function()
                        if obj.code ~= 0 then
                            vim.notify('99 put failed: exit ' .. obj.code .. '\n' .. (obj.stderr or ''), vim.log.levels.ERROR)
                            return
                        end
                        local ok, lines = pcall(vim.fn.readfile, tmp)
                        if not ok or not lines or #lines == 0 then
                            vim.notify('99 put: empty result', vim.log.levels.WARN)
                            return
                        end
                        vim.api.nvim_buf_set_text(buf, row, col, row, col, lines)
                        vim.notify('99 put: inserted')
                    end)
                end)
            end

            vim.api.nvim_create_user_command('AI99Put', function(args)
                local prompt = table.concat(args.fargs or {}, ' ')
                if prompt ~= '' then
                    run_99_put(prompt)
                    return
                end

                local Window = require('99.window')
                local Extensions = require('99.extensions')
                local state = _99.__get_state()
                Window.capture_input('Put', {
                    keymap = {
                        [':w'] = 'submit',
                    },
                    rules = state.rules,
                    cb = function(ok, input)
                        if ok and input and vim.trim(input) ~= '' then
                            run_99_put(input)
                        end
                    end,
                    on_load = function()
                        Extensions.setup_buffer(state)
                    end,
                })
            end, { desc = 'Generate text at cursor with 99/Pi', nargs = '*' })

            vim.api.nvim_create_user_command('AI99Search', function()
                require('99').search()
            end, { desc = 'Run 99 search' })

            vim.api.nvim_create_user_command('AI99Vibe', function()
                require('99').vibe()
            end, { desc = 'Run 99 vibe' })

            vim.api.nvim_create_user_command('AI99Tutorial', function()
                require('99').tutorial()
            end, { desc = 'Run 99 tutorial' })

            vim.api.nvim_create_user_command('AI99Open', function()
                require('99').open()
            end, { desc = 'Open 99 history' })
        end,
    },
}
