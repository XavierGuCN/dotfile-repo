return {
  -- VIDE LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vide = {
          -- 使用你自行安装的 Vide，不交给 Mason 安装
          mason = false,

          cmd = { "vide" },
          filetypes = { "verilog", "systemverilog" },
          root_markers = { "vide.toml", ".git" },
          init_options = {
            semantic = {tokens = {port = {clk = {rst = {enable = false}}}}},
          },
        },
      },
    },
  },

  -- Automatic Verilog
  {
    "HonkW93/automatic-verilog",
    ft = { "verilog", "systemverilog" },
  },

  -- Verible 格式化：由 Conform 调用 Mason 安装的 verible-verilog-format。
  -- 查询当前安装版本的完整参数：
  -- ~/.local/share/nvim/mason/bin/verible-verilog-format --helpfull
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        verilog = { "verible" },
        systemverilog = { "verible" },
      },
      formatters = {
        verible = {
          prepend_args = {
            -- 一、基础缩进与换行
            "--indentation_spaces=2", -- 非负整数；每一级代码块缩进的空格数，默认 2。
            "--wrap_spaces=4", -- 非负整数；每一级续行缩进的空格数，默认 4。
            "--column_limit=180", -- 正整数；目标行宽，并非所有行都能满足，默认 100。
            "--try_wrap_long_lines=false", -- true / false；尝试优化长行换行，默认 false。
            "--wrap_end_else_clauses=true", -- true / false；将 end 和 else 分到两行，默认 false。
            "--line_terminator=auto", -- auto / LF / CRLF；根据输入识别或指定换行符，默认 auto。
            "--line_break_penalty=2", -- 非负整数；新增换行的代价，越大越倾向少换行，默认 2。
            "--over_column_limit_penalty=100", -- 非负整数；超长行的基础代价，默认 100。

            -- 二、各类代码的对齐
            -- 本组所有参数可选：align / flush-left / preserve / infer，默认均为 infer。
            -- align：补空格形成纵向对齐列；flush-left：只保留必要缩进和间隔。
            -- preserve：保留原有对齐间距；infer：根据已有代码推断对齐方式。
            "--port_declarations_alignment=align", -- 定义处的端口声明，例如 input logic ...。
            "--named_port_alignment=align", -- 实例化时的具名端口连接，例如 .clk(clk)。
            "--formal_parameters_alignment=align", -- module/interface/class 头部 #(...) 中的形参。
            "--named_parameter_alignment=align", -- 实例化时的具名参数，例如 .WIDTH(32)。
            "--parameter_declaration_alignment=infer", -- 模块等内部的 parameter/localparam；不含 class 内部。
            "--module_net_variable_alignment=infer", -- module/generate/interface/package 内的网络和变量声明。
            "--assignment_statement_alignment=infer", -- module/generate/interface/package 内支持的赋值语句。
            "--enum_assignment_statement_alignment=infer", -- 枚举成员赋值，例如 IDLE = 0。
            "--case_items_alignment=infer", -- case 分支项。
            "--class_member_variable_alignment=infer", -- 类成员变量声明。
            "--struct_union_members_alignment=infer", -- struct / union 成员声明。
            "--distribution_items_alignment=infer", -- 随机约束 dist 中的分布项。

            -- 三、参数列表和端口列表的缩进
            -- 本组所有参数可选：indent / wrap，默认均为 wrap。
            -- indent：采用 indentation_spaces；wrap：采用 wrap_spaces。
            "--formal_parameters_indentation=wrap", -- 定义头部 #(...) 内的参数声明。
            "--named_parameter_indentation=wrap", -- 实例化时的 .PARAM(value)。
            "--named_port_indentation=wrap", -- 实例化时的 .port(signal)。
            "--port_declarations_indentation=wrap", -- 定义处的端口声明列表。

            -- 四、空格、数组维度与对齐分组
            "--compact_indexing_and_selections=true", -- true / false；索引及位选择内使用紧凑表达式，默认 true。
            "--class_parameter_space=false", -- true / false；类的参数化 typedef 中在 # 前加空格，默认 false。
            "--expand_coverpoints=false", -- true / false；始终展开 coverpoint 布局，默认 false。
            -- 以下两项仅在相应端口声明对齐已启用时生效，可选 true / false，默认 false。
            "--port_declarations_right_align_packed_dimensions=false", -- 右对齐变量名前的 packed 维度。
            "--port_declarations_right_align_unpacked_dimensions=false", -- 右对齐变量名后的 unpacked 维度。
            -- 对齐分组边界，适用于 module items、语句和 class items：
            -- none：不额外拆分（默认）；blank-lines：空行拆分；separator-comments：分隔注释拆分。
            -- blank-lines-and-separator-comments：空行和分隔注释都拆分。
            -- 分隔注释示例：独立一行的 // ---- 或 // ====，普通说明注释不一定算分隔注释。
            "--alignment_group_boundary=none",

            -- 五、格式化范围、输出和验证
            "--failsafe_success=true", -- true / false；出错保留原文且返回成功；false 便于检测失败，默认 true。
            "--verify_convergence=true", -- true / false；验证再次格式化不再改变结果，默认 true；--lines 时不检查。
            "--max_search_states=100000", -- 正整数；换行优化最多探索的状态数，默认 100000。
            -- 以下选项仅作命令行参考，不启用，避免干扰 Conform 的标准输入/输出流程。
            -- "--inplace=false", -- true / false；直接覆盖输入文件，默认 false；Conform 负责写回缓冲区。
            -- "--lines=3-10,20-25", -- 行号或闭区间，逗号分隔，可重复传入；默认全部行。
            -- "--stdin_name=$FILENAME", -- 字符串，默认 <stdin>；Conform 内置 args 已传入真实文件名。
            -- "--verify=false", -- true / false，默认 false；true 仅检查是否需要格式化，不用于编辑器格式化。
            -- verify 退出码：0 无需修改，1 需要格式化；本机版本支持，README 可能尚未列出。

            -- 六、调试参数
            -- 以下均保留为注释；部分选项会提前退出，不能用于日常 Conform 格式化。
            -- "--verbose=false", -- true / false；详细日志，默认 false。
            -- "--show_equally_optimal_wrappings=false", -- true / false；报告同样优的换行方案，默认 false。
            -- "--show_token_partition_tree=false", -- true / false；输出 token 分组树后退出，默认 false。
            -- "--show_inter_token_info=false", -- true / false；配合分组树显示间距和代价，默认 false。
            -- "--show_largest_token_partitions=0", -- 非负整数；大于 0 时输出 token 分组信息后退出，默认 0。

            -- 补充：项目参数文件，每行一个 --参数=值；不会自动搜索该文件。
            -- "--flagfile=/absolute/path/.rules.verible_format", -- 路径；使用时注意与上面的显式参数重复覆盖。
            -- 局部禁用格式化：在 Verilog 源码中用 // verilog_format: off 和 // verilog_format: on 包围代码。
          },
        },
      },
    },
  },
}
