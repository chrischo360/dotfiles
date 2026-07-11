vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "typewriter"
vim.o.termguicolors = true

local dark = vim.o.background == "dark"

local c = dark and {
  bg = "#262626",
  bg_alt = "#202020",
  bg_side = "#3a342e",
  bg_soft = "#303030",
  bg_float = "#2a2a2a",
  fg = "#c5b8a1",
  fg_dim = "#a99d89",
  muted = "#999999",
  faint = "#6f6f6f",
  border = "#44403a",
  selection = "#17304d",
  cursorline = "#2f352b",
  accent = "#519d5c",
  accent_soft = "#304832",
  red = "#d75f5f",
  orange = "#e87d3e",
  yellow = "#e5b567",
  green = "#b4d273",
  blue = "#6c99bb",
  cyan = "#78b6ad",
  purple = "#9e86c8",
} or {
  bg = "#fcf5e4",
  bg_alt = "#f6edd8",
  bg_side = "#e4dcc8",
  bg_soft = "#f2ead6",
  bg_float = "#fff8e8",
  fg = "#262626",
  fg_dim = "#444444",
  muted = "#595959",
  faint = "#9e9e9e",
  border = "#d7cdb8",
  selection = "#cce6ff",
  cursorline = "#edf4dc",
  accent = "#519d5c",
  accent_soft = "#dbe9d0",
  red = "#b54d4d",
  orange = "#c9632d",
  yellow = "#9d6d20",
  green = "#668a31",
  blue = "#3f7698",
  cyan = "#3f8b84",
  purple = "#7a60a8",
}

