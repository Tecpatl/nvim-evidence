local tools = require("evidence.util.tools")

local now_time = os.time()

---@class SqlInfo
---@field uri string
---@field all_table_id table<string>
---@field now_table_id string
local SqlInfo = {}

---@class FsrsTableField
---@field id number
---@field content string
---@field due Timestamp
---@field info string fsrs data
---@field file_type string "markdown" | "org"
local FsrsTableField = {
  id = 0, -- same as { type = "integer", required = true, primary = true }
  content = "text",
  due = now_time,
  info = "",
  file_type = "markdown",
}

---@class SqlTable
---@field sqlite any
---@field tbl any
---@field uri string sql path
---@field all_table_id table<string>
---@field now_table_id string
---@field now_table any
---@field all_table table<string,any>
---@field table_field table<string,any>
local SqlTable = {}
SqlTable.__index = SqlTable

function SqlTable:new()
  self.sqlite = require("sqlite.db")
  self.tbl = require("sqlite.tbl")
  self.uri = ""
  self.all_table_id = {}
  self.now_table_id = ""
  self.now_table = nil
  self.table_field = {
    id = true, -- same as { type = "integer", required = true, primary = true }
    content = { "text" },
    due = { "number" },
    info = { "text", required = true },
    file_type = { "text" },
  }
  self.all_table = {}
  return setmetatable({}, self)
end

function SqlTable:dump()
  return {
    uri = self.uri,
    all_table_id = self.all_table_id,
    now_table_id = self.now_table_id,
  }
end

---@param data SqlInfo
function SqlTable:setup(data)
  assert(data.uri ~= nil, "uri required")
  assert(type(data.all_table_id) == "table", "all_table_id required table")
  assert(type(data.now_table_id) == "string", "now_table_id required string")
  self.uri = data.uri
  self.all_table_id = data.all_table_id
  self.now_table_id = data.now_table_id

  for _k, item in pairs(self.all_table_id) do
    local tb = self.tbl(item, self.table_field)
    self.all_table[item] = tb
  end

  self.now_table = self.all_table[self.now_table_id]

  local uri_map = { uri = self.uri }
  self.sqlite(tools.merge(uri_map, self.all_table))
end

---@return table<string>
function SqlTable:getTableIds()
  return self.all_table_id
end

---@param content string
---@param info string
---@param due Timestamp
---@param file_type? string
function SqlTable:insertCard(content, info, due, file_type)
  if not file_type or file_type == "" then
    file_type = "markdown"
  end
  self.now_table:insert({ content = content, info = info, due = due, file_type = file_type })
end

---@param id number
---@param row FsrsTableField
---@return boolean
function SqlTable:editById(id, row)
  row["id"] = nil
  return self.now_table:update({
    where = { id = id },
    set = row,
  })
end

---@param query string
---@return nil | table
function SqlTable:eval(query)
  local item = self.now_table:eval(query)
  if tools.isTableEmpty(item) then
    return nil
  end
  return item
end

function SqlTable:clear()
  return self:eval("delete from " .. self.now_table_id)
end

---@param limit_num number
---@param statement string | nil
---@return nil | FsrsTableField[]
function SqlTable:find(limit_num, statement)
  local query = "SELECT * FROM " .. self.now_table_id
  if statement ~= nil then
    query = query .. " where " .. statement
  end
  if limit_num ~= -1 then
    query = query .. " LIMIT " .. limit_num
  end
  local ret = self:eval(query)
  if type(ret) ~= "table" then
    return nil
  end
  return ret
end

---@param id number
function SqlTable:del(id)
  self.now_table:remove({ id = id })
end

---@param column string
---@param statement? string
---@param limit_num? number
---@return nil | FsrsTableField[]
function SqlTable:min(column, statement, limit_num)
  limit_num = limit_num or 1
  local query = ""
  if limit_num ~= 1 then
    query = "SELECT * FROM " .. self.now_table_id .. " order by " .. column
  else
    query = "SELECT *, MIN(" .. column .. ") AS `rowmin` FROM " .. self.now_table_id
  end
  if statement ~= nil then
    query = query .. " where " .. statement
  end
  if limit_num ~= -1 then
    query = query .. " LIMIT " .. limit_num
  end
  local ret = self:eval(query)
  if ret ~= nil then
    return ret
  else
    return nil
  end
end

---@param table_id string
---@return boolean
function SqlTable:setTable(table_id)
  if tools.isInTable(table_id, self.all_table_id) then
    self.now_table_id = table_id
    self.now_table = self.all_table[table_id]
    return true
  end
  return false
end

return SqlTable
