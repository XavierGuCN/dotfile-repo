-- Inst Same-name Port and Net: connect .name to the net with the same name.
local M = {}

local identifier = "^[%a_][%w_$]*$"
local forbidden = {
  module = true,
  ["function"] = true,
  task = true,
  interface = true,
  program = true,
  input = true,
  output = true,
  inout = true,
  wire = true,
  logic = true,
  reg = true,
  assign = true,
  ["return"] = true,
}

-- Mask comments and strings without changing byte offsets or line numbers.
local function mask(text)
  local out, i = {}, 1
  while i <= #text do
    local pair, c = text:sub(i, i + 1), text:sub(i, i)
    local finish
    if pair == "//" then
      finish = (text:find("\n", i + 2, true) or (#text + 1)) - 1
    elseif pair == "/*" then
      local ending = text:find("*/", i + 2, true)
      if not ending then
        return nil
      end
      finish = ending + 1
    elseif c == '"' then
      finish = i + 1
      while finish <= #text do
        local ch = text:sub(finish, finish)
        if ch == "\\" then
          finish = finish + 2
        elseif ch == '"' then
          break
        else
          finish = finish + 1
        end
      end
      if finish > #text then
        return nil
      end
    end
    if finish then
      out[#out + 1] = text:sub(i, finish):gsub("[^\n]", " ")
      i = finish + 1
    else
      out[#out + 1], i = c, i + 1
    end
  end
  return table.concat(out)
end

local function tokenize(lines)
  local tokens, stack = {}, {}
  for row, line in ipairs(lines) do
    local col = 1
    while col <= #line do
      local c = line:sub(col, col)
      if c:match("%s") then
        col = col + 1
      else
        local value = line:sub(col):match("^[%a_][%w_$]*") or c
        local token = { value = value, row = row, col = col }
        tokens[#tokens + 1] = token
        if value == "(" then
          stack[#stack + 1] = #tokens
        elseif value == ")" and #stack > 0 then
          local opening = table.remove(stack)
          tokens[opening].mate, token.mate = #tokens, opening
        end
        col = col + #value
      end
    end
  end
  return tokens
end

-- Return a replacement buffer and cursor position, or a reason for leaving it alone.
function M.instantiate_lines(lines, row)
  local clean = mask(table.concat(lines, "\n"))
  if not clean then
    return nil, "Unterminated comment or string"
  end
  local masked = vim.split(clean, "\n", { plain = true })
  local name = masked[row]:match("^%s*%.?([%a_][%w_$]*)%s*$")
  if not name then
    return nil, "Expected a standalone name or .name on the current line"
  end
  -- A trailing line comment is supported; do not consume block comments or strings.
  local suffix = lines[row]:match("(//.*)$") or ""
  local raw = suffix ~= "" and lines[row]:sub(1, #lines[row] - #suffix) or lines[row]
  if not raw:match("^%s*%.?[%a_][%w_$]*%s*$") then
    return nil, "The current line contains unsupported text"
  end

  local tokens = tokenize(masked)
  local opening, closing
  for i, token in ipairs(tokens) do
    if token.value == "(" and token.row < row and token.mate and tokens[token.mate].row > row then
      opening, closing = i, token.mate
    end
  end
  if not opening then
    return nil, "No closed instance port list found"
  end
  local instance, type_index = tokens[opening - 1], opening - 2
  if not instance or not instance.value:match(identifier) then
    return nil, "Cannot identify the instance name"
  end
  if tokens[type_index] and tokens[type_index].value == ")" then
    local parameter_open = tokens[type_index].mate
    if not parameter_open or not tokens[parameter_open - 1] or tokens[parameter_open - 1].value ~= "#" then
      return nil, "Cannot identify the parameter list"
    end
    type_index = parameter_open - 2
  end
  local module_type, before = tokens[type_index], tokens[type_index - 1]
  if
    not module_type
    or not module_type.value:match(identifier)
    or forbidden[module_type.value]
    or (before and forbidden[before.value])
  then
    return nil, "Cannot identify a module instance at the current position"
  end
  local first, last = tokens[opening].row, tokens[closing].row
  if
    masked[first]:sub(tokens[opening].col + 1):match("%S")
    or masked[last]:sub(1, tokens[closing].col - 1):match("%S")
  then
    return nil, "Only port lists with one port per line are supported"
  end

  local entries, reference = {}, nil
  for r = first + 1, last - 1 do
    local line = masked[r]
    if line:match("%S") then
      local indent, port, between, expression, comma = line:match("^(%s*)%.([%a_][%w_$]*)(%s*)(%b())%s*(,?)%s*$")
      local entry = { row = r }
      if port then
        local left = #indent + #port + #between + 2
        local right = left + #expression - 1
        entry.comma = comma == ","
        entry.complete = true
        entry.insert_at = right
        entry.indent = lines[r]:sub(1, #indent)
        entry.left = vim.fn.strdisplaywidth(lines[r]:sub(1, left - 1))
        entry.right = vim.fn.strdisplaywidth(lines[r]:sub(1, right - 1))
        if not reference or math.abs(r - row) < math.abs(reference.row - row) then
          reference = entry
        end
      elseif line:match("^%s*%.?[%a_][%w_$]*%s*$") then
        entry.insert_at = #line:gsub("%s+$", "")
      else
        return nil, "The port list contains multiline connections, conditional compilation, or unrecognized ports"
      end
      entries[#entries + 1] = entry
    end
  end
  local position
  for i, entry in ipairs(entries) do
    if entry.row == row then
      position = i
    end
  end
  if not position then
    return nil, "Current port not found"
  end
  local indent = reference and reference.indent or lines[row]:match("^%s*")
  local result = indent .. "." .. name
  local width = vim.fn.strdisplaywidth(result)
  result = result .. string.rep(" ", math.max(1, reference and reference.left - width or 1)) .. "(" .. name
  local cursor = #result
  width = vim.fn.strdisplaywidth(result)
  result = result .. string.rep(" ", math.max(0, reference and reference.right - width or 0)) .. ")"
  if position < #entries then
    result = result .. ","
  end
  if suffix ~= "" then
    result = result .. " " .. suffix
  end
  local output = vim.deepcopy(lines)
  output[row] = result
  local previous = entries[position - 1]
  if previous and previous.complete and not previous.comma then
    local line = output[previous.row]
    output[previous.row] = line:sub(1, previous.insert_at) .. "," .. line:sub(previous.insert_at + 1)
  end
  return output, cursor
end

function M.instantiate_same_name_port_net()
  local buffer = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local output, cursor = M.instantiate_lines(lines, row)
  if not output then
    vim.notify("InstSameNamePortNet: " .. cursor, vim.log.levels.INFO)
    return
  end
  local first, last = row, row
  for r = 1, #lines do
    if lines[r] ~= output[r] then
      first, last = math.min(first, r), math.max(last, r)
    end
  end
  vim.api.nvim_buf_set_lines(buffer, first - 1, last, false, vim.list_slice(output, first, last))
  vim.api.nvim_win_set_cursor(0, { row, cursor })
end

function M.setup_buffer(buffer)
  vim.api.nvim_buf_create_user_command(
    buffer,
    "InstSameNamePortNet",
    M.instantiate_same_name_port_net,
    { desc = "Inst Same-name Port and Net" }
  )
  vim.keymap.set(
    "n",
    "<leader>vp",
    M.instantiate_same_name_port_net,
    { buffer = buffer, desc = "Inst Same-name Port and Net" }
  )
  vim.keymap.set(
    "i",
    "<C-g>p",
    M.instantiate_same_name_port_net,
    { buffer = buffer, desc = "Inst Same-name Port and Net" }
  )
end

return M
