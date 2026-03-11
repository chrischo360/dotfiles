local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local function slugify(str)
  return str:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
end

ls.add_snippets("markdown", {
  s("pgl", {
    t("[PGL-"),
    i(1, "000"),
    t("](https://projecthub.service.csnzoo.com/browse/PGL-"),
    f(function(args) return args[1][1] end, { 1 }),
    t(")"),
  }),

  s({ trig = "meeting", desc = "Create meeting note with link" }, {
    t("- [ ] ["),
    i(1, "meeting-name"),
    t("](../meetings/"),
    f(function() return os.date("%Y-%m-%d") end),
    t("_"),
    f(function(args) return slugify(args[1][1]) end, { 1 }),
    t(".md)"),
  }),

  s({ trig = "note", desc = "Create scratch note with link" }, {
    t("["),
    i(1, "note-name"),
    t("](../scratch/"),
    f(function(args) return slugify(args[1][1]) end, { 1 }),
    t(".md)"),
  }),
})
