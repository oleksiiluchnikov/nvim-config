-- Simple prompt library - just merge and return
return vim.tbl_deep_extend(
    'force',
    require('plugins.codecompanion.prompt_library.git'),
    require('plugins.codecompanion.prompt_library.code'),
    require('plugins.codecompanion.prompt_library.documentation')
)
