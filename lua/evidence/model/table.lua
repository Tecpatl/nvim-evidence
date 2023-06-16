local tools = require("evidence.util.tools")
local tblInfo = require("evidence.model.info")

local now_time = os.time()

---@class SqlInfo
---@field uri string
---@field is_record boolean
local SqlInfo = {}

---@class CardField
---@field id number
---@field content string
---@field due Timestamp
---@field info string fsrs data
---@field file_type string "markdown" | "org"

---@class RecordCardField
---@field id number
---@field card_id number
---@field content string
---@field due Timestamp
---@field info string fsrs data
---@field file_type string "markdown" | "org"
---@field timestamp Timestamp
---@field access_way AccessWayType

---@class TagField
---@field id number
---@field name string
---@field father_id number

---@class CardTagField
---@field card_id number
---@field tag_id number

---@alias TablesType string
local Tables = {
  card = "card",
  tag = "tag",
  card_tag = "card_tag",
  record_card = "record_card",
}

---@class SqlTable
---@field sql any
---@field db any
---@field uri string sql path
---@field is_record boolean
local SqlTable = {}
SqlTable.__index = SqlTable

function SqlTable:new()
  --- !! attention sql command only db:eval db:execute due to "sqlite.db" not support composite primary key and foreign keys
  self.sql = require("sqlite.db")
  self.db = nil
  self.uri = ""
  self.is_record = false
  return setmetatable({}, self)
end

function SqlTable:dump()
  return {
    uri = self.uri,
    is_record = self.is_record,
  }
end

function SqlTable:createTrigger(name, content)
  local is_trigger = self:eval([[
    SELECT COUNT(*) AS trigger_count
    FROM sqlite_master
    WHERE type = 'trigger'
      AND name = ']] .. name .. [[';
    ]])[1]["trigger_count"]
  print(is_trigger)

  if is_trigger == 0 then
    self:eval(content)
  end
end

---@param data SqlInfo
function SqlTable:setup(data)
  assert(data.uri ~= nil, "uri required")
  self.uri = data.uri
  self.is_record = data.is_record or false

  self.db = self.sql:open(self.uri)

  self.db:execute("PRAGMA foreign_keys = ON;")

  self.db:execute([[
    create table if not exists card(
      id INTEGER primary KEY AUTOINCREMENT,
      content text NOT NULL,
      due int NOT NULL,
      info text NOT NULL,
      file_type text NOT NULL
    )]])

  self.db:execute([[
    create table if not exists tag(
      id INTEGER primary KEY AUTOINCREMENT,
      name text NOT NULL UNIQUE,
      father_id int DEFAULT -1
    )]])

  self.db:execute([[
    create table if not exists card_tag(
      tag_id int NOT NULL,
      card_id int NOT NULL,
      PRIMARY KEY (card_id, tag_id),
      FOREIGN KEY (card_id) REFERENCES card(id),
      FOREIGN KEY (tag_id) REFERENCES tag(id)
    )]])

  self.db:execute([[
    CREATE TABLE IF NOT EXISTS record_card (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      card_id INTEGER,
      content text NOT NULL,
      due int NOT NULL,
      info text NOT NULL,
      file_type text NOT NULL,
      timestamp int not null,
      access_way int not null
    )]])
end

---@param query string
---@return nil | table
function SqlTable:eval(query)
  --print(query)
  local item = self.db:eval(query)
  if type(item) ~= "table" then
    item = nil
  end
  if tools.isTableEmpty(item) then
    return nil
  end
  return item
end

---@return number id
function SqlTable:getLastId()
  local item = self:eval("SELECT last_insert_rowid();")
  if item == nil then
    error("getLastId")
  end
  return item[1]["last_insert_rowid()"]
end

---@param id number
---@return CardField
function SqlTable:findCardById(id)
  local ret = self:findCard(1, "id=" .. id)
  if ret ~= nil then
    return ret[1]
  else
    error("findCardById not exist id:" .. id)
  end
