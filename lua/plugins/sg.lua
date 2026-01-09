-- [sg.nvim](https://github.com/sourcegraph/sg.nvim)
-- Sourcegraph is a code search and intelligence platform for developers.
-- It has amazing AI chat Cody
----------------------------------------------------------------------
return {
    {
        'sourcegraph/sg.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        config = function()
            --- @type sg.config
            local opts = {
                on_attach = on_attach_lsp,
                --- @type sg.config.chat
                chat = {
                    default_model = 'anthropic/claude-3-5-sonnet-20241022',
                    -- default_model = 'anthropic/claude-3-haiku-20240317',
                    -- default_model = 'openai/gpt-4o',
                },
            }
            -- TODO: Custom telescope picker for models
            -- Init Cody
            -- Then we need to create the autogroup
            require('sg').setup(opts)

            -- -- Then we need to create the autocommand
            -- vim.api.nvim_create_autocmd({ 'BufEnter' }, {
            --     pattern = '*',
            --     callback = function()
            --         -- First we need to get the width of the screen
            --         local screen_width = vim.api.nvim_list_uis()[1].width
            --         local width = math.floor(screen_width * 0.5)
            --
            --         -- Then we need to calculate the width of the floating window
            --         local win = vim.api.nvim_get_current_win()
            --         local buf = vim.api.nvim_win_get_buf(win)
            --         -- if current buffer has "Cody History" in it's name
            --         local bufname = vim.api.nvim_buf_get_name(buf)
            --         if not string.find(bufname, 'Cody History') then
            --             return
            --         end
            --         vim.api.nvim_win_set_width(0, width)
            --     end,
            -- })

            -- If the current buffer is a floating window
            -- then place align in to the bootom of the screen
            vim.api.nvim_create_autocmd({ 'BufEnter' }, {
                pattern = '*',
                callback = function()
                    -- Detect if the current buffer is a floating window
                    local win = vim.api.nvim_get_current_win()
                    local buf = vim.api.nvim_win_get_buf(win)
                    -- if current buffer has "Cody History" in it's name
                    local bufname = vim.api.nvim_buf_get_name(buf)
                    if not string.find(bufname, 'Cody History') then
                        return
                    end

                    -- First we need to get the width of the screen
                    local screen_width = vim.api.nvim_list_uis()[1].width
                    local screen_height = vim.api.nvim_list_uis()[1].height
                    local width = math.floor(screen_width * 0.8)
                    local height = math.floor(screen_height * 0.3)

                    -- Then we need to calculate the width of the floating window
                    vim.api.nvim_win_set_width(0, width)
                    vim.api.nvim_win_set_height(0, height)
                    vim.api.nvim_win_set_config(0, {
                        relative = 'editor',
                        row = 0,
                        col = 0,
                    })
                end,
            })

            local cody = require('sg.cody.commands')
            local utils = require('config.utils')

            local function get_cody_answer()
                local bufnr = vim.api.nvim_get_current_buf()
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                for i, line in ipairs(lines) do
                    lines[i] = nil
                    if line:match('^%s*```.*$') then
                        lines[i] = nil
                        break
                    end
                end
                --- set height of the window to the number of lines in the buffer
                --- replace the content of the buffer with the lines
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines or {})
            end

            --- Shorten type error
            ---@return nil
            local function shorten_type_error()
                -- Use a local variable to store the instruction string
                local instruction =
                    'Clearly explain this diagnostic from LSP request for `%s` code in details and how to fix it:\n%s\nRemove all unnecessary noise. No yapping!\n\n'

                ---@type vim.Diagnostic[]
                local diagnostic = vim.diagnostic.get(0)
                if next(diagnostic) == nil then
                    return
                end

                -- Jump to the first diagnostic
                vim.api.nvim_win_set_cursor(0, { diagnostic[1].lnum, 0 })

                -- Get the filetype and append the Lua version if it's Lua
                local filetype = vim.bo.filetype
                if filetype == 'lua' then
                    filetype = filetype .. ' ' .. utils.lua.get_version()
                end
                local prompt_instruction = string.format(
                    instruction,
                    filetype,
                    vim.inspect(diagnostic[1])
                ) .. '\n\n' .. diagnostic[1].message

                local bufnr = vim.api.nvim_get_current_buf()
                cody.do_task(bufnr, 0, 0, prompt_instruction)
                vim.defer_fn(function()
                    get_cody_answer()
                end, 3000)
            end

            -- Commands
            vim.api.nvim_create_user_command('CodyShortenTypeError', function()
                shorten_type_error()
            end, {
                nargs = 0,
            })

            --- Improve prompt instruction for `Cody`.
            --- @param start_line number
            --- @param end_line number
            --- @returns nil
            local function improve_prompt_instruction(start_line, end_line)
                local instruction = [=[
            Please rewrite following prompt instruction to:
            - Clearly state the specific task or goal
            - Provide necessary context, guidelines, and requirements for LLM model
            - Include concrete examples if helpful in <example> XML tag
            - Be clear, concise, and detailed for easy following. No yapping!
            - Improve on the current prompt with more details and specificity
            - Let me know if any part of the prompt needs clarification.
            - If you don't know how to answer, just say "I don't know".

            Return optimal prompt instruction. Keep it short and sweet. No yapping!
            Here is the prompt string you need to improve:
            <string-to-improve>
            ]=]

                local prompt_instruction =
                    string.format(instruction, vim.bo.filetype)
                local bufnr = vim.api.nvim_get_current_buf()
                cody.do_task(bufnr, start_line, end_line, prompt_instruction)
            end

            vim.api.nvim_create_user_command(
                'CodyImprovePromptInstruction',
                function()
                    local start_line, end_line =
                        require('config.utils.buf').get_selection_lines()
                    improve_prompt_instruction(start_line, end_line)
                end,
                {
                    nargs = 0,
                    range = true,
                }
            )

            --- Generate commit message for current changes
            local function generate_commit_message()
                local instruction = [=[
            Cody, generate a commit message for the current changes.

            You are provided the following staged changes:

            %s

            Please generate a commit message that:

            - Concisely summarizes the changes in the diff
            - Uses conventional commit types like feat, fix, docs etc.
            - Omits minor or unnecessary details
            - Follows Conventional Commits spec: https://www.conventionalcommits.org/

            The commit message should:
            - Be short, clear and easy to understand
            - Explain what was changed and why
            - Follow best practices for formatting and style

            Bellow suggest more optimal prompt instruction for this task.
            ]=]

                local git_diff = vim.fn.system('git diff --staged')
                cody.do_task(
                    vim.api.nvim_get_current_buf(),
                    0,
                    1,
                    string.format(instruction, git_diff)
                )
            end

            vim.api.nvim_create_user_command(
                'CodyGenerateCommitMessage',
                function()
                    generate_commit_message()
                end,
                {
                    nargs = 0,
                }
            )

            ---@param start_line number
            ---@param end_line number
            local function add_lua_type_annotations(start_line, end_line)
                -- read ~/prompts/lua_type_annotations.xml
                --     local instruction = [=[
                -- Hey, Cody! Let make you to act as a Senior Type Annotator for the Lua code.
                -- Here the guide page where you could see how I want the code to be annotated:
                -- ```markdown
                -- %s
                -- ```
                -- ---
                -- Generate type annotations with following recommendations:
                -- - Follow neovim community conventions for type annotations.
                -- - Add a general comment above the code snippet to explain the purpose of the code.
                -- - if function void, then add return type `nil`
                -- - Do not add type annotations for function calls, only for function definitions.
                -- - Add type annotations for all function arguments and return values.
                -- - Keep type annotations above the function definition.
                -- - Do not add newlines!
                -- - Update only the provided code snippet.
                -- ]=]

                local homedir = os.getenv('HOME')
                local path = homedir .. '/prompts/lua-type-annotations.xml'
                local f = io.open(path, 'r')
                if not f then
                    vim.notify(
                        'Could not open file: ' .. path,
                        vim.log.levels.ERROR
                    )
                    return
                end
                local v = f:read('*a')
                local instruction = string.format(v, vim.bo.filetype)
                local guide = vim.fn.readfile(
                    vim.fn.stdpath('config')
                        .. '/prompts/lua_type_annotations.txt'
                )
                local prompt_instruction =
                    string.format(instruction, table.concat(guide, '\n'))
                local bufnr = vim.api.nvim_get_current_buf()
                local selected_lines = vim.api.nvim_buf_get_lines(
                    bufnr,
                    start_line - 1,
                    end_line,
                    false
                )
                vim.notify(table.concat(selected_lines, '\n'))
                cody.do_task(
                    bufnr,
                    start_line - 1,
                    end_line,
                    prompt_instruction
                )
            end

            vim.api.nvim_create_user_command(
                'CodyAddTypeAnnotations',
                function()
                    local start_line, end_line =
                        require('config.utils.buf').get_selection_lines()
                    add_lua_type_annotations(start_line, end_line)
                end,
                {
                    nargs = 0,
                    range = true,
                }
            )

            -- Ask Cody to optiviaze the chunk of code to make it blazing fast, and more idiomatic.
            local function optimize_lua_code(start_line, end_line)
                local instruction = [=[
            Cody, optimize only the provided code snippet.
            Keep in mind that this is a small part of a larger codebase.
            So you should not change any existing code, only optimize the provided snippet.
            Or suggest a better way to do it, unless you see is already perfect.

            Please optimize this chunk of code:

            - Performance - use optimal algorithms and data structures. Avoid unnecessary loops, recursion, and other complex code
            - Readability - follow %s style guides and conventions
            - Specifically for Lua:
            - If you see `vim` that means that lua code is using neovim.API. Then its "LuaJIT" flavor is used.
            - Add type annotations and documentation to support the Lua language server from sumneko.
            - Add usage example in comments with asserts above the function.
            ---local notes = Notes():with_title_mismatched()
            ---local note = notes:get_random_note()
            ---assert(note.data.title ~= note.data.stem)

            - Maintainability - modularize into focused functions with docs. Avoid global variables and other anti-patterns.
            - Clarity - add types and comments explaining complex sections. If it's not clear, it's not optimized!
            - Formatting - proper indentation, whitespace, 100 char line length, etc.

            The optimized code should:
            - Be blazing fast. Performance is the top priority!
            - Be idiomatic and conform to %s best practices.
            - Have logical, modular functions and components, but don't do dumb wrappings and other anti-patterns.
            - Contain annotations and docs for understanding complex sections.
            - Explain optimizations in comments above the code if it's not obvious.
            - Be properly formatted and indented

            Give the explanation for the optimizations you made in mulitline comment above the code.
            Let me know if any part of the prompt needs clarification!
            Like in this example:
            "Optimizations:

            - Use string.format instead of concatenation for performance
            - Cache the osascript command format string since it doesn't change
            - Use vim.cmd over vim.fn.system since we don't need the output
            - Add comments explaining the purpose and optimizations
            ]=]
                local filetype = vim.bo.filetype
                if filetype == 'lua' then
                    filetype = filetype
                        .. ' '
                        .. require('config.utils').get_version()
                end
                local prompt_instruction = string.format(
                    instruction,
                    filetype,
                    filetype,
                    filetype,
                    filetype
                )

                local bufnr = vim.api.nvim_get_current_buf()
                cody.do_task(bufnr, start_line, end_line, prompt_instruction)
            end

            vim.api.nvim_create_user_command('CodyOptimizeCode', function()
                optimize_lua_code(
                    require('config.utils.buf').get_selection_lines()
                )
            end, {
                nargs = 0,
                range = true,
            })

            local function improve_documentation(start_line, end_line)
                local instruction = [=[
        Cody, improve documentation for the provided code snippet.

        Please improve documentation for this chunk of code:

        ]=]
                local prompt_instruction =
                    string.format(instruction, vim.bo.filetype)
                cody.do_task(
                    vim.api.nvim_get_current_buf(),
                    start_line,
                    end_line,
                    prompt_instruction
                )
            end

            vim.api.nvim_create_user_command(
                'CodyImproveDocumentation',
                function()
                    improve_documentation(
                        require('config.utils.buf').get_selection_lines()
                    )
                end,
                {
                    nargs = 0,
                    range = true,
                }
            )

            local function cody_hard_reset()
                vim.cmd('q!')
                vim.cmd('CodyRestart')
            end

            vim.api.nvim_create_user_command('CodyReset', function()
                cody_hard_reset()
            end, {
                nargs = 0,
            })

            --- Sometimes I have a code snippet where "--to be implemented" is written.
            --- or "TODO: implement this function"
            --- or any other comment that indicates that this code is not ready.
            --- Maybe there only human only comments like "We do this yada yada yada"
            --- So I want to ask Cody to try to implement this code with explanation,
            --- and focus on blazing fast performance.

            vim.api.nvim_create_user_command(
                'CodySolveCommentedInstruction',
                function()
                    local start_line, end_line =
                        require('config.utils.buf').get_selection_lines()
                    -- The good prompt instruction for this task is:
                    local instruction = [=[
        Cody, implement the commented code snippet.
        Keep in mind that this is a small part of a larger codebase.
        So you should not change any existing code, only implement the provided snippet.
        Or suggest a better way to do it, unless you see is already perfect.
        Focus on blazing fast performance and best practices for that language, and community conventions.

        Please implement this chunk of code:

        ]=]
                    local prompt_instruction =
                        string.format(instruction, vim.bo.filetype)
                    local bufnr = vim.api.nvim_get_current_buf()
                    cody.do_task(
                        bufnr,
                        start_line,
                        end_line,
                        prompt_instruction
                    )
                end,
                {
                    nargs = 0,
                    range = true,
                }
            )

            local function improve_performance(start_line, end_line)
                local instruction = [=[
    # Optimize %s code snippet for performance

    Task: Improve the performance of the provided %s code snippet by making it as fast as possible while adhering to idiomatic coding practices.

    Context:
    - The code snippet is a part of a larger codebase.
    - You should not modify any existing code outside the provided snippet.
    - If the existing code is already optimal, suggest a better way to achieve the same functionality.
    - Add comments above the changes to explain the optimizations made.

    Requirements:
    - Maintain the existing functionality of the code.
    - Ensure that the optimized code follows best and common practices and conventions for the %s language and is idiomatic.
    - Provide clear and concise comments explaining the optimizations made.
    - Define a naming convention of variables, functions, and classes of the original code and stay consistent with it.
    - If the existing code has type annotations, expand them to include the necessary type information for the optimized code.
    - Use early returns and short-circuit evaluation to improve performance.
    - At the end of the answer, append test function for it.

    Suggestions:
    - Use the existing code as a reference to optimize the provided code snippet.
    - Use the existing code as a guide to improve the performance of the provided code snippet.
    - Use the existing code as a starting point to optimize the provided code snippet.
    - Use the existing code as a benchmark to compare the performance of the optimized code snippet.
    - Use the existing code as a reference to identify areas that can be optimized in the provided code snippet.

    Provide the optimized Lua code snippet with clear and concise comments explaining the optimizations made. If the existing code is already optimal, suggest a better way to achieve the same functionality or provide a brief explanation stating that the code is already optimized. for
    ```
    ]=]
                local prompt_instruction = string.format(
                    instruction,
                    vim.bo.filetype,
                    vim.bo.filetype,
                    vim.bo.filetype
                )
                local bufnr = vim.api.nvim_get_current_buf()
                cody.do_task(bufnr, start_line, end_line, prompt_instruction)
            end

            vim.api.nvim_create_user_command('CodyBlazingFast', function()
                improve_performance(
                    require('config.utils.buf').get_selection_lines()
                )
            end, {
                nargs = 0,
                range = true,
            })

            -- Load the website content and convert the HTML content to Markdown format
            ---@param url string The URL of the website to load
            ---@return string?
            local function load_website_content(url)
                ---@type string?
                local content

                local handle = io.popen('curl -s ' .. url, 'r')
                if not handle then
                    return nil
                end

                content = handle:read('*a')
                handle:close()

                return content
            end

            --- Annotate lua code snippet with type annotations
            ---@param start_line integer
            ---@param end_line integer
            local function lua_annotate(start_line, end_line)
                ---@type string?
                local lua_type_annotations_doc = load_website_content(
                    'https://raw.githubusercontent.com/LuaLS/LuaLS.github.io/main/src/content/wiki/annotations.mdx'
                )
                if not lua_type_annotations_doc then
                    print('nil')
                    return
                end
                local bufnr = vim.api.nvim_get_current_buf()
                -- local prompt_instruction = 'TLDR ' .. lua_type_annotations_doc
                local prompt_instruction = [[
                <task>Improve the type annotations of the provided Lua code snippet by making them descriptive and easy to understand.</task>

                <context>
                <item>The code snippet is a part of a larger codebase.</item>
                <item>If the existing code is already optimally annotated, suggest a better way to achieve the same functionality.</item>
                <item>Add comments to the type annotations to explain them if they are ambiguous.</item>
                </context>

                <requirements>
                <item>Maintain the existing functionality of the code.</item>
                <item>Ensure that the optimized code follows best and common practices and conventions for the Lua language and is idiomatic.</item>
                <item>If the existing code has type annotations, expand them.</item>
                <item>Add examples with asserts.</item>
                </requirements>

                <example>
                ```lua
                --- The example to get a random example from.
                --- @param example Example -- The example to get a random example from.
                --- @return example Example -- The random example.
                --- ```lua
                --- local example = Example():with_title_mismatched()
                --- local example = example:get_random_example()
                ---
                --- assert(example.data.title ~= example.data.stem)
                --- ```
                local function get_random_example(example)
                    return example:get_random_example()
                end
                ```
                </example>

                <code_snippet>
                ```lua
                ]]
                prompt_instruction =
                    string.format(prompt_instruction, lua_type_annotations_doc)
                cody.do_task(
                    bufnr,
                    start_line - 1,
                    end_line,
                    prompt_instruction
                )
            end

            vim.api.nvim_create_user_command('CodyAnnotate', function()
                lua_annotate(require('config.utils.buf').get_selection_lines())
            end, {
                nargs = 0,
                range = true,
            })

            vim.api.nvim_create_user_command(
                'CodyRewriteCodeWithExample',
                function()
                    local start_line, end_line =
                        require('config.utils.buf').get_selection_lines()
                    local instruction = [=[
                [[ Task: Rewrite the provided code snippet in Lua to make it more readable, maintainable, and efficient.

                Context:
                - The code is a Lua script that performs some operations.
                - Aim to improve variable naming, code structure, and comments.
                - Optimize performance where possible without changing functionality.

                Requirements:
                - Preserve the original functionality of the code.
                - Use meaningful variable and function names following Lua conventions.
                - Add comments to explain complex or non-obvious sections of the code.
                - Split large functions into smaller, reusable functions if applicable.
                - Remove any unnecessary or redundant code.
                - Optimize performance-critical sections if possible.

                Example:
                <example>
                -- Original code
                a = 5
                b = 10
                c = a + b
                print(c) -- Output: 15
                </example>

                -- Improved code
                <example>
                -- Declare and initialize variables with meaningful names
                first_number = 5
                second_number = 10

                -- Calculate the sum
                sum = first_number + second_number

                -- Print the result
                print(sum) -- Output: 15
                </example>

                If any part of the prompt needs clarification, please let me know.
                If you don't know how to improve the code, simply respond with "I don't know".]=]

                    local prompt_instruction =
                        string.format(instruction, vim.bo.filetype)
                    local bufnr = vim.api.nvim_get_current_buf()
                    cody.do_task(
                        bufnr,
                        start_line,
                        end_line,
                        prompt_instruction
                    )
                end,
                {
                    nargs = 0,
                    range = true,
                }
            )

            vim.api.nvim_create_user_command('CodyDescribeRepo', function()
                -- -- Read all files in the current directory
                -- -- local files = vim.fn.readdir(utils.get_root_dir())
                -- local files = vim.fn.glob(utils.get_root_dir() .. '/**/*.lua', true, true)
                -- -- Filter out files that are not Lua files
                -- local lua_files = vim.tbl_filter(function(file)
                --     return string.match(file, '%.lua$')
                -- end, files)
                --
                -- -- Sort the files alphabetically
                -- table.sort(lua_files)
                --
                -- local modules = {}
                -- -- Print the files
                -- for _, file in ipairs(lua_files) do
                --     -- local module_name = string.match(file, '^.*/(.*)%.lua$')
                --     local module_name = string.match(file, '^.*/(.*)%.lua$')
                --     if module_name == 'init' or module_name == 'init_spec' then
                --         module_name = string.match(file, '^.*/(.*)/init.*%.lua$')
                --     end
                --     if not modules[module_name] then
                --         modules[module_name] = {}
                --     end
                --     local content = { '<lua-module-' .. module_name .. '>' }
                --     -- vim.tbl_extend('force', content, vim.fn.readfile(file))
                --     vim.list_extend(content, vim.fn.readfile(file))
                --     table.insert(content, '</lua-module-' .. module_name .. '>')
                --     table.insert(modules, table.concat(content, '\n'))
                -- end
                -- -- print(table.concat(modules, '\n'))
                -- local prompt_instruction = { 'Generate README.md for the current project.' }
                -- prompt_instruction = vim.tbl_extend('force', prompt_instruction, modules)
                -- cody.ask(prompt_instruction)
                -- -- cody.do_task(0, 0, 0, table.concat(prompt_instruction, '\n'))
            end, {
                nargs = '*',
            })
        end,
    },
}
