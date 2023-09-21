require("evidence.util.dumper")
local bit = require("bit")

local M={}

function M.isInTable(v, tb)
  for _, value in ipairs(tb) do
    if value == v then
      return true
    end
  end
  return false
end

-- array concat
function M.table_concat(...)
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
function M.merge(t1, t2, is_deep)
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
function M.array2Str(tbl, item)
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

function M.str2table(str)
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
function M.isTableEmpty(t, visited)
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
function M.parseDate(date_string, date_format)
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

function M.copy(orig)
  local copy_item = {}
  for k, v in pairs(orig) do
    copy_item[k] = v
  end
  return copy_item
end

function M.deepCopy(orig)
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

function M.printDump(obj)
  if obj == nil then
    print("printDump nil")
  end
  local meta = getmetatable(obj)
  setmetatable(obj, nil)
  print(vim.inspect(obj))
  setmetatable(obj, meta)
end

function M.parse(data)
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
function M.stringify(data)
  return DataDumper(data)
end

---@param prompt string
---@param default string
function M.uiInput(prompt, default, ...)
  if select("#", ...) > 0 then
    local arg = select(1, ...)
    return vim.fn.input(prompt, default, "customlist," .. (arg.name or ""))
  end
  return vim.fn.input(prompt, default)
end

---@param name string
---@return boolean
function M.confirmCheck(name)
  local confirm = uiInput(name .. "  (y/n):", "")
  if confirm ~= "y" then
    print(name .. " failed")
    return false
  end
  return true
end

---@param array table
function M.reverseArray(array)
  local reversedArray = {}
  local length = #array
  for i = length, 1, -1 do
    table.insert(reversedArray, array[i])
  end
  return reversedArray
end

---@param items table|nil
---@param val string
function M.getValArrayFromItem(items, val)
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
function M.clear_match(group, win_id)
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
function M.get_window_id_from_buffer_id(buffer_id)
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
function M.getVisualSelection()
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", {})
  if #text > 0 then
    return text
  else
    return ""
  end
end

---@param arr number[]
---@param lim number
---@return number
function M.findMinMissingNumber(arr, lim)
  local bitmapSize = math.ceil(lim / 32)
  local bitmap = {}

  for _, num in ipairs(arr) do
    local index = math.floor(num / 32) + 1
    local bitPos = num % 32

    bitmap[index] = bit.bor(bitmap[index] or 0, bit.lshift(1, bitPos))
  end

  for i = 1, bitmapSize do
    if not bitmap[i] or bitmap[i] ~= 0xFFFFFFFF then
      for j = 0, 31 do
        if not (bitmap[i] and bit.band(bit.rshift(bitmap[i], j), 1) == 1) then
          return (i - 1) * 32 + j
        end
      end
    end
  end

  return -1
end

---@param count number
---@return string[]
function M.generateDistinctColors(count)
  local colors = {}

  local step = 360 / count

  for i = 1, count do
    local hue = (i - 1) * step

    local h = hue / 360
    local s = 1
    local v = 1

    local r, g, b
    if s == 0 then
      r, g, b = v, v, v
    else
      local i = math.floor(h * 6)
      local f = h * 6 - i
      local p = v * (1 - s)
      local q = v * (1 - s * f)
      local t = v * (1 - s * (1 - f))

      if i % 6 == 0 then
        r, g, b = v, t, p
      elseif i % 6 == 1 then
        r, g, b = q, v, p
      elseif i % 6 == 2 then
        r, g, b = p, v, t
      elseif i % 6 == 3 then
        r, g, b = p, q, v
      elseif i % 6 == 4 then
        r, g, b = t, p, v
      else
        r, g, b = v, p, q
      end
    end
    local hex = string.format("#%02X%02X%02X", r * 255, g * 255, b * 255)
    table.insert(colors, hex)
  end

  return colors
end

-- 在字符串的指定下标位置处添加新的字符串
---@param originalString string
---@param position number
---@param newString string
function M.insertStringAtPosition(originalString, position, newString)
  local firstPart = originalString:sub(1, position)
  local secondPart = originalString:sub(position + 1)
  local finalString = firstPart .. newString .. secondPart
  return finalString
end

---@return SelectRegion | {}
function M.getVisualSelectPos()
  local a1, a2, a3, a4 = unpack(vim.fn.getpos("'<"))
  local b1, b2, b3, b4 = unpack(vim.fn.getpos("'>"))
  --print(vim.inspect(a1 .. " " .. a2 .. " " .. a3 .. " " .. a4))
  --print(vim.inspect(b1 .. " " .. b2 .. " " .. b3 .. " " .. b4))
  if a2 == 0 and a3 == 0 and b2 == 0 and b3 == 0 then
    return {}
  end
  return {
    startRow = a2,
    startCol = a3,
    endRow = b2,
    endCol = b3,
  }
end

---@param array table
---@param element any
function M.removeValFromArray(array, element)
  local index = 1
  while index <= #array do
    if array[index] == element then
      table.remove(array, index)
    else
      index = index + 1
    end
  end
end

---@param file string
function M.file_exists(file)
  local f = io.open(file, "r")
  if f then
    io.close(f)
    return true
  else
    return false
  end
end

return M
