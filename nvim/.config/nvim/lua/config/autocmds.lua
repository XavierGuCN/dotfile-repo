-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_inst_same_name_port_net", { clear = true }),
  pattern = { "verilog", "systemverilog" },
  callback = function(event)
    require("utils.inst_same_name_port_net").setup_buffer(event.buf)
    require("utils.verilog_formating").setup_buffer(event.buf)
  end,
})

-- 在文件类型设置之后应用，避免 LazyVim、ftplugin 或 EditorConfig 恢复自动换行。
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "InsertEnter" }, {
  group = vim.api.nvim_create_augroup("user_no_auto_wrap", { clear = true }),
  callback = function()
    vim.opt_local.wrap = false
    vim.opt_local.textwidth = 0
    vim.opt_local.wrapmargin = 0
    vim.opt_local.formatoptions:remove({ "t", "c", "a", "r", "o" })
  end,
})
