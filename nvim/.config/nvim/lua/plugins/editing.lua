return {
  {
    "nvim-mini/mini.pairs",
    opts = {
      mappings = {
        ['"'] = false,
        ["'"] = false,
      },
    },
  },

  -- 注释 / Markdown 表格：<leader>tm 开关，<leader>tr 重新对齐。
  {
    "dhruvasagar/vim-table-mode",
  },

  -- 注释框与标题分隔线，支持当前行和可视选择。
  {
    "LudoPinelli/comment-box.nvim",
    opts = {},
    keys = {
      { "<leader>cb", "<Cmd>CBccbox<CR>", mode = { "n", "x" }, desc = "Comment Box" },
      { "<leader>c-", "<Cmd>CBllline<CR>", mode = { "n", "x" }, desc = "Comment Title Line" },
      { "<leader>cB", "<Cmd>CBd<CR>", mode = { "n", "x" }, desc = "Remove Comment Box" },
      { "<leader>c?", "<Cmd>CBcatalog<CR>", desc = "Comment Box Styles" },
    },
  },

  -- 选中多行后 ga= 按等号对齐；普通模式 gaip= 对齐当前段落。
  {
    "junegunn/vim-easy-align",
    keys = {
      { "ga", "<Plug>(EasyAlign)", mode = { "n", "x" }, desc = "Easy Align" },
    },
  },
}
