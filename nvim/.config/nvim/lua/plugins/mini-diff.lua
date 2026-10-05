return {
  {
    "nvim-mini/mini.diff",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      {
        "<leader>hD",
        function()
          local diff = require("mini.diff")
          if diff.get_buf_data(0) then
            diff.toggle_overlay(0)
          else
            vim.notify("当前文件未启用保存差异；Git 文件请使用 <leader>ghp 或 <leader>ghd")
          end
        end,
        desc = "Toggle Saved Diff Overlay",
      },
    },
    opts = function()
      local diff = require("mini.diff")
      local source = diff.gen_source.save()
      local attach = source.attach
      source.attach = function(bufnr)
        -- Git 仓库继续使用 gitsigns，避免两套差异标记重叠。
        if vim.fs.root(bufnr, ".git") then
          return false
        end
        return attach(bufnr)
      end

      return {
        -- 普通文件 / SOS 文件与上次保存内容比较，保存后清除标记。
        source = source,
        view = {
          style = "sign",
          signs = { add = "+", change = "~", delete = "_" },
        },
        -- 不注册默认快捷键，保留现有 Git 和 Verilog 映射。
        mappings = {
          apply = "",
          reset = "",
          textobject = "",
          goto_first = "",
          goto_prev = "",
          goto_next = "",
          goto_last = "",
        },
      }
    end,
  },
}