local none = "NONE"
local hi = function(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

hi("Normal", { fg = c.fg, bg = c.bg })
hi("NormalNC", { fg = c.fg_dim, bg = c.bg })
hi("NormalFloat", { fg = c.fg, bg = c.bg_float })
hi("FloatBorder", { fg = c.border, bg = c.bg_float })
hi("FloatTitle", { fg = c.accent, bg = c.bg_float, bold = true })
hi("ColorColumn", { bg = c.bg_alt })
hi("Cursor", { fg = c.bg, bg = c.fg })
hi("CursorLine", { bg = c.cursorline })
hi("CursorLineNr", { fg = c.accent, bg = c.cursorline, bold = true })
hi("LineNr", { fg = c.faint })
hi("SignColumn", { fg = c.faint, bg = c.bg })
hi("FoldColumn", { fg = c.faint, bg = c.bg })
hi("Folded", { fg = c.muted, bg = c.bg_alt })
hi("EndOfBuffer", { fg = c.bg })
hi("VertSplit", { fg = c.border, bg = c.bg })
hi("WinSeparator", { fg = c.border, bg = c.bg })
hi("StatusLine", { fg = c.fg, bg = c.bg_side })
hi("StatusLineNC", { fg = c.muted, bg = c.bg_alt })
hi("TabLine", { fg = c.muted, bg = c.bg_alt })
hi("TabLineFill", { bg = c.bg_alt })
hi("TabLineSel", { fg = c.fg, bg = c.bg, bold = true })
hi("Visual", { bg = c.selection })
hi("VisualNOS", { bg = c.selection })
hi("Search", { fg = c.bg, bg = c.yellow })
hi("IncSearch", { fg = c.bg, bg = c.orange })
hi("CurSearch", { fg = c.bg, bg = c.orange, bold = true })
hi("Substitute", { fg = c.bg, bg = c.orange })
hi("MatchParen", { fg = c.accent, bg = c.accent_soft, bold = true })
hi("NonText", { fg = c.faint })
hi("Whitespace", { fg = c.faint })
hi("SpecialKey", { fg = c.faint })
hi("Directory", { fg = c.blue })
hi("Title", { fg = c.fg, bold = true })
hi("Question", { fg = c.green })
hi("MoreMsg", { fg = c.green })
hi("ModeMsg", { fg = c.fg_dim })
hi("WarningMsg", { fg = c.orange })
hi("ErrorMsg", { fg = c.red })

hi("Pmenu", { fg = c.fg, bg = c.bg_float })
hi("PmenuSel", { fg = c.bg, bg = c.accent })
hi("PmenuSbar", { bg = c.bg_side })
hi("PmenuThumb", { bg = c.muted })
hi("WildMenu", { fg = c.bg, bg = c.accent })
hi("QuickFixLine", { bg = c.accent_soft, bold = true })

hi("Comment", { fg = c.faint, italic = true })
hi("Constant", { fg = c.orange })
hi("String", { fg = c.green })
hi("Character", { fg = c.green })
hi("Number", { fg = c.orange })
hi("Boolean", { fg = c.orange })
hi("Float", { fg = c.orange })
hi("Identifier", { fg = c.fg })
hi("Function", { fg = c.blue })
hi("Statement", { fg = c.purple })
hi("Conditional", { fg = c.purple })
hi("Repeat", { fg = c.purple })
hi("Label", { fg = c.purple })
hi("Operator", { fg = c.fg_dim })
hi("Keyword", { fg = c.purple })
hi("Exception", { fg = c.purple })
hi("PreProc", { fg = c.yellow })
hi("Include", { fg = c.purple })
hi("Define", { fg = c.purple })
hi("Macro", { fg = c.yellow })
hi("PreCondit", { fg = c.yellow })
hi("Type", { fg = c.yellow })
hi("StorageClass", { fg = c.yellow })
hi("Structure", { fg = c.yellow })
hi("Typedef", { fg = c.yellow })
hi("Special", { fg = c.blue })
hi("SpecialChar", { fg = c.orange })
hi("Tag", { fg = c.blue })
hi("Delimiter", { fg = c.fg_dim })
hi("SpecialComment", { fg = c.faint, italic = true })
hi("Debug", { fg = c.red })
hi("Underlined", { fg = c.blue, underline = true })
hi("Ignore", { fg = c.faint })
hi("Error", { fg = c.red })
hi("Todo", { fg = c.bg, bg = c.yellow, bold = true })

hi("@variable", { fg = c.fg })
hi("@variable.builtin", { fg = c.orange })
hi("@variable.parameter", { fg = c.fg_dim })
hi("@variable.member", { fg = c.fg })
hi("@constant", { fg = c.orange })
hi("@constant.builtin", { fg = c.orange })
hi("@constant.macro", { fg = c.yellow })
hi("@module", { fg = c.yellow })
hi("@label", { fg = c.purple })
hi("@string", { fg = c.green })
hi("@string.documentation", { fg = c.green })
hi("@string.regexp", { fg = c.cyan })
hi("@string.escape", { fg = c.orange })
hi("@character", { fg = c.green })
hi("@boolean", { fg = c.orange })
hi("@number", { fg = c.orange })
hi("@number.float", { fg = c.orange })
hi("@type", { fg = c.yellow })
hi("@type.builtin", { fg = c.yellow })
hi("@attribute", { fg = c.yellow })
hi("@property", { fg = c.fg })
hi("@function", { fg = c.blue })
hi("@function.builtin", { fg = c.blue })
hi("@function.call", { fg = c.blue })
hi("@function.macro", { fg = c.blue })
hi("@constructor", { fg = c.yellow })
hi("@operator", { fg = c.fg_dim })
hi("@keyword", { fg = c.purple })
hi("@keyword.coroutine", { fg = c.purple })
hi("@keyword.function", { fg = c.purple })
hi("@keyword.operator", { fg = c.purple })
hi("@keyword.import", { fg = c.purple })
hi("@keyword.type", { fg = c.purple })
hi("@keyword.modifier", { fg = c.purple })
hi("@keyword.repeat", { fg = c.purple })
hi("@keyword.return", { fg = c.purple })
hi("@keyword.debug", { fg = c.red })
hi("@keyword.exception", { fg = c.purple })
hi("@punctuation.delimiter", { fg = c.fg_dim })
hi("@punctuation.bracket", { fg = c.fg_dim })
hi("@punctuation.special", { fg = c.faint })
hi("@comment", { fg = c.faint, italic = true })
hi("@comment.documentation", { fg = c.faint, italic = true })
hi("@comment.error", { fg = c.red })
hi("@comment.warning", { fg = c.orange })
hi("@comment.todo", { fg = c.yellow })
hi("@comment.note", { fg = c.blue })
hi("@markup.strong", { bold = true })
hi("@markup.italic", { italic = true })
hi("@markup.strikethrough", { strikethrough = true })
hi("@markup.underline", { underline = true })
hi("@markup.heading", { fg = c.fg, bold = true })
hi("@markup.heading.1", { fg = c.fg, bold = true })
hi("@markup.heading.2", { fg = c.fg, bold = true })
hi("@markup.heading.3", { fg = c.fg, bold = true })
hi("@markup.link", { fg = c.blue })
hi("@markup.link.label", { fg = c.blue })
hi("@markup.link.url", { fg = c.faint, underline = true })
hi("@markup.raw", { fg = c.green })
hi("@markup.list", { fg = c.accent })
hi("@tag", { fg = c.blue })
hi("@tag.attribute", { fg = c.yellow })
hi("@tag.delimiter", { fg = c.faint })

hi("DiagnosticError", { fg = c.red })
hi("DiagnosticWarn", { fg = c.orange })
hi("DiagnosticInfo", { fg = c.blue })
hi("DiagnosticHint", { fg = c.cyan })
hi("DiagnosticOk", { fg = c.green })
hi("DiagnosticVirtualTextError", { fg = c.red, bg = dark and "#3a2828" or "#f4dddd" })
hi("DiagnosticVirtualTextWarn", { fg = c.orange, bg = dark and "#3a3024" or "#f4e7cf" })
hi("DiagnosticVirtualTextInfo", { fg = c.blue, bg = dark and "#263342" or "#dcebf2" })
hi("DiagnosticVirtualTextHint", { fg = c.cyan, bg = dark and "#263a38" or "#dcefeb" })
hi("DiagnosticUnderlineError", { sp = c.red, undercurl = true })
hi("DiagnosticUnderlineWarn", { sp = c.orange, undercurl = true })
hi("DiagnosticUnderlineInfo", { sp = c.blue, undercurl = true })
hi("DiagnosticUnderlineHint", { sp = c.cyan, undercurl = true })

hi("DiffAdd", { fg = dark and "#d4e8bf" or "#385a1e", bg = dark and "#33402c" or "#dfeccc" })
hi("DiffChange", { fg = dark and "#ecd09b" or "#6b4f18", bg = dark and "#403628" or "#efe1bf" })
hi("DiffDelete", { fg = dark and "#eba0a0" or "#7f3030", bg = dark and "#402c2c" or "#efd7d3" })
hi("DiffText", { fg = dark and "#f3d39a" or "#4b3510", bg = dark and "#594222" or "#e8c77f", bold = true })
hi("DiffAdded", { link = "DiffAdd" })
hi("DiffRemoved", { link = "DiffDelete" })
hi("DiffChanged", { link = "DiffChange" })
hi("DiffFile", { fg = c.blue, bold = true })
hi("DiffLine", { fg = c.faint })
hi("DiffIndexLine", { fg = c.purple })

hi("GitSignsAdd", { fg = c.green })
hi("GitSignsChange", { fg = c.yellow })
hi("GitSignsDelete", { fg = c.red })
hi("GitSignsAddNr", { fg = c.green })
hi("GitSignsChangeNr", { fg = c.yellow })
hi("GitSignsDeleteNr", { fg = c.red })
hi("GitSignsAddLn", { bg = dark and "#303a2b" or "#e5eed3" })
hi("GitSignsChangeLn", { bg = dark and "#3b352a" or "#eee2c5" })
hi("GitSignsDeleteLn", { bg = dark and "#3a2b2b" or "#eedbd7" })
hi("GitConflictCurrent", { bg = dark and "#303a2b" or "#e5eed3" })
hi("GitConflictIncoming", { bg = dark and "#263342" or "#dcebf2" })
hi("GitConflictAncestor", { bg = dark and "#3b352a" or "#eee2c5" })

hi("LspReferenceText", { bg = c.bg_soft })
hi("LspReferenceRead", { bg = c.bg_soft })
hi("LspReferenceWrite", { bg = c.bg_soft })
hi("LspSignatureActiveParameter", { fg = c.bg, bg = c.accent })
hi("@lsp.type.comment", {})
hi("@lsp.type.enum", { link = "@type" })
hi("@lsp.type.enumMember", { link = "@constant" })
hi("@lsp.type.interface", { link = "@type" })
hi("@lsp.type.keyword", { link = "@keyword" })
hi("@lsp.type.namespace", { link = "@module" })
hi("@lsp.type.parameter", { link = "@variable.parameter" })
hi("@lsp.type.property", { link = "@property" })
hi("@lsp.type.variable", { link = "@variable" })

hi("markdownHeadingDelimiter", { fg = c.faint })
hi("markdownH1", { fg = c.fg, bold = true })
hi("markdownH2", { fg = c.fg, bold = true })
hi("markdownH3", { fg = c.fg, bold = true })
hi("markdownH4", { fg = c.fg, bold = true })
hi("markdownH5", { fg = c.fg, bold = true })
hi("markdownH6", { fg = c.fg, bold = true })
hi("markdownCode", { fg = c.green, bg = c.bg_alt })
hi("markdownCodeBlock", { fg = c.green, bg = c.bg_alt })
hi("markdownCodeDelimiter", { fg = c.faint })
hi("markdownBlockquote", { fg = c.faint })
hi("markdownListMarker", { fg = c.accent })
hi("markdownOrderedListMarker", { fg = c.accent })
hi("markdownRule", { fg = c.border })
hi("markdownLinkText", { fg = c.blue })
hi("markdownUrl", { fg = c.faint, underline = true })
hi("markdownBold", { fg = c.fg, bold = true })
hi("markdownItalic", { fg = c.fg_dim, italic = true })

hi("RenderMarkdownH1Bg", { bg = c.accent_soft, fg = c.fg, bold = true })
hi("RenderMarkdownH2Bg", { bg = dark and "#2a3841" or "#dcebf2", fg = c.fg, bold = true })
hi("RenderMarkdownH3Bg", { bg = dark and "#3b3026" or "#efe1bf", fg = c.fg, bold = true })
hi("RenderMarkdownH4Bg", { bg = dark and "#332d3e" or "#e6def0", fg = c.fg, bold = true })
hi("RenderMarkdownH5Bg", { bg = dark and "#263a38" or "#dcefeb", fg = c.fg, bold = true })
hi("RenderMarkdownH6Bg", { bg = c.bg_alt, fg = c.fg, bold = true })
hi("RenderMarkdownCode", { bg = c.bg_alt })
hi("RenderMarkdownCodeInline", { fg = c.green, bg = c.bg_alt })
hi("RenderMarkdownBullet", { fg = c.accent })
hi("RenderMarkdownDash", { fg = c.border })
hi("RenderMarkdownQuote", { fg = c.faint })
hi("RenderMarkdownTodoUnchecked", { fg = c.blue })
hi("RenderMarkdownTodoChecked", { fg = c.green, strikethrough = true })

hi("TelescopeNormal", { fg = c.fg, bg = c.bg_float })
hi("TelescopeBorder", { fg = c.border, bg = c.bg_float })
hi("TelescopePromptNormal", { fg = c.fg, bg = c.bg_soft })
hi("TelescopePromptBorder", { fg = c.border, bg = c.bg_soft })
hi("TelescopePromptTitle", { fg = c.bg, bg = c.accent, bold = true })
hi("TelescopePreviewTitle", { fg = c.bg, bg = c.blue, bold = true })
hi("TelescopeResultsTitle", { fg = c.bg, bg = c.bg_side })
hi("TelescopeSelection", { fg = c.fg, bg = c.cursorline })
hi("TelescopeSelectionCaret", { fg = c.accent })
hi("TelescopeMatching", { fg = c.orange, bold = true })

hi("NeoTreeNormal", { fg = c.fg_dim, bg = c.bg_alt })
hi("NeoTreeNormalNC", { fg = c.fg_dim, bg = c.bg_alt })
hi("NeoTreeEndOfBuffer", { fg = c.bg_alt, bg = c.bg_alt })
hi("NeoTreeWinSeparator", { fg = c.border, bg = c.bg_alt })
hi("NeoTreeDirectoryIcon", { fg = c.blue })
hi("NeoTreeDirectoryName", { fg = c.blue })
hi("NeoTreeFileName", { fg = c.fg_dim })
hi("NeoTreeFileNameOpened", { fg = c.fg, bold = true })
hi("NeoTreeGitAdded", { fg = c.green })
hi("NeoTreeGitModified", { fg = c.yellow })
hi("NeoTreeGitDeleted", { fg = c.red })
hi("NeoTreeGitUntracked", { fg = c.orange })

hi("WhichKey", { fg = c.accent })
hi("WhichKeyGroup", { fg = c.blue })
hi("WhichKeyDesc", { fg = c.fg })
hi("WhichKeySeparator", { fg = c.faint })
hi("WhichKeyFloat", { bg = c.bg_float })
hi("LazyNormal", { fg = c.fg, bg = c.bg_float })
hi("MasonNormal", { fg = c.fg, bg = c.bg_float })
hi("OilDir", { fg = c.blue })
hi("OilDirIcon", { fg = c.blue })
hi("OilLink", { fg = c.purple })
hi("OilSocket", { fg = c.orange })
hi("OilOrphanLink", { fg = c.red })

hi("CmpItemAbbr", { fg = c.fg })
hi("CmpItemAbbrDeprecated", { fg = c.faint, strikethrough = true })
hi("CmpItemAbbrMatch", { fg = c.blue, bold = true })
hi("CmpItemAbbrMatchFuzzy", { fg = c.blue })
hi("CmpItemKind", { fg = c.purple })
hi("CmpItemMenu", { fg = c.faint })

hi("lualine_a_normal", { fg = c.bg, bg = c.accent, bold = true })
hi("lualine_b_normal", { fg = c.fg, bg = c.bg_side })
hi("lualine_c_normal", { fg = c.fg_dim, bg = c.bg_alt })
hi("lualine_a_insert", { fg = c.bg, bg = c.blue, bold = true })
hi("lualine_a_visual", { fg = c.bg, bg = c.purple, bold = true })
hi("lualine_a_replace", { fg = c.bg, bg = c.red, bold = true })
hi("lualine_a_command", { fg = c.bg, bg = c.yellow, bold = true })
hi("lualine_a_inactive", { fg = c.muted, bg = c.bg_alt })
hi("lualine_b_inactive", { fg = c.faint, bg = c.bg_alt })
hi("lualine_c_inactive", { fg = c.faint, bg = c.bg_alt })

vim.g.terminal_color_0 = dark and "#202020" or "#262626"
vim.g.terminal_color_1 = c.red
vim.g.terminal_color_2 = c.green
vim.g.terminal_color_3 = c.yellow
vim.g.terminal_color_4 = c.blue
vim.g.terminal_color_5 = c.purple
vim.g.terminal_color_6 = c.cyan
vim.g.terminal_color_7 = dark and "#c5b8a1" or "#e4dcc8"
vim.g.terminal_color_8 = c.faint
vim.g.terminal_color_9 = c.red
vim.g.terminal_color_10 = c.green
vim.g.terminal_color_11 = c.yellow
vim.g.terminal_color_12 = c.blue
vim.g.terminal_color_13 = c.purple
vim.g.terminal_color_14 = c.cyan
vim.g.terminal_color_15 = dark and "#f0e6d2" or "#fcf5e4"
