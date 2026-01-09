---@module 'snippets.ft.lua'
---@description Lua and Neovim-specific snippets

local u = require('snippets.utils')
local s, t, i, f, c = u.s, u.t, u.i, u.f, u.c
local fmt, fmta = u.fmt, u.fmta
local rep = u.rep

return {
	-- Module template
	s({ trig = 'module', name = 'Module', dscr = 'Lua module template' }, fmt([[
---@module '{}'
---@description {}
---@author {}
---@license MIT

local M = {{}}

{}

return M
]], {
		u.filename_node(false),
		i(1, 'Module description'),
		u.username_node(),
		i(0),
	})),

	-- Function with annotations
	s({ trig = 'fn', name = 'Function', dscr = 'Function with LSP annotations' }, fmt([[
---{}
---@param {} {} {}
---@return {} {}
function {}({})
	{}
end
]], {
		i(1, 'Description'),
		i(2, 'param'),
		i(3, 'type'),
		i(4, 'Description'),
		i(5, 'type'),
		i(6, 'Description'),
		i(7, 'function_name'),
		rep(2),
		i(0),
	})),

	-- Local function
	s({ trig = 'lfn', name = 'Local Function', dscr = 'Local function' }, fmt([[
local function {}({})
	{}
end
]], {
		i(1, 'function_name'),
		i(2, 'args'),
		i(0),
	})),

	-- Module function
	s({ trig = 'mfn', name = 'Module Function', dscr = 'Module function with annotations' }, fmt([[
---{}
---@param {} {} {}
---@return {} {}
function M.{}({})
	{}
end
]], {
		i(1, 'Description'),
		i(2, 'param'),
		i(3, 'type'),
		i(4, 'Description'),
		i(5, 'type'),
		i(6, 'Description'),
		i(7, 'method_name'),
		rep(2),
		i(0),
	})),

	-- Require
	s({ trig = 'req', name = 'Require', dscr = 'Require statement' }, fmt([[
local {} = require('{}')
]], {
		i(1, 'module'),
		i(2, 'module.path'),
	})),

	-- Protected require
	s({ trig = 'preq', name = 'Protected Require', dscr = 'Protected require with pcall' }, fmt([[
local ok, {} = pcall(require, '{}')
if not ok then
	{}
	return
end
]], {
		i(1, 'module'),
		rep(1),
		i(2, "vim.notify('Failed to load module', vim.log.levels.ERROR)"),
	})),

	-- Conditional
	s({ trig = 'if', name = 'If Statement', dscr = 'If statement' }, fmt([[
if {} then
	{}
end
]], {
		i(1, 'condition'),
		i(0),
	})),

	-- If-else
	s({ trig = 'ife', name = 'If-Else', dscr = 'If-else statement' }, fmt([[
if {} then
	{}
else
	{}
end
]], {
		i(1, 'condition'),
		i(2, '-- true branch'),
		i(0, '-- false branch'),
	})),

	-- For loop (numeric)
	s({ trig = 'for', name = 'For Loop', dscr = 'Numeric for loop' }, fmt([[
for {} = {}, {} do
	{}
end
]], {
		i(1, 'i'),
		i(2, '1'),
		i(3, 'n'),
		i(0),
	})),

	-- For loop (pairs)
	s({ trig = 'forp', name = 'For Pairs', dscr = 'For loop with pairs' }, fmt([[
for {}, {} in pairs({}) do
	{}
end
]], {
		i(1, 'key'),
		i(2, 'value'),
		i(3, 'table'),
		i(0),
	})),

	-- For loop (ipairs)
	s({ trig = 'fori', name = 'For IPairs', dscr = 'For loop with ipairs' }, fmt([[
for {}, {} in ipairs({}) do
	{}
end
]], {
		i(1, 'index'),
		i(2, 'value'),
		i(3, 'table'),
		i(0),
	})),

	-- Neovim autocommand
	s({ trig = 'autocmd', name = 'Autocommand', dscr = 'Neovim autocommand' }, fmt([[
vim.api.nvim_create_autocmd({}, {{
	group = {},
	pattern = {},
	callback = function()
		{}
	end,
}})
]], {
		c(1, {
			t("'FileType'"),
			t("'BufEnter'"),
			t("'BufWritePre'"),
			t("{ 'BufRead', 'BufNewFile' }"),
			i(nil, "'Event'"),
		}),
		i(2, 'augroup'),
		i(3, "'*'"),
		i(0),
	})),

	-- Neovim augroup
	s({ trig = 'augroup', name = 'Augroup', dscr = 'Create augroup' }, fmt([[
local {} = vim.api.nvim_create_augroup('{}', {{ clear = true }})
]], {
		i(1, 'group'),
		i(2, 'GroupName'),
	})),

	-- Keymap
	s({ trig = 'keymap', name = 'Keymap', dscr = 'Neovim keymap' }, fmt([[
vim.keymap.set({}, '{}', {}, {{ desc = '{}' }})
]], {
		c(1, {
			t("'n'"),
			t("'i'"),
			t("'v'"),
			t("'x'"),
			t("{ 'n', 'v' }"),
			i(nil, "'mode'"),
		}),
		i(2, '<leader>key'),
		i(3, 'function() end'),
		i(4, 'Description'),
	})),

	-- API options
	s({ trig = 'nvimopt', name = 'Neovim Option', dscr = 'Set Neovim option' }, fmt([[
vim.opt.{} = {}
]], {
		i(1, 'option'),
		i(2, 'value'),
	})),

	-- Vim notify
	s({ trig = 'notify', name = 'Notify', dscr = 'Vim notification' }, fmt([[
vim.notify('{}', vim.log.levels.{}, {{ title = '{}' }})
]], {
		i(1, 'Message'),
		c(2, {
			t('INFO'),
			t('WARN'),
			t('ERROR'),
			t('DEBUG'),
		}),
		i(3, 'Title'),
	})),

	-- Table
	s({ trig = 'tbl', name = 'Table', dscr = 'Table definition' }, fmt([[
local {} = {{
	{}
}}
]], {
		i(1, 'tbl'),
		i(0),
	})),

	-- LuaSnip snippet template
	s({ trig = 'snip', name = 'Snippet', dscr = 'LuaSnip snippet template' }, fmt([[
s({ trig = '{}', name = '{}', dscr = '{}' }, fmt([[
{}
]], {{
	{}
}})),
]], {
		i(1, 'trigger'),
		i(2, 'Name'),
		i(3, 'Description'),
		i(4, 'Template text with {}'),
		i(0, 'nodes'),
	})),
}
