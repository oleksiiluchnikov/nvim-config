-- lua/plugins/codecompanion/git_commit.lua
-- Single module for automated git committing

local M = {}

-- Tool definition
M.tool = {
    ['git_commit_file'] = {
        description = 'Stage and commit the current file with AI-generated commit message',
        callback = {
            name = 'git_commit_file',
            cmds = {
                function(self, args, input)
                    local file_path = args.file_path
                    local commit_message = args.commit_message

                    if not file_path or file_path == '' then
                        return {
                            status = 'error',
                            data = 'File path is required',
                        }
                    end

                    if not commit_message or commit_message == '' then
                        return {
                            status = 'error',
                            data = 'Commit message is required',
                        }
                    end

                    -- Stage file
                    local add_cmd =
                        string.format('git add "%s" 2>&1', file_path)
                    local add_handle = io.popen(add_cmd)
                    if not add_handle then
                        return {
                            status = 'error',
                            data = 'Failed to stage file',
                        }
                    end
                    local add_output = add_handle:read('*a')
                    add_handle:close()

                    -- Commit
                    local commit_cmd = string.format(
                        'git commit -m "%s" 2>&1',
                        commit_message:gsub('"', '\\"')
                    )
                    local commit_handle = io.popen(commit_cmd)
                    if not commit_handle then
                        return { status = 'error', data = 'Failed to commit' }
                    end
                    local commit_output = commit_handle:read('*a')
                    commit_handle:close()

                    -- Get commit hash
                    local hash_handle =
                        io.popen('git rev-parse --short HEAD 2>&1')
                    local commit_hash = hash_handle and hash_handle:read('*l')
                        or 'unknown'
                    if hash_handle then
                        hash_handle:close()
                    end

                    local success_msg = string.format(
                        '✓ Committed: %s\nHash: %s\nMessage: %s',
                        file_path,
                        commit_hash,
                        commit_message
                    )

                    return { status = 'success', data = success_msg }
                end,
            },
            schema = {
                type = 'function',
                ['function'] = {
                    name = 'git_commit_file',
                    description = 'Stage and commit a file with a commit message',
                    parameters = {
                        type = 'object',
                        properties = {
                            file_path = {
                                type = 'string',
                                description = 'File path relative to git root',
                            },
                            commit_message = {
                                type = 'string',
                                description = 'Conventional commit message',
                            },
                        },
                        required = { 'file_path', 'commit_message' },
                    },
                },
            },
            handlers = {
                setup = function(self, tools)
                    local handle = io.popen('git rev-parse --git-dir 2>&1')
                    if not handle then
                        return false
                    end
                    local output = handle:read('*a')
                    handle:close()
                    return not output:match('not a git repository')
                end,
            },
            output = {
                prompt = function(self, tools)
                    return string.format(
                        'Commit \'%s\' with:\n\n%s',
                        self.args.file_path,
                        self.args.commit_message
                    )
                end,
                success = function(self, tools, cmd, stdout)
                    vim.notify(
                        '✓ Committed: ' .. self.args.file_path,
                        vim.log.levels.INFO,
                        { title = 'Git' }
                    )
                    return tools.chat:add_tool_output(self, stdout[1])
                end,
                error = function(self, tools, cmd, stderr)
                    vim.notify(
                        '✗ Commit failed',
                        vim.log.levels.ERROR,
                        { title = 'Git' }
                    )
                    return tools.chat:add_tool_output(
                        self,
                        stderr[1] or 'Unknown error'
                    )
                end,
                rejected = function(self, tools, cmd)
                    return tools.chat:add_tool_output(
                        self,
                        'Commit rejected by user'
                    )
                end,
            },
            opts = {
                requires_approval = true,
            },
        },
    },
}

-- Prompt definition
M.prompt = {
    ['Auto Commit File'] = {
        strategy = 'chat',
        description = 'Automatically commit current file with AI-generated message',
        opts = {
            index = 25,
            short_name = 'autocommit',
            auto_submit = true,
        },
        prompts = {
            {
                role = 'system',
                content = [[You are a git commit expert. You will:
1. Analyze the git diff
2. Generate a conventional commit message
3. Use @{git_commit_file} to commit the file

Format: type(scope): subject

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore]],
                opts = { visible = false },
            },
            {
                role = 'user',
                content = function()
                    local file_path = vim.fn.expand('%:.')

                    -- Try cached diff first, then unstaged
                    local diff_cmd = string.format(
                        'git diff --cached -- "%s" 2>&1 || git diff -- "%s" 2>&1',
                        file_path,
                        file_path
                    )
                    local handle = io.popen(diff_cmd)
                    if not handle then
                        return 'Error: Could not get diff'
                    end
                    local diff = handle:read('*a')
                    handle:close()

                    if not diff or diff == '' then
                        return string.format(
                            'Error: No changes in %s',
                            file_path
                        )
                    end

                    return string.format(
                        'File: %s\n\nDiff:\n```diff\n%s\n```\n\nGenerate a commit message and use @{git_commit_file} to commit this file.',
                        file_path,
                        diff
                    )
                end,
                opts = { contains_code = true },
            },
        },
    },
}

return M
