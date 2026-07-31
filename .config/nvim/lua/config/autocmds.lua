-- Auto commands

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Open nvim-tree on startup (skip if file specified, NVIM_NO_TREE=1, or memo files)
augroup("NvimTreeAutoOpen", { clear = true })
autocmd("VimEnter", {
  group = "NvimTreeAutoOpen",
  callback = function()
    -- Skip if NVIM_NO_TREE environment variable is set
    if vim.env.NVIM_NO_TREE == "1" then
      return
    end
    -- Skip if file was specified as argument (e.g., nvim somefile.txt)
    if vim.fn.argc() > 0 then
      return
    end
    -- Skip for memo files
    local filename = vim.fn.expand("%:p")
    local memo_dir = vim.fn.expand("~") .. "/memos"
    if filename:sub(1, #memo_dir) == memo_dir then
      return
    end
    -- pcall: on the very first launch plugins are still installing, and an
    -- unguarded require throws an autocmd error on every startup until
    -- nvim-tree exists.
    local ok, api = pcall(require, "nvim-tree.api")
    if ok then
      api.tree.open()
    end
  end,
})

-- Highlight on yank
augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  group = "YankHighlight",
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
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
    -- Two trailing spaces are a hard line break in Markdown, so stripping
    -- them silently changes how the document renders.
    local skip = { markdown = true, gitcommit = true, diff = true }
    if skip[vim.bo.filetype] then
      return
    end
    -- Edit the buffer directly instead of :%s - the ex command clobbers the
    -- last-search pattern, so a later `n` jumps to trailing whitespace
    -- rather than the user's own search.
    local save_cursor = vim.fn.getpos(".")
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local changed = false
    for i, line in ipairs(lines) do
      local trimmed = line:gsub("%s+$", "")
      if trimmed ~= line then
        lines[i] = trimmed
        changed = true
      end
    end
    if changed then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      vim.fn.setpos(".", save_cursor)
    end
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
    local file = vim.uv.fs_realpath(event.match) or event.match
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
