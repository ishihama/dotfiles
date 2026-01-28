-- Editor plugins: file tree, fuzzy finder, treesitter

return {
  -- NvimTree file explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    keys = {
      { "<Leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
      { "<Leader>E", "<cmd>NvimTreeFocus<CR>", desc = "Focus file explorer" },
    },
    opts = {
      filters = {
        dotfiles = false,
        git_ignored = false,
      },
      disable_netrw = true,
      hijack_netrw = true,
      hijack_cursor = true,
      sync_root_with_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = false,
      },
      view = {
        width = 30,
        side = "left",
      },
      renderer = {
        root_folder_label = false,
        highlight_git = true,
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
          glyphs = {
            folder = {
              arrow_closed = "",
              arrow_open = "",
            },
            git = {
              unstaged = "✗",
              staged = "✓",
              unmerged = "",
              renamed = "➜",
              untracked = "★",
              deleted = "",
              ignored = "◌",
            },
          },
        },
      },
      actions = {
        open_file = {
          quit_on_open = false,
          resize_window = true,
          window_picker = {
            enable = false,  -- 直接エディタウィンドウにフォーカス
          },
        },
      },
      git = {
        enable = true,
        ignore = false,
      },
    },
  },

  -- Telescope fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    cmd = "Telescope",
    keys = {
      { "<Leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<Leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep" },
      { "<Leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<Leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
      { "<Leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<Leader>fc", "<cmd>Telescope commands<CR>", desc = "Commands" },
    },
    opts = function()
      local actions = require("telescope.actions")
      return {
        defaults = {
          prompt_prefix = "   ",
          selection_caret = " ",
          entry_prefix = "  ",
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
            },
            width = 0.87,
            height = 0.80,
          },
          sorting_strategy = "ascending",
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<Esc>"] = actions.close,
            },
          },
          file_ignore_patterns = {
            "node_modules",
            ".git/",
            "target/",
            "dist/",
            "build/",
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
          buffers = {
            sort_lastused = true,
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer,
              },
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },

  -- Treesitter for better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Install parsers
      local ensure_installed = {
        "bash",
        "c",
        "css",
        "dockerfile",
        "go",
        "gomod",
        "gosum",
        "html",
        "java",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "regex",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      }

      -- Auto install parsers
      require("nvim-treesitter").install(ensure_installed)

      -- Enable treesitter highlighting
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },

  -- Which-key for keybinding hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      plugins = {
        spelling = { enabled = true },
      },
      spec = {
        { "<Leader>f", group = "Find" },
        { "<Leader>h", group = "Git Hunk" },
        { "<Leader>c", group = "Code" },
        { "<Leader>d", group = "Diagnostic" },
        { "<Leader>b", group = "Buffer" },
        { "<Leader>t", group = "Toggle" },
      },
    },
  },
}
