-- Keymaps configuration

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Better j/k for wrapped lines
keymap("n", "j", "gj", opts)
keymap("n", "k", "gk", opts)

-- Clear search highlight with Esc
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", opts)

-- Window navigation
keymap("n", "<Tab>", "<C-w>w", opts)           -- 次のウィンドウ
keymap("n", "<S-Tab>", "<C-w>W", opts)         -- 前のウィンドウ
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Window resize
keymap("n", "<C-Up>", "<cmd>resize +2<CR>", opts)
keymap("n", "<C-Down>", "<cmd>resize -2<CR>", opts)
keymap("n", "<C-Left>", "<cmd>vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", "<cmd>vertical resize +2<CR>", opts)

-- Buffer navigation
keymap("n", "<S-l>", "<cmd>bnext<CR>", opts)
keymap("n", "<S-h>", "<cmd>bprevious<CR>", opts)
keymap("n", "<Leader>bd", "<cmd>bdelete<CR>", opts)

-- Move lines
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Stay in visual mode when indenting
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Better paste (don't yank replaced text)
keymap("v", "p", '"_dP', opts)

-- Quick save
keymap("n", "<Leader>w", "<cmd>w<CR>", opts)
keymap("n", "<Leader>q", "<cmd>q<CR>", opts)

-- NvimTree
keymap("n", "<Leader>e", "<cmd>NvimTreeToggle<CR>", opts)
keymap("n", "<Leader>E", "<cmd>NvimTreeFocus<CR>", opts)

-- Telescope
keymap("n", "<Leader>ff", "<cmd>Telescope find_files<CR>", opts)
keymap("n", "<Leader>fg", "<cmd>Telescope live_grep<CR>", opts)
keymap("n", "<Leader>fb", "<cmd>Telescope buffers<CR>", opts)
keymap("n", "<Leader>fh", "<cmd>Telescope help_tags<CR>", opts)
keymap("n", "<Leader>fr", "<cmd>Telescope oldfiles<CR>", opts)
keymap("n", "<Leader>fc", "<cmd>Telescope commands<CR>", opts)

-- LSP keymaps (set in lsp.lua on_attach)
-- gd = go to definition
-- gr = references
-- K = hover
-- <Leader>ca = code action
-- <Leader>rn = rename

-- Diagnostic
keymap("n", "[d", vim.diagnostic.goto_prev, opts)
keymap("n", "]d", vim.diagnostic.goto_next, opts)
keymap("n", "<Leader>d", vim.diagnostic.open_float, opts)
keymap("n", "<Leader>dl", "<cmd>Telescope diagnostics<CR>", opts)
