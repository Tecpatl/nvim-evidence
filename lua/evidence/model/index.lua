local SqlTable = require("evidence.model.table")
local _FSRS_ = require("evidence.model.fsrs")
local _ = _FSRS_.model
local tools = require("evidence.util.tools")

---@class CardItem
---@field id number
---@field content string
---@field due Timestamp
---@field card Card
---@field file_type string "markdown" | "org"
--
---@class ModelTableInfo
---@field uri string
---@field paramter Parameters

---@class Model
---@field tbl SqlTable
---@field is_setup boolean
---@field paramter Parameters
---@field instance Model
local Model = {}

Model.__index = function(self, key)
  local value = rawget(Model, key)
  if key ~= "setup" then
    if not self.is_setup then
      error("Class not initialized. Please call setup() first.", 2)
    end
  end
  return value
end

Model.__newindex = function()
  error("Attempt to modify a read-only table")
end

function Model:getInstance()
  if not self.instance then
    self.tbl = SqlTable:new()
    self.paramter = {}
    self.instance = setmetatable({ is_setup = false }, self)
  end
  return self.instance
end

---@param data ModelTableInfo
function Model:setup(data)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  self.paramter = _.Parameters:new(data.paramter)
  local sql_info = {
    uri = data.uri,
  }
  self.tbl:setup(sql_info)
end

---@return ModelTableInfo
function Model:getAllInfo()
  return {
    uri = self.tbl.uri,
    sql_table = self.tbl:dump(),
  }
end

--function Model:release()
--  self.instance.is_setup = false
--  self.instance = nil
--  self.tbl = nil
--end

---@param content string
function Model:addNewCard(content)
  local card_info = _.Card:new()
  local file_type = vim.bo.filetype
  if not file_type or file_type == "" then
    file_type = "markdown"
  end

  self.tbl:insertCard(content, card_info:dumpStr(), card_info.due, file_type)
end

---@param id number
---@param row table
function Model:editCard(id, row)
  self.tbl:editCard(id, row)
end

---@return nil | CardField[]
function Model:findAll()
  return self.tbl:findCard()
end

---@param limit_num? number
---@return CardItem[]|nil
function Model:getMinDueItem(limit_num)
  local item = self.tbl:minCard("due", "info NOT LIKE '%reps=0%'", limit_num)
  return self:convertFsrsTableField2CardItem(item)
end

---@param limit_num number
---@return CardItem[]|nil
function Model:getNewItem(limit_num)
  local item = self.tbl:findCard(limit_num, "info LIKE '%reps=0%'")
  return self:convertFsrsTableField2CardItem(item)
end

---@param id number
---@return CardField
function Model:findById(id)
  local ret = self.tbl:findCard(1, "id=" .. id)
  if ret ~= nil then
    return ret[1]
  else
    error("findById not exist id:" .. id)
  end
end

---@param content string
---@param lim? number
---@return CardItem[]|nil
function Model:fuzzyFind(content, lim)
  lim = lim or 10
  local item = nil
  if content ~= "" then
    item = self.tbl:findCard(lim, "content like '%" .. content .. "%'")
  else
    item = self.tbl:findCard(lim)
  end
  return self:convertFsrsTableField2CardItem(item)
end

---@param item CardField[] | nil
---@return CardItem[]|nil
function Model:convertFsrsTableField2CardItem(item)
  if item ~= nil then
    local arr = {}
    for _, v in ipairs(item) do
      table.insert(arr, {
        id = v.id,
        content = v.content,
        due = v.due,
        file_type = v.file_type,
        card = self:convertRealCard(v),
      })
    end
    return arr
  else
    return nil
  end
end

---@param id number
function Model:delCard(id)
  self.tbl:delCard(id)
end

---@return Parameters
function Model:getParameter()
  return self.paramter
end

---@return FSRS
function Model:getFsrs()
  return _FSRS_.fsrs:new(self:getParameter())
end

--function Model:clear()
--return self.tbl:clear()
--end

---@param sql_card CardField
---@return Card
function Model:convertRealCard(sql_card)
  local data = tools.parse(sql_card.info)
  --print(vim.inspect(data))
  return _.Card:new(data)
end

---@param id number
---@param rating RatingType
---@param now_time? Timestamp
function Model:ratingCard(id, rating, now_time)
  local fsrs = self:getFsrs()
  local sql_card = self:findById(id)
  now_time = now_time or os.time()
  local new_card = fsrs:repeats(self:convertRealCard(sql_card), now_time)[rating].card
  sql_card.due = new_card.due
  sql_card.info = new_card:dumpStr()
  self:editCard(id, sql_card)
end

return Model:getInstance()
