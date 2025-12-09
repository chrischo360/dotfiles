-- Plugin: nvim-surround
-- Description: Add, delete, change surrounding characters (quotes, brackets, tags) around text.
--
-- ╔════════════════════════════════════════════════════════════════════════════╗
-- ║                        NVIM-SURROUND CHEAT SHEET                           ║
-- ╚════════════════════════════════════════════════════════════════════════════╝
--
-- MNEMONICS:
--   ys = "You Surround"    (add surround)
--   ds = "Delete Surround" (remove surround)
--   cs = "Change Surround" (replace surround)
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ NORMAL MODE - Add Surround                                              │
-- └─────────────────────────────────────────────────────────────────────────┘
--   ys{motion}{char}    You surround {motion} with {char}
--
--   Examples:
--     ysiw"     → surround inner word with "quotes"
--     ysiw'     → surround inner word with 'quotes'
--     ysiw)     → surround inner word with (parentheses)
--     ysiw]     → surround inner word with [brackets]
--     ysiw}     → surround inner word with {braces}
--     ysiwt     → surround inner word with <tag> (prompts for tag name)
--
--   Markdown shortcuts:
--     ysiwb     → surround inner word with **bold**
--     ysiwi     → surround inner word with _italic_
--     ysiwc     → surround inner word with `code`
--     ysiw*     → surround inner word with **bold** (alternative)
--     ysiw_     → surround inner word with _italic_ (alternative)
--
--   Line operations:
--     yss"      → surround entire line with "quotes"
--     ySS)      → surround line with (parens) and indent (capital S)
--
--   Other text objects:
--     ysap"     → surround a paragraph with "quotes"
--     ys$"      → surround from cursor to end of line
--     ysit"     → surround inner tag with "quotes"
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ VISUAL MODE - Add Surround                                              │
-- └─────────────────────────────────────────────────────────────────────────┘
--   1. Select text (v, V, or Ctrl-v)
--   2. Press S{char}
--
--   Examples:
--     viw → S"    → surround word with "quotes"
--     vap → S)    → surround paragraph with (parens)
--     V → Sb      → surround line with **bold**
--     v → Si      → surround selection with _italic_
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ DELETE Surround                                                         │
-- └─────────────────────────────────────────────────────────────────────────┘
--   ds{char}    Delete surrounding {char}
--
--   Examples:
--     ds"       → delete surrounding "quotes"
--     ds)       → delete surrounding (parentheses)
--     dst       → delete surrounding <tags>
--     dsb       → delete surrounding **bold**
--     dsi       → delete surrounding _italic_
--     dsc       → delete surrounding `code`
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ CHANGE Surround                                                         │
-- └─────────────────────────────────────────────────────────────────────────┘
--   cs{old}{new}    Change surrounding from {old} to {new}
--
--   Examples:
--     cs"'      → change "quotes" to 'quotes'
--     cs'<q>    → change 'quotes' to <q>tags</q>
--     cs)]      → change (parens) to [brackets]
--     csbi      → change **bold** to _italic_
--     cstb      → change <tag> to **bold**
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ COMMON TEXT OBJECTS                                                     │
-- └─────────────────────────────────────────────────────────────────────────┘
--   iw   = inner word
--   iW   = inner WORD (includes punctuation)
--   is   = inner sentence
--   ip   = inner paragraph
--   it   = inner tag block
--   i"   = inner quotes
--   i)   = inner parentheses
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ BRACKET BEHAVIOR                                                        │
-- └─────────────────────────────────────────────────────────────────────────┘
--   Opening bracket = adds spaces:  ysiwb → ( text )
--   Closing bracket = no spaces:    ysiwB → (text)
--
--   Examples:
--     ysiw(     → ( word )
--     ysiw)     → (word)
--     ysiw{     → { word }
--     ysiw}     → {word}
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ REAL-WORLD EXAMPLES                                                     │
-- └─────────────────────────────────────────────────────────────────────────┘
--   hello         → ysiw"    → "hello"
--   "hello"       → ds"      → hello
--   "hello"       → cs"'     → 'hello'
--   hello world   → yss)     → (hello world)
--   <p>text</p>   → dst      → text
--   text          → ysiwt    → <tag>text</tag>  (prompts for tag)
--   word          → ysiwb    → **word**
--   **bold**      → csbi     → _bold_

return {
  "kylechui/nvim-surround",
  version = "*", -- Use for stability; omit to use `main` branch for the latest features
  event = "VeryLazy",
  config = function()
    require("nvim-surround").setup({
      surrounds = {
        -- Markdown bold: **text**
        ["b"] = {
          add = { "**", "**" },
          find = "%*%*.-%*%*",
          delete = "^(%*%*)().-()(%*%*)$",
        },
        -- Markdown italic: _text_
        ["i"] = {
          add = { "_", "_" },
          find = "_.-%_",
          delete = "^(_)().-()(_)$",
        },
        -- Markdown code: `text`
        ["c"] = {
          add = { "`", "`" },
          find = "`.-`",
          delete = "^(`)().-()(`)$",
        },
        -- Keep default * and _ available too
        ["*"] = {
          add = { "**", "**" },
          find = "%*%*.-%*%*",
          delete = "^(%*%*)().-()(%*%*)$",
        },
        ["_"] = {
          add = { "_", "_" },
          find = "_.-%_",
          delete = "^(_)().-()(_)$",
        },
      },
    })
  end,
}
