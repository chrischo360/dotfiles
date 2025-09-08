-- Setup local plugins directly (not managed by lazy.nvim)
-- Call this from your init.lua or lazy config

-- Setup your local plugin
require("my-local-plugin").setup({
  message = "Hello from pure Lua setup!"
})

-- You can add more local plugin setups here
-- require("another-local-plugin").setup({ ... })
