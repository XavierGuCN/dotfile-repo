-- LazyVim 会自动加载此文件；这里的配置用于覆盖默认选项。
-- 查看选项帮助：例如 :help number 或 :help shiftwidth
-- 部分选项也已包含在 LazyVim 默认配置中，在这里显式列出，方便修改。
local opt = vim.opt

-- 显示与滚动
opt.number = true -- 显示当前行的绝对行号
opt.relativenumber = false -- 其他行显示相对行号，方便使用 5j / 5k 跳转
opt.cursorline = true -- 高亮光标所在行
opt.termguicolors = true -- 启用真彩色，需要终端支持（Kitty 支持）
opt.signcolumn = "yes" -- 始终保留标记栏，避免诊断标记出现时文本左右跳动
opt.wrap = false -- 长行不自动折行；可用 :set wrap 临时开启
opt.textwidth = 0 -- 输入时不按固定列宽插入换行
opt.wrapmargin = 0 -- 输入时不按窗口边距插入换行
opt.formatoptions:remove({ "t", "c", "a", "r", "o" }) -- 禁止自动换行、自动重排及新行延续注释
opt.scrolloff = 0 -- 垂直滚动时，不保留光标上下的额外行，以防止屏幕内容上下跳动
opt.sidescrolloff = 8 -- 水平滚动时，尽量在光标左右保留 8 列
opt.list = true -- 显示指定的不可见字符
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- 标出 Tab、行尾空格、不换行空格
opt.colorcolumn = "" -- 不显示列宽参考线；改为 "80" 或 "100" 可开启

-- 缩进（文件类型插件或 EditorConfig 可能覆盖这些默认值）
opt.expandtab = true -- 按 Tab 时插入空格
opt.tabstop = 2 -- 文件中的 Tab 按 2 列显示
opt.shiftwidth = 2 -- 自动缩进以及 >> / << 每次调整 2 个空格
opt.softtabstop = 2 -- 插入模式下 Tab / Backspace 按 2 个空格处理
opt.autoindent = true -- 新行继承上一行的缩进
opt.smartindent = true -- 为类似 C 的语法提供简单智能缩进
opt.shiftround = true -- 调整缩进时对齐到 shiftwidth 的整数倍

-- 搜索
opt.ignorecase = true -- 搜索默认忽略大小写
opt.smartcase = true -- 搜索词包含大写字母时，区分大小写
opt.incsearch = true -- 输入搜索词时即时预览匹配位置
opt.hlsearch = true -- 高亮搜索结果；使用 :noh 临时清除高亮

-- 窗口与缓冲区
opt.laststatus = 2 -- 每个窗口下方都显示独立状态栏（3 为全局共用状态栏）
opt.splitright = true -- :vsplit 在右侧打开新窗口
opt.splitbelow = true -- :split 在下方打开新窗口
opt.splitkeep = "screen" -- 分割窗口时尽量保持屏幕中的文本位置
opt.hidden = true -- 允许切换离开尚未保存的缓冲区
opt.confirm = true -- 遇到未保存修改时，询问保存、放弃或取消

-- 编辑与文件
opt.mouse = "a" -- 在所有模式下启用鼠标
opt.undofile = true -- 保存撤销历史，重新打开文件后仍可撤销
opt.swapfile = true -- 保留交换文件，便于异常退出后恢复
opt.updatetime = 200 -- 空闲 200 毫秒后写入交换文件并触发 CursorHold
opt.timeoutlen = 300 -- 等待组合映射后续按键的时间（毫秒）
opt.virtualedit = "block" -- 可视块模式下允许光标移动到行尾之后
opt.inccommand = "nosplit" -- 在当前窗口预览 :s 替换结果

vim.g.autoformat = false -- 禁用自动格式化

-- 可选：让普通复制/粘贴使用系统剪贴板，需要可用的剪贴板提供程序。
-- LazyVim 通常已配置此项；如需手动覆盖，取消下一行注释。
-- opt.clipboard = "unnamedplus"

-- HDL 文件类型映射
vim.filetype.add({
  extension = {
    v = "verilog",
    vh = "verilog",
    sv = "systemverilog",
    svh = "systemverilog",
    svi = "systemverilog",
  },
})
