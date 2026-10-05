return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-storm",
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "storm",
      on_highlights = function(hl, colors)
        -- 避免选中 Tab 的背景与窗口数量的蓝色文字重合。
        hl.TabLineSel = { fg = colors.fg, bg = "#384152", bold = true }
        -- Tokyo Storm 下，对 Bufferline 的 Tab 使用亮白色、粗体、斜体来显示当前 Tab。
        if require("tokyonight").styles[vim.o.background] == "storm" then
          hl.BufferLineTabSelected = { fg = "#FFFFFF", bg = colors.bg, bold = true, italic = true }
        end
      end,
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- 保留默认主题，仅提高非当前窗口状态栏的对比度。
      opts.options = opts.options or {}
      local base_theme = opts.options.theme or "auto"
      local theme = vim.deepcopy(
        type(base_theme) == "table" and base_theme or require("lualine.themes." .. base_theme)
      )
      theme.inactive = {
        a = { fg = "#E2E8F0", bg = "#384152" },
        b = { fg = "#E2E8F0", bg = "#384152" },
        c = { fg = "#E2E8F0", bg = "#384152" },
      }
      opts.options.globalstatus = false -- 每个分屏窗口各自显示状态栏
      opts.options.theme = theme
      opts.inactive_sections = {
        lualine_c = { { "filename", path = 1 } }, -- 非当前窗口也显示相对路径
        lualine_x = { "location" },
      }
    end,
  },

  -- Bufferline Setting
  {
    "akinsho/bufferline.nvim",
    -- 启用 / 禁用 Bufferline
    enabled = true,
  },

  -- Treesitter Context (Sticky Scroll like VSCode)
  -- {
  --   "nvim-treesitter/nvim-treesitter-context",
  --   event = { "BufReadPost", "BufNewFile" },
  --   opts = {},
  -- },

}
