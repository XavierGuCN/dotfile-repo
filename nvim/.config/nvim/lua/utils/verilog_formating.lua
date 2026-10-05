-- 用户配置：宽度均为最小宽度，长字段不截断；缩进使用空格。

-- /*[num1]*/  output reg signed /*[num2]*/ [  15: 0] /*[num3]*/  dac1_ch2_q  /*[num4]*/  ;
-- /*[num5]*/  reg signed        /*[num6]*/ [  15: 0] /*[num3]*/  reg_rf_ct9  /*[num8]*/   ;
-- /*[num9]*/  parameter                              /*[num10]*/ RF_ADC3_MIN  /*[num11]*/ = 16'h8233  /*[num18]*/  ;
-- /*[num12]*/ assign                                 /*[num13]*/ uart_bus_clk /*[num14]*/ = clk       /*[num19]*/  ;

-- uart_top_232 u0_uart_top_232(
-- /*[num15]*/ .uart_bus_clk                     /*[num16]*/  (uart_bus_clk    /*[num17]*/ ),
-- /*[num15]*/ .uart_bus_rst                     /*[num16]*/  (~rst_n          /*[num17]*/ ),
-- /*[num15]*/ .uart_tx                          /*[num16]*/  (rx_232_0        /*[num17]*/ )
-- );

local tab_size = 2

local simpleAlign = {
  wrap_single_statement = true, -- 是否为 if 的单条执行语句添加 begin-end；关闭时不会添加但对已有的 begin-end 块会保留
  num1 = tab_size, -- input/output/inout 前的绝对缩进
  num2 = 1, -- 端口 signed 槽位后的附加空格
  num3 = 15, -- packed 位宽字段总宽度（含 [] 和到变量名之前的空格）
  num4 = 27, -- 端口变量名字段宽度
  num5 = tab_size, -- reg/wire/integer/logic 前的绝对缩进
  num6 = 1, -- 变量 signed 槽位后的附加空格
  num7 = 0, -- 保留，未使用
  num8 = 24, -- 变量名字段宽度（含 unpacked 数组和初始化）
  num9 = tab_size, -- parameter/localparam 前的绝对缩进
  num10 = 1, -- 参数关键字到参数名的总宽度，包含关键字和可选类型/位宽
  num11 = 12, -- 参数名到等号的总宽度
  num12 = tab_size, -- assign 前的绝对缩进
  num13 = 1, -- assign 到目标信号名的总宽度，包含 assign
  num14 = 12, -- 目标信号名到等号的总宽度
  num15 = 2 * tab_size, -- 实例端口点号前的绝对缩进
  num16 = 34, -- 点号后端口名到左括号的总宽度（不含点号）
  num17 = 25, -- 左括号后表达式到右括号的总宽度
  num18 = 1, -- 参数等号之后到结束符的总宽度，包含等号后的一个空格
  num19 = 1, -- assign 等号之后到分号的总宽度，包含等号后的一个空格
  upbound = 4, -- 位宽上界最小宽度，右对齐
  lowbound = 2, -- 位宽下界最小宽度，右对齐
  Width_always = tab_size, -- always 行的绝对缩进
  indent_width = tab_size, -- always 内部每层缩进（begin/end 独立成行时与所属语句对齐）
}

-- :VerilogFormat / 普通模式 vf 或 <leader>vf：整份缓冲区。
-- :'<,'>VerilogFormat / 可视模式 vf 或 <leader>vf：选中行；字符/块选区也按整行处理。
-- 固定槽：端口方向 7 列、reg/wire/logic 6 列、signed 7 列；
-- 普通变量类型 8 列、signed 7 列。可选词缺失时仍保留槽位，num2/6 不缩减它们。
-- 仅处理可识别的完整单行声明/赋值/连接；跨行声明、宏、转义标识符、
-- 代码中间的块注释不做字段对齐。if/else 条件及每条执行语句各占一行，
-- wrap_single_statement 开启时为单条语句补齐 begin/end；else if 保持连写，已有块保留。
-- 选区只有覆盖完整 if/else 链时才改写该链，条件/表达式内部注释移到其前面。
-- 无需外部格式化器或语法树；无法识别的结构保留原样。
local M = { config = simpleAlign }
local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end
local function spaces(n)
  return string.rep(" ", math.max(0, n))