end

---@param limit_num number
---@param access_ways AccessWayType[]
---@return RecordCardField | nil
function SqlTable:findRecordCard(limit_num, access_ways)
  local query = "SELECT * FROM " .. Tables.record_card
  if not tools.isTableEmpty(access_ways) then
    local way_str = ""
    for key, val in pairs(access_ways) do
      if way_str ~= "" then
        way_str = way_str .. ","
      end
      way_str = way_str .. val
    end
    query = query .. " where access_way in (" .. way_str .. " ) "
  end
  if limit_num ~= nil and limit_num ~= -1 then
    query = query .. " LIMIT " .. limit_num
  end
  return self:eval(query)
end

---@param card_id number
---@param access_way AccessWayType
function SqlTable:insertRecordCard(card_id, access_way)
  if self.is_record then
    self.db:execute([[
      DELETE FROM record_card
      WHERE id IN (
        SELECT id
        FROM record_card
        ORDER BY id ASC
        LIMIT 1
      )
      AND (
        SELECT COUNT(*)
        FROM record_card
      ) > 100;
    ]])

    local card = self:findCardById(card_id)
    self.db:insert(Tables.record_card, {
      card_id = card_id,
      content = card.content,
      info = card.info,
      due = card.due,
      file_type = card.file_type,
      timestamp = os.time(),
      access_way = access_way,
    })
  end
end

---@param content string
---@param info string
---@param due Timestamp
---@param file_type? string
---@return number id
function SqlTable:insertCard(content, info, due, file_type)
  if not file_type or file_type == "" then
    file_type = "markdown"
  end
  self.db:insert(Tables.card, { content = content, info = info, due = due, file_type = file_type })
  local id = self:getLastId()
  self:insertRecordCard(id, tblInfo.AccessWay.insert)
  return id
end

---@param name string
---@param father_id? number
---@return number id
function SqlTable:insertTag(name, father_id)
  father_id = father_id or -1
  self.db:insert(Tables.tag, { name = name, father_id = father_id })
  return self:getLastId()
end

---@param id number
---@param row TagField
function SqlTable:editTag(id, row)
  row["id"] = nil
  return self.db:update(Tables.tag, {
    where = { id = id },
    set = row,
  })
end

---@param statement string
---@param limit_num number
function SqlTable:findCardTag(statement, limit_num)
  local query = "select * from " .. Tables.card_tag .. " where " .. statement .. " LIMIT " .. limit_num
  self.db:execute(query)
end

---@param card_id number
---@param tag_id number
function SqlTable:insertCardTag(card_id, tag_id)
  self.db:insert(Tables.card_tag, { card_id = card_id, tag_id = tag_id })
end

---@param card_id number
---@param tag_id number
function SqlTable:delCardTag(card_id, tag_id)
  local query = "delete from " .. Tables.card_tag .. " where card_id=" .. card_id .. " and tag_id=" .. tag_id
  self.db:execute(query)
end

---@param id number
---@param row CardField
function SqlTable:editCard(id, row)
  self:insertRecordCard(id, tblInfo.AccessWay.edit)
  row["id"] = nil
  return self.db:update(Tables.card, {
    where = { id = id },
    set = row,
  })
end

---@param card_id number
---@param is_include boolean
---@return nil | TagField[]
function SqlTable:findTagsByCard(card_id, is_include)
  local query = ""
  if is_include == true then
    query = "SELECT t.* FROM "
        .. Tables.card_tag
        .. " AS ct JOIN "
        .. Tables.tag
        .. " AS t ON "
        .. "ct.tag_id = t.id"
        .. " WHERE ct.card_id = "
        .. card_id
  else
    query = "SELECT * FROM "
        .. Tables.tag
        .. " WHERE id NOT IN ( SELECT tag_id FROM card_tag WHERE card_id = "
        .. card_id
        .. " )"
  end
  return self:eval(query)
