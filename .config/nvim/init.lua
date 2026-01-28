-- Neovim configuration entry point

-- Load core settings
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Load plugins (lazy.nvim)
require("plugins")
