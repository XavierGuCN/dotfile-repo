# Verilog 自定义文本格式化

实现位于 `lua/utils/verilog_formating.lua`，文件开头的 `simpleAlign` 表集中配置全部宽度。
修改配置后重启 Neovim。在 Verilog / SystemVerilog 缓冲区中使用：

- `:VerilogFormat` 或普通模式 `vf` / `<leader>vf`：格式化全文。
- 选中内容后按 `vf` / `<leader>vf`，或输入 `:VerilogFormat`：格式化选中的行。
- `:10,20VerilogFormat`：仅格式化第 10–20 行。
- `u`：一次撤销本次格式化。

范围采用 Vim 的行范围：字符选区和块选区也会格式化涉及的整行。
脚本读取全文来判断注释和 always 上下文，但不会修改范围外的行。
普通模式的 `vf` 映射只在 Verilog / SystemVerilog 缓冲区生效。
`<leader>vf` 同样只在这些缓冲区生效，并在 which-key 的 `<leader>v` 菜单下显示 `f`。

## 宽度规则

`num1/5/9/12/15` 是绝对缩进；其他字段宽度包含字段本身，超过设定宽度时自然扩展。
字段不截断；需要分隔标识符的地方至少保留一个空格。

端口方向占 7 列，端口类型占 6 列，signed 占 7 列，之后附加 `num2` 个空格。
变量类型占 8 列，signed 占 7 列，之后附加 `num6` 个空格。
可选关键字缺失时保留对应槽位，所以把 `num2/6` 设为 0 也不会删掉这些占位。

`num3` 是从 `[` 到变量名前的整个 packed 位宽字段宽度；没有位宽也保留该字段。
`upbound/lowbound` 分别右对齐位宽上下界，并要求 `num3 >= upbound + lowbound + 3`。
实际表达式超过最小宽度时会撑开该字段，长位宽后至少保留一个空格。
支持连续的多个 packed 维度；变量后的 unpacked 数组保留在变量字段内。

`num10/13` 包含 parameter/localparam 或 assign 关键字自身；`num16` 不含点号。
`num18/19` 包含等号之后固定的一个空格；`num7` 保留不用。
参数的可选类型/位宽计入 `num10`，初始化表达式不做内部改写。

`Width_always` 控制 always 行的绝对缩进，`indent_width` 控制块内每层缩进。
支持 always/always_ff/always_comb/always_latch，嵌套 if/else if/else，
begin 与语句同行或独立成行，以及无 begin 的单语句分支；也支持常规 case、for、while、repeat。
独立 begin/end 与所属控制语句对齐。always 内及改写的 if 分支内不套用模块层声明的绝对缩进。

## if / else 分支

脚本顶部 `simpleAlign.wrap_single_statement` 默认为 `true`。
执行 `VerilogFormat` 或 `vf` 时，完整的 if/else 链默认会统一为以下格式：

```verilog
if (ready) begin
  data <= next_data;
end
else if (reset) begin
  data <= 0;
  valid <= 0;
end
else begin
  valid <= 1;
end
```

条件单独占一行（同一行放 `begin`），每条执行语句各占一行。
无论分支包含一条还是多条执行语句，都有 `begin/end`；已有的块不会重复包裹，命名块保留。
将 `wrap_single_statement = false` 后，不再为原本没有块的单条执行语句添加 `begin/end`：

```verilog
if (ready)
  q = a;
```

此开关同样作用于 else if 和 else 分支。关闭开关不会删除已有的 begin/end，
以保留已有作用域及嵌套 else 的归属；多语句块和命名块始终保留。
嵌套 if 的 else 归属不变，else if 链保持连写。
分支内原先跨行的条件/表达式会合并；字符串内容保持不变。
条件/表达式内部的注释移到对应语句之前，避免行注释吞掉合并后的代码；行尾注释保留。
块内部的空白行可能随此规范化消除。

这项规则也适用于 always 外的普通过程语句，例如 initial、function、task 中的 if。
选择部分内容时，只改写完整落在选区内的 if/else 链；不完整的外层链保留，
其中完整选中的嵌套链仍可处理。选区外的文本不变，即使选区内行数增加或减少。
不推测无 begin 时后续语句的归属：仅将 Verilog 语法规定的那一条受控语句包入块内。

## 处理边界

这是纯文本格式化器，不调用 LSP、Verible 或 Tree-sitter。
声明、assign 和实例连接主要处理完整单行；表达式、字符串和行尾注释保留。
跨行声明/连接、宏及其续行、转义标识符、代码中间的块注释不进行字段对齐。
if 规范化以外的空行和独立注释保持原样。无法完整识别结构的 always 块不进行块缩进，
包括仍存在同一行 begin/end、条件编译指令或不支持的结构的情况。
if 分支规范化支持同行的 begin/end；含宏、转义标识符、跨行字符串、do/while、
断言动作等未支持结构的链不进行结构改写。SystemVerilog 的 constraint/property/sequence 内的 if 不适用此规则。

现有 Conform/Verible 配置仍然启用。保存时的自动格式化可能重新调整自定义列宽；
需要保留此脚本的结果时，可在当前缓冲区执行 `:lua vim.b.autoformat = false`，
再执行 `vf` 并保存。

验证命令（在 Neovim 配置目录中执行）：

```sh
nvim --headless -u NONE -i NONE -l tests/verilog_formating.lua
```
