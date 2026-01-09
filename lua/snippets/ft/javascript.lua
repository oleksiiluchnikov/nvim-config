---@module 'snippets.ft.javascript'
---@description JavaScript and TypeScript snippets

local u = require('snippets.utils')
local s, t, i, f, c = u.s, u.t, u.i, u.f, u.c
local fmt = u.fmt

return {
	-- Console logs
	s({ trig = 'cl', name = 'Console Log', dscr = 'console.log()' }, fmt([[
console.log({})
]], {
		i(1, 'value'),
	})),

	s({ trig = 'clo', name = 'Console Log Object', dscr = 'console.log with label' }, fmt([[
console.log('{}:', {})
]], {
		i(1, 'label'),
		i(2, 'value'),
	})),

	s({ trig = 'ce', name = 'Console Error', dscr = 'console.error()' }, fmt([[
console.error({})
]], {
		i(1, 'error'),
	})),

	s({ trig = 'cw', name = 'Console Warn', dscr = 'console.warn()' }, fmt([[
console.warn({})
]], {
		i(1, 'warning'),
	})),

	-- Functions
	s({ trig = 'fn', name = 'Function', dscr = 'Function declaration' }, fmt([[
function {}({}) {{
	{}
}}
]], {
		i(1, 'name'),
		i(2, 'params'),
		i(0),
	})),

	s({ trig = 'afn', name = 'Async Function', dscr = 'Async function' }, fmt([[
async function {}({}) {{
	{}
}}
]], {
		i(1, 'name'),
		i(2, 'params'),
		i(0),
	})),

	s({ trig = 'arrow', name = 'Arrow Function', dscr = 'Arrow function' }, fmt([[
const {} = ({}) => {{
	{}
}}
]], {
		i(1, 'name'),
		i(2, 'params'),
		i(0),
	})),

	s({ trig = 'arrowasync', name = 'Async Arrow', dscr = 'Async arrow function' }, fmt([[
const {} = async ({}) => {{
	{}
}}
]], {
		i(1, 'name'),
		i(2, 'params'),
		i(0),
	})),

	-- Imports/Exports
	s({ trig = 'imp', name = 'Import', dscr = 'ES6 import' }, fmt([[
import {} from '{}'
]], {
		i(1, 'module'),
		i(2, './module'),
	})),

	s({ trig = 'impd', name = 'Import Destructure', dscr = 'Import with destructuring' }, fmt([[
import {{ {} }} from '{}'
]], {
		i(1, 'exports'),
		i(2, './module'),
	})),

	s({ trig = 'req', name = 'Require', dscr = 'CommonJS require' }, fmt([[
const {} = require('{}')
]], {
		i(1, 'module'),
		i(2, './module'),
	})),

	s({ trig = 'exp', name = 'Export', dscr = 'ES6 export' }, fmt([[
export const {} = {}
]], {
		i(1, 'name'),
		i(2, 'value'),
	})),

	s({ trig = 'expd', name = 'Export Default', dscr = 'ES6 default export' }, fmt([[
export default {}
]], {
		i(1, 'value'),
	})),

	-- Control flow
	s({ trig = 'if', name = 'If Statement', dscr = 'If statement' }, fmt([[
if ({}) {{
	{}
}}
]], {
		i(1, 'condition'),
		i(0),
	})),

	s({ trig = 'ife', name = 'If-Else', dscr = 'If-else statement' }, fmt([[
if ({}) {{
	{}
}} else {{
	{}
}}
]], {
		i(1, 'condition'),
		i(2, '// true'),
		i(0, '// false'),
	})),

	s({ trig = 'ternary', name = 'Ternary', dscr = 'Ternary operator' }, fmt([[
{} ? {} : {}
]], {
		i(1, 'condition'),
		i(2, 'true'),
		i(3, 'false'),
	})),

	-- Loops
	s({ trig = 'for', name = 'For Loop', dscr = 'For loop' }, fmt([[
for (let {} = 0; {} < {}; {}++) {{
	{}
}}
]], {
		i(1, 'i'),
		u.same(1),
		i(2, 'length'),
		u.same(1),
		i(0),
	})),

	s({ trig = 'forof', name = 'For-Of Loop', dscr = 'For-of loop' }, fmt([[
for (const {} of {}) {{
	{}
}}
]], {
		i(1, 'item'),
		i(2, 'array'),
		i(0),
	})),

	s({ trig = 'forin', name = 'For-In Loop', dscr = 'For-in loop' }, fmt([[
for (const {} in {}) {{
	{}
}}
]], {
		i(1, 'key'),
		i(2, 'object'),
		i(0),
	})),

	-- Array methods
	s({ trig = 'map', name = 'Array Map', dscr = 'Array.map()' }, fmt([[
{}.map(({}) => {})
]], {
		i(1, 'array'),
		i(2, 'item'),
		i(0),
	})),

	s({ trig = 'filter', name = 'Array Filter', dscr = 'Array.filter()' }, fmt([[
{}.filter(({}) => {})
]], {
		i(1, 'array'),
		i(2, 'item'),
		i(0),
	})),

	s({ trig = 'reduce', name = 'Array Reduce', dscr = 'Array.reduce()' }, fmt([[
{}.reduce(({}, {}) => {}, {})
]], {
		i(1, 'array'),
		i(2, 'acc'),
		i(3, 'item'),
		i(4, 'acc'),
		i(5, 'initial'),
	})),

	s({ trig = 'foreach', name = 'Array ForEach', dscr = 'Array.forEach()' }, fmt([[
{}.forEach(({}) => {{
	{}
}})
]], {
		i(1, 'array'),
		i(2, 'item'),
		i(0),
	})),

	-- Promises
	s({ trig = 'promise', name = 'Promise', dscr = 'Promise constructor' }, fmt([[
new Promise((resolve, reject) => {{
	{}
}})
]], {
		i(0),
	})),

	s({ trig = 'then', name = 'Promise Then', dscr = 'Promise.then()' }, fmt([[
.then(({}) => {{
	{}
}})
]], {
		i(1, 'result'),
		i(0),
	})),

	s({ trig = 'catch', name = 'Promise Catch', dscr = 'Promise.catch()' }, fmt([[
.catch(({}) => {{
	{}
}})
]], {
		i(1, 'error'),
		i(0),
	})),

	-- Async/Await
	s({ trig = 'await', name = 'Await', dscr = 'Await expression' }, fmt([[
const {} = await {}
]], {
		i(1, 'result'),
		i(2, 'promise'),
	})),

	s({ trig = 'try', name = 'Try-Catch', dscr = 'Try-catch block' }, fmt([[
try {{
	{}
}} catch ({}) {{
	{}
}}
]], {
		i(1, '// try'),
		i(2, 'error'),
		i(0, '// catch'),
	})),

	-- Classes
	s({ trig = 'class', name = 'Class', dscr = 'Class declaration' }, fmt([[
class {} {{
	constructor({}) {{
		{}
	}}

	{}
}}
]], {
		i(1, 'ClassName'),
		i(2, 'params'),
		i(3, '// constructor body'),
		i(0),
	})),

	s({ trig = 'method', name = 'Method', dscr = 'Class method' }, fmt([[
{}({}) {{
	{}
}}
]], {
		i(1, 'methodName'),
		i(2, 'params'),
		i(0),
	})),

	-- Object literals
	s({ trig = 'obj', name = 'Object', dscr = 'Object literal' }, fmt([[
const {} = {{
	{}
}}
]], {
		i(1, 'obj'),
		i(0),
	})),

	-- Destructuring
	s({ trig = 'dest', name = 'Destructure', dscr = 'Object destructuring' }, fmt([[
const {{ {} }} = {}
]], {
		i(1, 'props'),
		i(2, 'object'),
	})),

	s({ trig = 'desta', name = 'Array Destructure', dscr = 'Array destructuring' }, fmt([[
const [{}] = {}
]], {
		i(1, 'items'),
		i(2, 'array'),
	})),

	-- Template literals
	s({ trig = 'tl', name = 'Template Literal', dscr = 'Template literal' }, fmt([[
`${{{}}}{}${{{}}}` 
]], {
		i(1, 'var'),
		i(2, ' text '),
		i(3, 'var'),
	})),
}
