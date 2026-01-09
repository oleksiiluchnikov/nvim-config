-- lua/plugins/codecompanion/prompt_library/git.lua
-- Git-related prompts

return {
    ['Detailed Commit Message'] = {
        strategy = 'chat',
        description = 'Generate a detailed conventional commit message from git diff',
        opts = {
            index = 20,
            short_name = 'detailcommit',
            auto_submit = true,
            user_prompt = false,
        },
        prompts = {
            {
                role = 'system',
                content = [[
# Conventional Commit Format

## Types
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, missing semi-colons etc)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvements
- `test`: Adding or correcting tests
- `build`: Changes to build system or dependencies
- `ci`: Changes to CI configuration
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

## Rules
[[
# Conventional Commit Format

## Types
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, missing semi-colons etc)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvements
- `test`: Adding or correcting tests
- `build`: Changes to build system or dependencies
- `ci`: Changes to CI configuration
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

## Rules
1. Use imperative mood in subject ("add" not "added" or "adds")
2. Don't capitalize first letter of subject
3. No period at the end of subject
4. Subject line max 50 characters
5. Body wraps at 72 characters
6. Body explains WHAT and WHY, not HOW
7. Separate subject from body with blank line
8. Use footer for breaking changes (BREAKING CHANGE:) or issue references

## Task
Analyze the git diff provided and generate a detailed conventional commit message that:
- Accurately describes all changes
- Groups related changes logically
- Explains the honest motivation behind changes
- Includes relevant context
- Follows the specification exactly
- Is professional and clear
- No yapping.

### Before Generating Conventional Commits:

1. **Verify the context:**
   - Run `git status` to see what's staged if not provided
   - Run `git add .` if nothing staged
   - Run `git diff --staged` if not provided
   - Check current branch with `git branch --show-current`

2. **Assess commit scope:**
   - If changes span multiple unrelated concerns, they should be split into logical separate commits
   - If changes are too granular, squash

3. **Determine commit type priority:**
   - If a diff contains both feat and fix, the breaking/most significant change determines the type
   - Document secondary changes in the body

4. **Balance verbosity:**
   - Body should be detailed but scannable
   - Each bullet point should add unique value
   - Avoid redundancy between subject and body
   - Consider the audience (solo dev vs. team vs. OSS)

5. **Confirm before executing:**
   - For multi-file changes, summarize what will be committed
   - For main/master branch, double-check intent
   - For potentially breaking changes, explicitly confirm
]],
                opts = {
                    visible = false,
                },
            },
            {
                role = 'user',
                content = function()
                    -- Get git diff
                    local handle =
                        io.popen('git diff --cached 2>&1 || git diff 2>&1')
                    if not handle then
                        return 'Error: Could not execute git diff command'
                    end
                    local diff = handle:read('*a')
                    handle:close()

                    if not diff or diff == '' then
                        return 'Error: No changes detected. Stage your changes with `git add` or make sure you\'re in a git repository.'
                    end

                    -- Check if it's an error message
                    if
                        diff:match('fatal:')
                        or diff:match('not a git repository')
                    then
                        return 'Error: ' .. diff
                    end

                    return 'Here is the git diff:\n\n```diff\n'
                        .. diff
                        .. '\n```\n\nPlease generate a detailed conventional commit message for these changes and use @{cmd_runner} to run the command to commit them.'
                end,
                opts = {
                    contains_code = true,
                },
            },
        },
    },
    ['Quick Commit Message'] = {
        strategy = 'inline',
        description = 'Generate a quick conventional commit message',
        opts = {
            index = 21,
            short_name = 'qcommit',
            placement = 'new',
        },
        prompts = {
            {
                role = 'system',
                content = 'You generate concise conventional commit messages. Return ONLY the commit message, no explanations or markdown.',
            },
            {
                role = 'user',
                content = function()
                    local handle =
                        io.popen('git diff --cached 2>&1 || git diff 2>&1')
                    if not handle then
                        return 'Error: Could not execute git diff'
                    end
                    local diff = handle:read('*a')
                    handle:close()

                    if not diff or diff == '' then
                        return 'Error: No changes detected'
                    end

                    return 'Generate a conventional commit message:\n\n```diff\n'
                        .. diff
                        .. '\n```'
                end,
                opts = {
                    contains_code = true,
                },
            },
        },
    },
    ['Git PR Description'] = {
        strategy = 'chat',
        description = 'Generate a pull request description from git diff',
        opts = {
            index = 22,
            short_name = 'pr',
            auto_submit = true,
        },
        prompts = {
            {
                role = 'system',
                content = [[Generate a comprehensive pull request description that includes:
Summary
Brief overview of changes
Changes
    •	Bullet points of key changes 	•	Organized by type (features, fixes, refactors)
Testing
    •	How to test these changes 	•	Any new tests added
Notes
    •	Breaking changes (if any) 	•	Migration steps (if any) 	•	Related issues/PRs]],
                opts = {
                    visible = false,
                },
            },
            {
                role = 'user',
                content = function()
                    local handle = io.popen(
                        'git diff origin/main...HEAD 2>&1 || git diff 2>&1'
                    )
                    if not handle then
                        return 'Error: Could not get diff'
                    end
                    local diff = handle:read('*a')
                    handle:close()
                    return 'Generate a PR description for:\n\ndiff\n'
                        .. diff
                        .. '\n'
                end,
                opts = {
                    contains_code = true,
                },
            },
        },
    },
}