end

---@param old_tag_ids number[] tag would_be_delete
---@param new_tag_id number
function SqlTable:mergeTags(old_tag_ids, new_tag_id)
  local tag_str = ""
  for key, val in pairs(old_tag_ids) do
    if tag_str ~= "" then
      tag_str = tag_str .. ","
    end
    tag_str = tag_str .. val
  end
  local query = ""
  -- useless demand
  --if new_tag_id ~= -1 and is_card_update_tag == true then
  --  query = "INSERT OR IGNORE INTO "
  --      .. Tables.card_tag
  --      .. " (card_id, tag_id) SELECT card_id, "
  --      .. new_tag_id
  --      .. " FROM card_tag WHERE tag_id IN ("
  --      .. tag_str
  --      .. ") UNION ALL SELECT card_id,"
  --      .. new_tag_id
  --      .. " from "
  --      .. Tables.card_tag
  --      .. " where tag_id="
  --      .. new_tag_id
  --  self.db:execute(query)
  --end
  query = "DELETE FROM "
      .. Tables.card_tag
      .. " WHERE tag_id IN ("
      .. tag_str
      .. ")"
      .. " AND card_id IN ( SELECT card_id FROM "
      .. Tables.card_tag
      .. " WHERE tag_id IN ("
      .. tag_str
      .. ")"
      .. ")"
  self.db:execute(query)
  query = "delete from " .. Tables.tag .. " where id IN (" .. tag_str .. ")"
  self.db:execute(query)
end

---@param tag_ids number[]
---@param limit_num? number
---@param is_and? boolean
---@param column? string
---@return nil | CardField[]
function SqlTable:findCardsByTags(tag_ids, limit_num, is_and, column)
  if is_and == nil then
    is_and = true
  end
  column = column or "*"
  if type(tag_ids) ~= "table" or tools.isTableEmpty(tag_ids) then
    return
  end
  local tag_str = ""
  local cnt = #tag_ids
  for key, val in pairs(tag_ids) do
    if tag_str ~= "" then
      tag_str = tag_str .. ","
    end
    tag_str = tag_str .. val
  end
  local query = "SELECT c."
      .. column
      .. " FROM "
      .. Tables.card
      .. " AS c JOIN "
      .. Tables.card_tag
      .. " AS ct ON c.id = ct.card_id JOIN "
      .. Tables.tag
      .. " AS t ON ct.tag_id = t.id WHERE t.id IN ("
      .. tag_str
      .. ") GROUP BY c.id"
  if is_and then
    query = query .. " HAVING COUNT(DISTINCT t.id) = " .. cnt
  end
  if limit_num ~= nil and limit_num ~= -1 then
    query = query .. " LIMIT " .. limit_num
  end
  return self:eval(query)
end

---@param limit_num? number
---@param statement? string | nil
---@return nil | TagField[]
function SqlTable:findTag(limit_num, statement)
  local query = "SELECT * FROM " .. Tables.tag
  if statement ~= nil then
    query = query .. " where " .. statement
  end
  if limit_num ~= nil and limit_num ~= -1 then
    query = query .. " LIMIT " .. limit_num
  end
  return self:eval(query)
end

---@param limit_num? number
---@param statement? string | nil
---@return nil | CardField[]
function SqlTable:findCard(limit_num, statement)
  local query = "SELECT * FROM " .. Tables.card
  if statement ~= nil then
    query = query .. " where " .. statement
  end
  if limit_num ~= nil and limit_num ~= -1 then
    query = query .. " LIMIT " .. limit_num
  end
  return self:eval(query)
end