end
local function pad(s, width, gap)
  return s .. spaces(math.max(gap or 0, width - vim.fn.strdisplaywidth(s)))
end

-- 屏蔽字符串/注释，保持字节位置，块注释状态跨行传递。
local function scan(lines)
  local rows, block, macro = {}, false, false
  for row, line in ipairs(lines) do
    local out, i, comments, escaped, unsafe_string = {}, 1, {}, false, false
    local continuation = macro or line:match("^%s*`") ~= nil
    macro = continuation and line:match("\\%s*$") ~= nil
    while i <= #line do
      local c, pair = line:sub(i, i), line:sub(i, i + 1)
      if block or pair == "/*" then
        local ending = line:find("*/", i + (block and 0 or 2), true)
        local last = ending and ending + 1 or #line
        comments[#comments + 1] = { i, last }
        out[#out + 1] = spaces(last - i + 1)
        block, i = ending == nil, last + 1
      elseif pair == "//" then
        comments[#comments + 1] = { i, #line }
        out[#out + 1] = spaces(#line - i + 1)
        break
      elseif c == '"' then
        local j, closed = i + 1, false
        while j <= #line do
          if line:sub(j, j) == "\\" then
            j = j + 2
          elseif line:sub(j, j) == '"' then
            closed = true
            j = j + 1
            break
          else
            j = j + 1
          end
        end
        unsafe_string = unsafe_string or not closed
        out[#out + 1] = string.rep("x", math.min(j - i, #line - i + 1))
        i = j
      elseif c == "\\" then
        local word = line:sub(i):match("^%S+")
        out[#out + 1], i, escaped = string.rep("x", #word), i + #word, true
      else
        out[#out + 1], i = c, i + 1
      end
    end
    local clean = table.concat(out)
    local last = #(clean:gsub("%s+$", ""))
    local safe = not continuation and not escaped
    for _, comment in ipairs(comments) do
      if comment[1] <= last then
        safe = false
      end
    end
    rows[row] = {
      clean = clean,
      code = trim(line:sub(1, last)),
      suffix = trim(line:sub(last + 1)),
      safe = safe,
      macro = continuation,
      escaped = escaped,
      unsafe_string = unsafe_string,
    }
  end
  return rows
end

-- 返回括号之外的分隔符位置；字符串已屏蔽。
local function separators(s, wanted)
  local result, stack = {}, {}
  local closing = { [")"] = "(", ["]"] = "[", ["}"] = "{" }
  for i = 1, #s do
    local c = s:sub(i, i)
    if c == "(" or c == "[" or c == "{" then
      stack[#stack + 1] = c
    elseif closing[c] then
      if table.remove(stack) ~= closing[c] then
        return nil
      end
    elseif #stack == 0 and wanted:find(c, 1, true) then
      result[#result + 1] = i
    end
  end
  return #stack == 0 and result or nil
end

local function range_width(s, cfg)
  local colon = separators(s:sub(2, -2), ":?")
  if not colon or #colon ~= 1 or s:sub(colon[1] + 1, colon[1] + 1) ~= ":" then
    return s -- 三元表达式、非范围维度保持原样
  end
  local at = colon[1] + 1
  local high, low = trim(s:sub(2, at - 1)), trim(s:sub(at + 1, -2))
  return "[" .. spaces(cfg.upbound - #high) .. high .. ":" .. spaces(cfg.lowbound - #low) .. low .. "]"
end

local function dimensions(rest, cfg)
  local ranges = {}
  while rest:sub(1, 1) == "[" do
    local part = rest:match("^%b[]")
    if not part then
      return nil
    end
    ranges[#ranges + 1] = range_width(part, cfg)
    rest = trim(rest:sub(#part + 1))
  end
  return table.concat(ranges), rest
end

local function take_word(rest, allowed)
  local word = rest:match("^([%a_][%w_$]*)")
  if word and allowed[word] then
    return word, trim(rest:sub(#word + 1))
  end
  return "", rest
end

local function format_line(info, cfg)
  if not info.safe or info.code == "" then
    return nil
  end
  local code, clean = info.code, trim(info.clean)
  local kind = code:match("^([%a_][%w_$]*)")
  local result
  if
    kind == "input"
    or kind == "output"
    or kind == "inout"
    or kind == "reg"
    or kind == "wire"
    or kind == "integer"
    or kind == "logic"
  then
    local port = kind == "input" or kind == "output" or kind == "inout"
    local rest, datatype, signed = trim(code:sub(#kind + 1)), "", ""
    if port then
      datatype, rest = take_word(rest, { reg = true, wire = true, logic = true })
    end
    signed, rest = take_word(rest, { signed = true })
    local width
    width, rest = dimensions(rest, cfg)
    if not width or not rest:match("^[%a_][%w_$]*") then
      return nil
    end
    local ending = rest:match("(%)[%s]*;)%s*$") or rest:match("([,;])%s*$") or ""
    if not port and ending ~= ";" then
      return nil
    end
    local name = trim(rest:sub(1, #rest - #ending))
    local masked_name = scan({ name })[1].clean
    local semis = separators(masked_name, ";")
    if not semis or #semis > 0 then
      return nil
    end
    local prefix = port and (pad(kind, 7) .. pad(datatype, 6)) or pad(kind, 8)
    result = spaces(port and cfg.num1 or cfg.num5)
      .. prefix
      .. pad(signed, 7)
      .. spaces(port and cfg.num2 or cfg.num6)
      .. pad(width, cfg.num3, width ~= "" and 1 or 0)
      .. pad(name, port and cfg.num4 or cfg.num8)
      .. ending:gsub("%s+", "")
  elseif kind == "parameter" or kind == "localparam" or kind == "assign" then
    local marks = separators(clean, "=;,")
    if not marks then
      return nil
    end
    local eq = marks[1]
    if not eq or clean:sub(eq, eq) ~= "=" or clean:sub(eq + 1, eq + 1) == "=" then
      return nil
    end
    local last = marks[#marks]
    local ending = clean:sub(last, last)
    if ending ~= ";" and ending ~= "," then
      ending, last = "", #code + 1
    end
    if kind == "assign" and ending ~= ";" then
      return nil
    end
    -- 顶层逗号/分号只允许在末尾，避免误拆多条语句或多个参数。
    for _, at in ipairs(marks) do
      local c = clean:sub(at, at)
      if (c == ";" or c == ",") and at ~= #clean then
        return nil
      end
    end
    local lhs, rhs = trim(code:sub(#kind + 1, eq - 1)), trim(code:sub(eq + 1, last - 1))
    if lhs == "" or rhs == "" then
      return nil
    end
    if kind == "assign" then
      result = spaces(cfg.num12)
        .. pad(kind, cfg.num13, 1)
        .. pad(lhs, cfg.num14, 1)
        .. "= "
        .. pad(rhs, math.max(0, cfg.num19 - 1))
        .. ending
    else
      local prefix, name = lhs:match("^(.-)([%a_][%w_$]*)$")
      if not name then
        return nil
      end
      prefix = trim(prefix):gsub("%b[]", function(s)
        return range_width(s, cfg)
      end)
      prefix = kind .. (prefix ~= "" and (" " .. prefix) or "")
      result = spaces(cfg.num9)
        .. pad(prefix, cfg.num10, 1)
        .. pad(name, cfg.num11, 1)
        .. "= "
        .. pad(rhs, math.max(0, cfg.num18 - 1))
        .. ending
    end
  elseif code:sub(1, 1) == "." then
    local name, expression, ending = clean:match("^%.([%a_][%w_$]*)%s*(%b())%s*(,?)$")
    if not name then
      return nil
    end
    local at = clean:find("(", 1, true)
    local value = trim(code:sub(at + 1, at + #expression - 2))
    result = spaces(cfg.num15) .. "." .. pad(name, cfg.num16) .. "(" .. pad(value, cfg.num17) .. ")" .. ending
  end
  if result then
    return result:gsub("%s+$", "") .. (info.suffix ~= "" and (" " .. info.suffix) or "")
  end
end

-- 轻量语句结构扫描，只用于 always 缩进，不修改任何表达式。
local function always_indents(rows, cfg)
  local tokens, first, desired = {}, {}, {}
  for row, info in ipairs(rows) do
    local clean, col = info.macro and "`" or info.clean, 1
    while col <= #clean do
      local c = clean:sub(col, col)
      if c:match("%s") then
        col = col + 1
      else
        local value = clean:sub(col):match("^[%a_$][%w_$]*") or c
        tokens[#tokens + 1] = { value = value, row = row }
        first[row] = first[row] or #tokens
        col = col + #value
      end
    end
  end
  local function value(i)
    return tokens[i] and tokens[i].value
  end
  local function balanced(i, opening, closing)
    if value(i) ~= opening then
      return nil
    end
    local depth = 1
    i = i + 1
    while tokens[i] do
      if value(i) == "`" then
        return nil
      end
      if value(i) == opening then
        depth = depth + 1
      end
      if value(i) == closing then
        depth = depth - 1
      end
      if depth == 0 then
        return i + 1
      end
      i = i + 1
    end
  end
  local index = 1
  while tokens[index] do
    local start = index
    local keyword = value(start)
    if
      first[tokens[start].row] == start
      and (keyword == "always" or keyword == "always_ff" or keyword == "always_comb" or keyword == "always_latch")
    then
      local changes = {}
      local function mark(i, level)
        if tokens[i] and first[tokens[i].row] == i then
          changes[tokens[i].row] = cfg.Width_always + level * cfg.indent_width
        end
      end
      local function condition(i, level)
        local next_i = balanced(i, "(", ")")
        if next_i then
          for j = i, next_i - 1 do
            mark(j, level + 1)
          end
        end
        return next_i
      end
      local statement
      statement = function(i, level, depth)
        if not i or not tokens[i] or depth > 128 then
          return nil
        end
        mark(i, level)
        local word = value(i)
        if word == "begin" then
          local begin_row = tokens[i].row
          i = i + 1
          if value(i) == ":" then
            i = i + 2
          end -- begin : label
          while tokens[i] and value(i) ~= "end" do
            i = statement(i, level + 1, depth + 1)
            if not i then
              return nil
            end
          end
          if not tokens[i] or tokens[i].row == begin_row then
            return nil
          end
          mark(i, level)
          i = i + 1
          if value(i) == ":" then
            i = i + 2
          end
          return i
        elseif word == "if" or word == "for" or word == "while" or word == "repeat" then
          local after = condition(i + 1, level)
          if not after then
            return nil
          end
          i = statement(after, value(after) == "begin" and level or level + 1, depth + 1)
          if word == "if" and i and value(i) == "else" then
            mark(i, level)
            local next_word = value(i + 1)
            i = statement(i + 1, (next_word == "begin" or next_word == "if") and level or level + 1, depth + 1)
          end
          return i
        elseif word == "case" or word == "casex" or word == "casez" then
          i = condition(i + 1, level)
          while i and tokens[i] and value(i) ~= "endcase" do
            mark(i, level + 1)
            local ternary = 0
            while tokens[i] do
              local v = value(i)
              if v == "?" then
                ternary = ternary + 1
              end
              if v == ":" then
                if ternary == 0 then
                  break
                end
                ternary = ternary - 1
              end
              if v == "endcase" or v == "`" or v == ";" then
                return nil
              end
              i = i + 1
            end
            if not tokens[i] then
              return nil
            end
            i = statement(i + 1, value(i + 1) == "begin" and level + 1 or level + 2, depth + 1)
          end
          if not i or not tokens[i] then
            return nil
          end
          mark(i, level)
          return i + 1
        elseif word == "forever" then
          return statement(i + 1, value(i + 1) == "begin" and level or level + 1, depth + 1)
        end
        -- 普通语句可跨行；避免越过未知块结构或预处理指令。
        local stops = {
          ["end"] = true,
          ["else"] = true,
          endcase = true,
          endmodule = true,
          begin = true,
          always = true,
          always_ff = true,
          always_comb = true,
          always_latch = true,
          ["`"] = true,
        }
        local row = tokens[i].row
        while tokens[i] do
          local v = value(i)
          if stops[v] then
            return nil
          end
          if tokens[i].row ~= row then
            mark(i, level + 1)
          end
          if v == ";" then
            return i + 1
          end
          if v == "(" then
            local after = condition(i, level)
            if not after then
              return nil
            end
            i = after
          else
            i = i + 1
          end
        end
      end
      mark(start, 0)
      local body = start + 1
      if value(body) == "@" then
        body = body + 1
        if value(body) == "(" then
          body = condition(body, 0)
        else
          body = body + 1
        end
      end
      local finish = body and statement(body, value(body) == "begin" and 0 or 1, 0)
      if finish then
        for row, indent in pairs(changes) do
          desired[row] = indent
        end
        index = finish
      else
        index = start + 1
      end
    else
      index = index + 1
    end
  end
  return desired
end

-- 对 if 语句做结构化文本改写。先配对完整语句，再补 begin/end，
-- 因此 dangling else 仍然归属于原来的最近一层 if。
local function normalize_conditionals(lines, rows, cfg, first, last, indents)
  local source = table.concat(lines, "\n")
  local tokens, offsets, offset = {}, {}, 1
  for row, info in ipairs(rows) do
    offsets[row] = offset
    local clean, col = info.macro and "`" or info.clean, 1
    while col <= #clean do
      if clean:sub(col, col):match("%s") then
        col = col + 1
      else
        local word = clean:sub(col):match("^[%a_$][%w_$]*")
          or clean:sub(col):match("^%d[%w_'.]*")
          or clean:sub(col, col)
        tokens[#tokens + 1] = { value = word, row = row, start = offset + col - 1, finish = offset + col + #word - 2 }
        col = col + #word
      end
    end
    offset = offset + #lines[row] + 1
  end
  local function value(i)
    return tokens[i] and tokens[i].value
  end
  local function gap(a, b)
    return source:sub(tokens[a].finish + 1, tokens[b].start - 1)
  end
  -- 约束块、property/sequence 和括号中的 if 不是普通过程语句。
  local parens, braces, brackets, assertion_context = 0, 0, 0, false
  for t, token in ipairs(tokens) do
    local word = token.value
    local previous = value(t - 1)
    if
      (word == "property" or word == "sequence")
      and previous ~= "assert"
      and previous ~= "assume"
      and previous ~= "cover"
      and previous ~= "restrict"
    then
      assertion_context = true
    end
    token.statement_context = parens == 0 and braces == 0 and brackets == 0 and not assertion_context
    if word == "endproperty" or word == "endsequence" then
      assertion_context = false
    end
    if word == "(" then
      parens = parens + 1
    elseif word == ")" then
      parens = math.max(0, parens - 1)
    end
    if word == "{" then
      braces = braces + 1
    elseif word == "}" then
      braces = math.max(0, braces - 1)
    end
    if word == "[" then
      brackets = brackets + 1
    elseif word == "]" then
      brackets = math.max(0, brackets - 1)
    end
  end
  local pairs = { ["("] = ")", ["["] = "]", ["{"] = "}" }
  local function balanced(i)
    local stack = { pairs[value(i)] }
    if #stack == 0 then
      return nil
    end
    i = i + 1
    while tokens[i] do
      local v = value(i)
      if v == "`" then
        return nil
      end
      if pairs[v] then
        stack[#stack + 1] = pairs[v]
      elseif v == ")" or v == "]" or v == "}" then
        if table.remove(stack) ~= v then
          return nil
        end
        if #stack == 0 then
          return i + 1
        end
      end
      i = i + 1
    end
  end
  local parse
  local stops = {
    ["end"] = true,
    ["else"] = true,
    begin = true,
    ["if"] = true,
    case = true,
    casex = true,
    casez = true,
    endcase = true,
    fork = true,
    join = true,
    join_any = true,
    join_none = true,
    ["do"] = true,
    assert = true,
    assume = true,
    cover = true,
    expect = true,
    wait_order = true,
    randcase = true,
    randsequence = true,
    endmodule = true,
    endfunction = true,
    endtask = true,
    endgenerate = true,
    always = true,
    always_ff = true,
    always_comb = true,
    always_latch = true,
    ["`"] = true,
  }
  parse = function(i, depth)
    if not i or not tokens[i] or depth > 128 then
      return nil
    end
    local node = { first = i, kind = value(i) }
    local word = node.kind
    if word == "if" then
      if value(i + 1) ~= "(" then
        return nil
      end
      i = balanced(i + 1)
      if not i then
        return nil
      end
      node.header = i - 1
      node.yes, i = parse(i, depth + 1)
      if not node.yes then
        return nil
      end
      if value(i) == "else" then
        node.otherwise = i
        node.no, i = parse(i + 1, depth + 1)
        if not node.no then
          return nil
        end
      end
    elseif word == "begin" then
      i = i + 1
      if value(i) == ":" then
        if not value(i + 1) or not value(i + 1):match("^[%a_$]") then
          return nil
        end
        i = i + 2
      end
      node.header, node.children = i - 1, {}
      while tokens[i] and value(i) ~= "end" do
        local child
        child, i = parse(i, depth + 1)
        if not child then
          return nil
        end
        node.children[#node.children + 1] = child
      end
      if not tokens[i] then
        return nil
      end
      node.closing = i
      i = i + 1
      if value(i) == ":" then
        if not value(i + 1) or not value(i + 1):match("^[%a_$]") then
          return nil
        end
        i = i + 2
      end
    elseif
      word == "for"
      or word == "while"
      or word == "repeat"
      or word == "wait"
      or word == "forever"
      or word == "@"
      or word == "#"
    then
      i = i + 1
      if word ~= "forever" then
        if value(i) == "(" then
          i = balanced(i)
        elseif word == "@" or word == "#" then
          i = tokens[i] and i + 1 or nil
        else
          return nil
        end
      end
      if not i then
        return nil
      end
      node.header = i - 1
      node.body, i = parse(i, depth + 1)
      if not node.body then
        return nil
      end
      node.kind = "control"
    elseif word == "case" or word == "casex" or word == "casez" then
      if value(i + 1) ~= "(" then
        return nil
      end
      i = balanced(i + 1)
      if not i then
        return nil
      end
      node.header, node.children = i - 1, {}
      while tokens[i] and value(i) ~= "endcase" do
        local label, ternary = i, 0
        while tokens[i] do
          local v = value(i)
          if v == "?" then
            ternary = ternary + 1
          end
          if v == ":" then
            if ternary == 0 then
              break
            end
            ternary = ternary - 1
          end
          if stops[v] or v == ";" then
            return nil
          end
          if pairs[v] then
            i = balanced(i)
          else
            i = i + 1
          end
          if not i then
            return nil
          end
        end
        if not tokens[i] then
          return nil
        end
        local entry = { first = label, header = i }
        entry.body, i = parse(i + 1, depth + 1)
        if not entry.body then
          return nil
        end
        node.children[#node.children + 1] = entry
      end
      if not tokens[i] then
        return nil
      end
      node.closing, node.kind, i = i, "case", i + 1
    else
      node.kind = "simple"
      while tokens[i] do
        local v = value(i)
        if stops[v] or v == ")" or v == "]" or v == "}" then
          return nil
        end
        if v == ";" then
          break
        end
        if pairs[v] then
          i = balanced(i)
        else
          i = i + 1
        end
        if not i then
          return nil
        end
      end
      if not tokens[i] then
        return nil
      end
      i = i + 1
    end
    node.last = i - 1
    return node, i
  end

  local edits, i = {}, 1
  while tokens[i] do
    local node, next_i
    if value(i) == "if" and tokens[i].statement_context then
      node, next_i = parse(i, 0)
    end
    local eligible = node and tokens[node.first].row >= first and tokens[node.last].row <= last
    if eligible then
      for row = tokens[node.first].row, tokens[node.last].row do
        if rows[row].macro or rows[row].escaped or rows[row].unsafe_string then
          eligible = false
          break
        end
      end
    end
    if eligible then
      local out = {}
      local function emit(s, indent)
        out[#out + 1] = spaces(indent) .. s
      end
      -- 语句间的注释保留在原来的语句旁；条件/表达式内部注释移到其前面，
      -- 避免合并换行后 // 吞掉后续代码。字符串作为完整 token 原样保留。
      local function comments(text, indent, inline)
        local line_index = 0
        for line in (text .. "\n"):gmatch("(.-)\n") do
          line_index = line_index + 1
          line = trim(line)
          if line ~= "" then
            if inline and line_index == 1 and #out > 0 then
              out[#out] = out[#out] .. " " .. line
            else
              emit(line, indent)
            end
          end
        end
      end
      local function flat(a, b, indent)
        local parts = {}
        for t = a, b do
          if t > a then
            local between = gap(t - 1, t)
            if between:find("%S") then
              comments(between, indent, false)
              between = " "
            elseif between:find("\n", 1, true) then
              between = " "
            end
            parts[#parts + 1] = between
          end
          parts[#parts + 1] = source:sub(tokens[t].start, tokens[t].finish)
        end
        return table.concat(parts)
      end
      local render, block, branch
      block = function(n, indent, header, leading, tail)
        local opening = flat(n.first, n.header, indent)
        emit((header and (header .. " ") or "") .. opening, indent)
        comments(leading or "", indent + cfg.indent_width, true)
        local previous = n.header
        for _, child in ipairs(n.children) do
          comments(gap(previous, child.first), indent + cfg.indent_width, true)
          render(child, indent + cfg.indent_width, "")
          previous = child.last
        end
        comments(gap(previous, n.closing), indent + cfg.indent_width, true)
        emit(flat(n.closing, n.last, indent), indent)
        comments(tail or "", indent, true)
      end
      branch = function(n, indent, header, leading, tail)
        if n.kind == "begin" then
          block(n, indent, header, leading, tail)
        else
          emit(header .. (cfg.wrap_single_statement and " begin" or ""), indent)
          comments(leading, indent + cfg.indent_width, true)
          render(n, indent + cfg.indent_width, tail)
          if cfg.wrap_single_statement then
            emit("end", indent)
          end
        end
      end
      render = function(n, indent, tail, prefix)
        if n.kind == "if" then
          local header = (prefix or "") .. flat(n.first, n.header, indent)
          -- 统一关键字与条件之间的空格，不改变条件表达式内部的文本。
          header = header:gsub("^if%s*%(", "if ("):gsub("^else if%s*%(", "else if (")
          local middle = n.no and gap(n.yes.last, n.otherwise) or tail
          branch(n.yes, indent, header, gap(n.header, n.yes.first), middle)
          if n.no then
            if n.no.kind == "if" then
              comments(gap(n.otherwise, n.no.first), indent, false)
              render(n.no, indent, tail, "else ")
            else
              branch(n.no, indent, "else", gap(n.otherwise, n.no.first), tail)
            end
          end
        elseif n.kind == "begin" then
          block(n, indent, nil, "", tail)
        elseif n.kind == "control" then
          local header = flat(n.first, n.header, indent)
          if n.body.kind == "begin" then
            block(n.body, indent, header, gap(n.header, n.body.first), tail)
          else
            emit(header, indent)
            comments(gap(n.header, n.body.first), indent + cfg.indent_width, true)
            render(n.body, indent + cfg.indent_width, tail)
          end
        elseif n.kind == "case" then
          emit(flat(n.first, n.header, indent), indent)
          local previous = n.header
          for _, entry in ipairs(n.children) do
            comments(gap(previous, entry.first), indent + cfg.indent_width, true)
            local label = flat(entry.first, entry.header, indent + cfg.indent_width)
            if entry.body.kind == "begin" then
              block(entry.body, indent + cfg.indent_width, label, gap(entry.header, entry.body.first), "")
            else
              emit(label, indent + cfg.indent_width)
              comments(gap(entry.header, entry.body.first), indent + 2 * cfg.indent_width, true)
              render(entry.body, indent + 2 * cfg.indent_width, "")
            end
            previous = entry.body.last
          end
          comments(gap(previous, n.closing), indent + cfg.indent_width, true)
          emit("endcase", indent)
          comments(tail, indent, true)
        else
          emit(flat(n.first, n.last, indent), indent)
          comments(tail, indent, true)
        end
      end
      local start_row, end_row = tokens[node.first].row, tokens[node.last].row
      local base = indents[start_row] or vim.fn.strdisplaywidth(lines[start_row]:match("^%s*"))
      local finish = tokens[node.last].finish
      local end_col = finish - offsets[end_row] + 1
      local tail = ""
      if not rows[end_row].clean:sub(end_col + 1):find("%S") then
        tail = source:sub(finish + 1, offsets[end_row] + #lines[end_row] - 1)
        finish = finish + #tail
      end
      render(node, base, tail)
      local replacement = table.concat(out, "\n")
      local edit_first = tokens[node.first].start
      local prefix = source:sub(offsets[start_row], edit_first - 1)
      if edits[#edits] and edits[#edits].last == edit_first - 1 then
        replacement = replacement:sub(base + 1)
      elseif prefix:find("%S") then
        edit_first = edit_first - #prefix:match("%s*$")
        replacement = "\n" .. replacement
      else
        replacement = replacement:sub(base + 1)
      end
      if finish < offsets[end_row] + #lines[end_row] - 1 then
        replacement = replacement .. "\n" .. spaces(base)
        -- 后面若还有同一行的其他语句，换行但不吞掉它们。
        local trailing = source:sub(finish + 1):match("^[ \t]*")
        finish = finish + #trailing
      end
      edits[#edits + 1] =
        { first = edit_first, last = finish, text = replacement, first_row = start_row, last_row = end_row }
      i = next_i
    else
      i = i + 1
    end
  end
  local protected, delta = {}, 0
  for _, edit in ipairs(edits) do
    local _, old_count = source:sub(edit.first, edit.last):gsub("\n", "")
    local _, new_count = edit.text:gsub("\n", "")
    edit.delta = new_count - old_count
    for row = edit.first_row + delta, edit.last_row + delta + edit.delta do
      protected[row] = true
    end
    delta = delta + edit.delta
  end
  for e = #edits, 1, -1 do
    local edit = edits[e]
    last = last + edit.delta
    source = source:sub(1, edit.first - 1) .. edit.text .. source:sub(edit.last + 1)
  end
  return vim.split(source, "\n", { plain = true }), last, protected
end

function M.format_lines(lines, options, first, last)
  local cfg = vim.tbl_extend("force", {}, simpleAlign, options or {})
  for key, value in pairs(cfg) do
    if key == "wrap_single_statement" then
      assert(type(value) == "boolean", key .. " must be a boolean")
    else
      assert(
        type(value) == "number" and value >= 0 and value == math.floor(value),
        key .. " must be a non-negative integer"
      )
    end
  end
  assert(cfg.num3 >= cfg.upbound + cfg.lowbound + 3, "num3 must be >= upbound + lowbound + 3")
  first, last = first or 1, last or #lines
  local rows = scan(lines)
  local protected
  lines, last, protected = normalize_conditionals(lines, rows, cfg, first, last, always_indents(rows, cfg))
  rows = scan(lines)
  local indents = always_indents(rows, cfg)
  local result = vim.list_slice(lines)
  for row = first, last do
    if indents[row] ~= nil then
      result[row] = spaces(indents[row]) .. lines[row]:gsub("^%s+", "")
    elseif not protected[row] then
      result[row] = format_line(rows[row], cfg) or lines[row]
    end
  end
  return result
end

function M.format_buffer(first, last)
  local buffer = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  first, last = first or 1, last or #lines
  local ok, result = pcall(M.format_lines, lines, nil, first, last)
  if not ok then
    vim.notify("VerilogFormat: " .. result, vim.log.levels.ERROR)
    return
  end
  if vim.deep_equal(lines, result) then
    return
  end
  local view = vim.fn.winsaveview()
  local new_last = last + #result - #lines
  vim.api.nvim_buf_set_lines(buffer, first - 1, last, false, vim.list_slice(result, first, new_last))
  vim.fn.winrestview(view)
end

function M.setup_buffer(buffer)
  vim.api.nvim_buf_create_user_command(buffer, "VerilogFormat", function(args)
    M.format_buffer(args.line1, args.line2)
  end, { range = "%", desc = "Custom Verilog text formatting (supports line ranges)" })
  for _, lhs in ipairs({ "vf", "<leader>vf" }) do
    vim.keymap.set("n", lhs, "<Cmd>VerilogFormat<CR>", { buffer = buffer, desc = "Format Verilog buffer" })
    vim.keymap.set("x", lhs, ":VerilogFormat<CR>", { buffer = buffer, desc = "Format selected Verilog lines" })
  end
end

return M
