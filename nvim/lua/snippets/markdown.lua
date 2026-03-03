local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

ls.add_snippets("markdown", {
  s("pgl", {
    t("[PGL-"),
    i(1, "000"),
    t("](https://projecthub.service.csnzoo.com/browse/PGL-"),
    f(function(args) return args[1][1] end, { 1 }),
    t(")"),
  }),
})
