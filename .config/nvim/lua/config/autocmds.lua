-- Auto commands

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Open nvim-tree on startup (except for memo files)
augroup("NvimTreeAutoOpen", { clear = true })
autocmd("VimEnter", {
  group = "NvimTreeAutoOpen",
  callback = function()
    -- Skip nvim-tree for memo files
    local filename = vim.fn.expand("%:p")
    local memo_dir = vim.fn.expand("~") .. "/memos"
    if filename:sub(1, #memo_dir) == memo_dir then
      return
    end
    require("nvim-tree.api").tree.open()
  end,
})

-- Highlight on yank
augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  group = "YankHighlight",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Auto save memo files (migrated from .vimrc)
augroup("MemoAutoSave", { clear = true })
autocmd({ "CursorHold", "CursorHoldI" }, {
  group = "MemoAutoSave",
  pattern = vim.fn.expand("~") .. "/memos/*",
  callback = function()
    if vim.bo.modified then
      vim.cmd("silent! write")
    end
  end,
})

-- Remove trailing whitespace on save
augroup("TrimWhitespace", { clear = true })
autocmd("BufWritePre", {
  group = "TrimWhitespace",
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- Restore cursor position
augroup("RestoreCursor", { clear = true })
autocmd("BufReadPost", {
  group = "RestoreCursor",
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto create directories when saving file
augroup("AutoCreateDir", { clear = true })
autocmd("BufWritePre", {
  group = "AutoCreateDir",
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Close some filetypes with <q>
augroup("CloseWithQ", { clear = true })
autocmd("FileType", {
  group = "CloseWithQ",
  pattern = { "help", "lspinfo", "man", "notify", "qf", "checkhealth" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})

-- Set filetype for specific files
augroup("FileTypeDetect", { clear = true })
autocmd({ "BufRead", "BufNewFile" }, {
  group = "FileTypeDetect",
  pattern = "*.mdx",
  command = "setfiletype markdown",
})
