-- Basic Neovim options (migrated from .vimrc)

local opt = vim.opt

-- Encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.fileencodings = { "ucs-bom", "utf-8", "cp932", "euc-jp" }
opt.fileformats = { "unix", "dos", "mac" }

-- File handling
opt.backup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.local/state/nvim/undo")
opt.autoread = true
opt.hidden = true
opt.updatetime = 1000

-- Create undo directory if it doesn't exist
local undo_dir = vim.fn.expand("~/.local/state/nvim/undo")
if vim.fn.isdirectory(undo_dir) == 0 then
  vim.fn.mkdir(undo_dir, "p")
end

-- Display
opt.termguicolors = true
opt.number = true
opt.cursorline = true
opt.virtualedit = "onemore"
opt.smartindent = true
opt.visualbell = true
opt.showmatch = true
opt.laststatus = 3 -- Global statusline
opt.wildmode = { "list", "longest" }
opt.showcmd = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Tab & Indent
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.wrapscan = true
opt.hlsearch = true

-- Split
opt.splitright = true
opt.splitbelow = true

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- Clipboard (use system clipboard)
opt.clipboard = "unnamedplus"

-- Mouse
opt.mouse = "a"
