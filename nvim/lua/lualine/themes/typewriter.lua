local dark = vim.o.background == "dark"

local c = dark and {
  bg = "#262626",
  bg_alt = "#202020",
  bg_side = "#3a342e",
  fg = "#c5b8a1",
  muted = "#999999",
  accent = "#519d5c",
  red = "#d75f5f",
  yellow = "#e5b567",
  blue = "#6c99bb",
  purple = "#9e86c8",
} or {
  bg = "#fcf5e4",
  bg_alt = "#f6edd8",
  bg_side = "#e4dcc8",
  fg = "#262626",
  muted = "#595959",
  accent = "#519d5c",
  red = "#b54d4d",
  yellow = "#9d6d20",
  blue = "#3f7698",
  purple = "#7a60a8",
}

return {
  normal = {
    a = { fg = c.bg, bg = c.accent, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_side },
    c = { fg = c.fg, bg = c.bg_alt },
  },
  insert = {
    a = { fg = c.bg, bg = c.blue, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_side },
    c = { fg = c.fg, bg = c.bg_alt },
  },
  visual = {
    a = { fg = c.bg, bg = c.purple, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_side },
    c = { fg = c.fg, bg = c.bg_alt },
  },
  replace = {
    a = { fg = c.bg, bg = c.red, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_side },
    c = { fg = c.fg, bg = c.bg_alt },
  },
  command = {
    a = { fg = c.bg, bg = c.yellow, gui = "bold" },
    b = { fg = c.fg, bg = c.bg_side },
    c = { fg = c.fg, bg = c.bg_alt },
  },
  inactive = {
    a = { fg = c.muted, bg = c.bg_alt },
    b = { fg = c.muted, bg = c.bg_alt },
    c = { fg = c.muted, bg = c.bg_alt },
  },
}