---@param tag_ids number[]
---@param is_and boolean
---@param limit_num number
---@param statement string
---@param is_shuffle? boolean
---@return CardItem[]|nil
function SqlTable:findCardWithTags(tag_ids, is_and, limit_num, statement, is_shuffle)
  if type(tag_ids) ~= "table" or tools.isTableEmpty(tag_ids) then
    return self:findCard(limit_num, statement)
  else
    local tag_str = ""
    local cnt = #tag_ids
    for key, val in pairs(tag_ids) do
      if tag_str ~= "" then
        tag_str = tag_str .. ","
      end
      tag_str = tag_str .. val
    end
    query = "SELECT c.* FROM "
        .. Tables.card
        .. " AS c JOIN "
        .. Tables.card_tag
        .. " AS ct ON c.id = ct.card_id JOIN "
        .. Tables.tag
        .. " AS t ON ct.tag_id = t.id WHERE t.id IN ("
        .. tag_str
        .. ") "
    if statement ~= "" then
      query = query .. " AND " .. statement
    end
    query = query .. " GROUP BY c.id "
    if is_and then
      query = query .. " HAVING COUNT(DISTINCT t.id) = " .. cnt
    end
    if is_shuffle == true then
      query = query .. " order by random()%1000 "
    end
    if limit_num ~= -1 then
      query = query .. " LIMIT " .. limit_num
    end
    return self:eval(query)
  end
end

---@param id number
function SqlTable:delTag(id)
  local query = "delete from " .. Tables.card_tag .. " where tag_id=" .. id
  self.db:execute(query)
  query = "delete from " .. Tables.tag .. " where id=" .. id
  self.db:execute(query)
end

---@param id number
function SqlTable:delCard(id)
  self:insertRecordCard(id, tblInfo.AccessWay.delete)
  local query = "delete from " .. Tables.card_tag .. " where card_id=" .. id
  self.db:execute(query)
  query = "delete from " .. Tables.card .. " where id=" .. id
  self.db:execute(query)
end

---@param tag_ids number[]
---@param is_and boolean
---@param column string
---@param statement? string
---@param limit_num? number
---@return nil | CardField[]
function SqlTable:minCardWithTags(tag_ids, is_and, column, statement, limit_num)
  limit_num = limit_num or 1
  local query = ""
  if type(tag_ids) ~= "table" or tools.isTableEmpty(tag_ids) then
    if limit_num ~= 1 then
      query = "SELECT * FROM " .. Tables.card
    else
      query = "SELECT *, MIN(" .. column .. ") AS `rowmin` FROM " .. Tables.card
    end
    if statement ~= nil then
      query = query .. " where " .. statement
    end
    if limit_num ~= -1 then
      query = query .. " order by " .. column .. " LIMIT " .. limit_num
    end
  else
    local tag_str = ""
    local cnt = #tag_ids
    for key, val in pairs(tag_ids) do
      if tag_str ~= "" then
        tag_str = tag_str .. ","
      end
      tag_str = tag_str .. val
    end
    query = "SELECT c.* FROM "
        .. Tables.card
        .. " AS c JOIN "
        .. Tables.card_tag
        .. " AS ct ON c.id = ct.card_id JOIN "
        .. Tables.tag
        .. " AS t ON ct.tag_id = t.id WHERE t.id IN ("
        .. tag_str
        .. ") "
        .. " AND "
        .. statement
        .. " GROUP BY c.id "
    if is_and then
      query = query .. " HAVING COUNT(DISTINCT t.id) = " .. cnt
    end
    query = query .. " ORDER BY c." .. column .. " ASC "
    if limit_num ~= -1 then
      query = query .. " LIMIT " .. limit_num
    end
  end
  --print(query)
  return self:eval(query)
end

function SqlTable:close()
  self.db:close()
end

function SqlTable:clear()
  -- card_tag drop before card and tag
  local order = { Tables.card_tag, Tables.card, Tables.tag, Tables.record_card }

  for _, key in ipairs(order) do
    local v = Tables[key]
    local query = "delete from " .. v .. "; VACUUM; UPDATE SQLITE_SEQUENCE SET seq = 0 WHERE name = '" .. v .. "'"
    self.db:execute(query)
  end
end

return SqlTable
