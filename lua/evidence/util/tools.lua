require("evidence.util.dumper")

local function isInTable(v, tb)
  for _, value in ipairs(tb) do
    if value == v then
      return true
    end
  end
  return false
end

-- array concat
local function table_concat(...)
  local nargs = select("#", ...)
  local argv = { ... }
  local t = {}
  for i = 1, nargs do
    local array = argv[i]
    if type(array) == "table" then
      for j = 1, #array do
        t[#t + 1] = array[j]
      end
    else
      t[#t + 1] = array
    end
  end

  return t
end

-- t2 merge into t1
-- force overlay
---@param is_deep? boolean
local function merge(t1, t2, is_deep)
  if is_deep == nil then
    is_deep = true
  end
  for k, v in pairs(t2) do
    if is_deep == true and (type(v) == "table") and (type(t1[k] or false) == "table") then
      merge(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end

---@param tbl table|nil
---@param item? string
---@return string
local function array2Str(tbl, item)
  if tbl == nil then
    return "{}"
  end
  local str = "{"
  for i, value in ipairs(tbl) do
    if item ~= nil then
      value = value[item]
    end
    str = str .. tostring(value)
    if i ~= #tbl then
      str = str .. ","
    end
  end
  str = str .. "}"
  return str
end

local function str2table(str)
  local lines = {}
  local current_line = ""
  for c in str:gmatch(".") do
    if c ~= "\r" and c ~= "\n" then
      current_line = current_line .. c
    else
      if current_line ~= "" then
        table.insert(lines, current_line)
      else
        table.insert(lines, "")
      end
      current_line = ""
    end
  end
  if current_line ~= "" then
    table.insert(lines, current_line)
  end
  return lines
end

--- check {{{}}}
local function isTableEmpty(t, visited)
  if type(t) ~= "table" then
    return false
  end
  visited = visited or {} -- 初始化 visited 表
  if visited[t] then
    return true -- 如果 t 已经被访问过，认为它是空表
  end
  visited[t] = true -- 将 t 加入 visited 表中
  for _, v in pairs(t) do
    if type(v) == "table" then
      if not isTableEmpty(v, visited) then
        return false
      end
    else
      if v ~= nil then
        return false
      end
    end
  end
  return true
end

---@return integer
local function parseDate(date_string, date_format)
  local year, month, day, hour, minute, second = date_string:match(date_format)
  local date_table = {
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(minute),
    sec = tonumber(second),
  }
  assert(isTableEmpty(date_table) == false)
  return os.time(date_table)
end

local function copy(orig)
  local copy_item = {}
  for k, v in pairs(orig) do
    copy_item[k] = v
  end
  return copy_item
end

local function deepCopy(orig)
  local copy_item
  if type(orig) == "table" then
    copy_item = {}
    for k, v in next, orig, nil do
      copy_item[deepCopy(k)] = deepCopy(v)
    end
    setmetatable(copy_item, deepCopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy_item = orig
  end
  return copy_item
end

local function printDump(obj)
  if obj == nil then
    print("printDump nil")
  end
  local meta = getmetatable(obj)
  setmetatable(obj, nil)
  print(vim.inspect(obj))
  setmetatable(obj, meta)
end

local function parse(data)
  local obj = loadstring(data)
  if obj then
    obj = obj()
    return obj
  else
    error("loadstring parse failed")
  end
end

---full info
---@return string
local function stringify(data)
  return DataDumper(data)
end

---@param prompt string
---@param default string
local function uiInput(prompt, default, ...)
  if select("#", ...) > 0 then
    local arg = select(1, ...)
    return vim.fn.input(prompt, default, "customlist," .. (arg.name or ""))
  end
  return vim.fn.input(prompt, default)
end

---@param name string
---@return boolean
local function confirmCheck(name)
  local confirm = uiInput(name .. "  (y/n):", "")
  if confirm ~= "y" then
    print(name .. " failed")
    return false
  end
  return true
end

---@param array table
local function reverseArray(array)
  local reversedArray = {}
  local length = #array
  for i = length, 1, -1 do
    table.insert(reversedArray, array[i])
  end
  return reversedArray
end

---@param items table|nil
---@param val string
local function getValArrayFromItem(items, val)
  local res = {}
  if type(items) == "table" then
    for _, item in pairs(items) do
      table.insert(res, item[val])
    end
  end
  return res
end

---@param group string
---@param win_id? number
local function clear_match(group, win_id)
  if win_id == nil then
    win_id = vim.fn.win_getid()
  end
  local matches = vim.fn.getmatches(win_id)
  for _, match in pairs(matches) do
    if match.group == group then
      vim.fn.matchdelete(match.id, win_id)
    end
  end
end

---@param buffer_id number
---@return nil|number
local function get_window_id_from_buffer_id(buffer_id)
  local windows = vim.api.nvim_list_wins()
  for _, win_id in ipairs(windows) do
    local buf_id = vim.api.nvim_win_get_buf(win_id)
    if buf_id == buffer_id then
      return win_id
    end
  end
  return nil
end

---@return string
local function getVisualSelection()
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", {})
  if #text > 0 then
    return text
  else
    return ""
  end
end

return {
  isInTable = isInTable,
  table_concat = table_concat,
  merge = merge,
  str2table = str2table,
  isTableEmpty = isTableEmpty,
  parseDate = parseDate,
  copy = copy,
  deepCopy = deepCopy,
  printDump = printDump,
  parse = parse,
  stringify = stringify,
  uiInput = uiInput,
  confirmCheck = confirmCheck,
  array2Str = array2Str,
  reverseArray = reverseArray,
  getValArrayFromItem = getValArrayFromItem,
  clear_match = clear_match,
  get_window_id_from_buffer_id = get_window_id_from_buffer_id,
  getVisualSelection = getVisualSelection,
}
