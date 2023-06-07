local SqlTable = require("evidence.model.table")
local _FSRS_ = require("evidence.model.fsrs")
local _ = _FSRS_.model
local tools = require("evidence.util.tools")
local set = require("evidence.util.set")
local queue = require("evidence.util.queue")

---@class CardItem
---@field id number
---@field content string
---@field due Timestamp
---@field card Card
---@field file_type string "markdown" | "org"
--
---@class ModelTableParam
---@field uri string
---@field parameter Parameters

---@class Model
---@field tbl SqlTable
---@field is_setup boolean
---@field parameter Parameters
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
    self.instance = setmetatable({ is_setup = false, parameter = {} }, self)
  end
  return self.instance
end

---@param data ModelTableParam
function Model:setup(data)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  self.parameter = _.Parameters:new(data.parameter)
  local sql_info = {
    uri = data.uri,
  }
  self.tbl:setup(sql_info)
end

---@class ModelTableInfo
---@field sql_table table
---@field parameter Parameters

---@return ModelTableInfo
function Model:getAllInfo()
  return {
    parameter = self.parameter,
    sql_table = self.tbl:dump(),
  }
end

--function Model:release()
--  self.instance.is_setup = false
--  self.instance = nil
--  self.tbl = nil
--end

---@param content string
---@return number id
function Model:addNewCard(content)
  local card_info = _.Card:new()
  local file_type = vim.bo.filetype
  if not file_type or file_type == "" then
    file_type = "markdown"
  end

  return self.tbl:insertCard(content, card_info:dumpStr(), card_info.due, file_type)
end

---@param id number
---@param row table
function Model:editCard(id, row)
  self.tbl:editCard(id, row)
end

---@param id number
---@param row table
function Model:editTag(id, row)
  self.tbl:editTag(id, row)
end

---@return nil | CardField[]
function Model:findAllCards()
  return self.tbl:findCard()
end

---@param tag_ids number[]
---@param is_and boolean
---@param contain_son boolean
---@param limit_num? number
---@return CardItem[]|nil
function Model:getMinDueItem(tag_ids, is_and, contain_son, limit_num)
  if contain_son == true and is_and == false then
    tag_ids = self:findAllSonTags(tag_ids)
  end
  local item = self.tbl:minCardWithTags(tag_ids, is_and, "due", "info NOT LIKE '%reps=0%'", limit_num)
  return self:cardFields2CardItems(item)
end

---@param id number
---@return CardItem
function Model:getItemById(id)
  local item = self:findCardById(id)
  return self:cardField2CardItem(item)
end

---@param tag_ids number[]
---@param is_and boolean
---@param contain_son boolean
---@param limit_num number
---@return CardItem[]|nil
function Model:getNewItem(tag_ids, is_and, contain_son, limit_num)
  if contain_son == true and is_and == false then
    tag_ids = self:findAllSonTags(tag_ids)
  end
  local item = self.tbl:findCardWithTags(tag_ids, is_and, limit_num, "info LIKE '%reps=0%'")
  return self:cardFields2CardItems(item)
end

---@param id number
---@return CardField
function Model:findCardById(id)
  local ret = self.tbl:findCard(1, "id=" .. id)
  if ret ~= nil then
    return ret[1]
  else
    error("findCardById not exist id:" .. id)
  end
end

---@param name string
---@param lim? number
---@return CardItem[]|nil
function Model:fuzzyFindTag(name, lim)
  lim = lim or 10
  local item = nil
  if name ~= "" then
    item = self.tbl:findTag(lim, "name like '%" .. name .. "%'")
  else
    item = self.tbl:findTag(lim)
  end
  return item
end

---@param content string
---@param lim? number
---@return CardItem[]|nil
function Model:fuzzyFindCard(content, lim)
  lim = lim or 10
  local item = nil
  if content ~= "" then
    item = self.tbl:findCard(lim, "content like '%" .. content .. "%'")
  else
    item = self.tbl:findCard(lim)
  end
  return self:cardFields2CardItems(item)
end

---@param item CardField
---@return CardItem
function Model:cardField2CardItem(item)
  return {
    id = item.id,
    content = item.content,
    due = item.due,
    file_type = item.file_type,
    card = self:convertRealCard(item),
  }
end

---@param item CardField[] | nil
---@return CardItem[]|nil
function Model:cardFields2CardItems(item)
  if type(item) == "table" then
    local arr = {}
    for _, v in ipairs(item) do
      table.insert(arr, self:cardField2CardItem(v))
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
  return self.parameter
end

---@return FSRS
function Model:getFsrs()
  return _FSRS_.fsrs:new(self:getParameter())
end

function Model:clear()
  return self.tbl:clear()
end

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
  local sql_card = self:findCardById(id)
  now_time = now_time or os.time()
  local new_card = fsrs:repeats(self:convertRealCard(sql_card), now_time)[rating].card
  sql_card.due = new_card.due
  sql_card.info = new_card:dumpStr()
  self:editCard(id, sql_card)
end

function Model:findAllTags()
  return self.tbl:findTag()
end

---@param name string
---@param father_id? number
---@return number id
function Model:addTag(name, father_id)
  father_id = father_id or -1
  return self.tbl:insertTag(name, father_id)
end

---@param tag_id number
---@return TagField[]
function Model:findFatherTags(tag_id)
  local now_tag_id = tag_id
  --print("findFatherTags")
  local tags = {}
  while tag_id ~= -1 do
    local tag_item = self:findTagById(tag_id)
    if tag_item == nil then
      error("findFatherTags")
    end
    if tag_item.id ~= now_tag_id then
      table.insert(tags, tag_item)
    end
    tag_id = tag_item.father_id
  end
  return tags
end

---@param card_id number
---@return table set
function Model:findFatherTagsInCard(card_id)
  local res = {}
  local tags = self:findIncludeTagsByCard(card_id)
  if tags ~= nil then
    for _, tag in ipairs(tags) do
      local fathers = self:findFatherTags(tag.id)
      for __, father in ipairs(fathers) do
        set.add(res, father.id)
      end
    end
  end
  return res
end

---@param tag_id number
---@return nil | TagField[]
function Model:findSonTags(tag_id)
  return self.tbl:findTag(-1, "father_id=" .. tag_id)
end

---@param tag_ids number[]
---@return nil | TagField[]
function Model:findTagByIds(tag_ids)
  local tag_str = ""
  local cnt = #tag_ids
  for key, val in pairs(tag_ids) do
    if tag_str ~= "" then
      tag_str = tag_str .. ","
    end
    tag_str = tag_str .. val
  end
  return self.tbl:findTag(-1, "id in (" .. tag_str .. ")")
end

---@param tag_id number
---@return nil | TagField
function Model:findTagById(tag_id)
  local res = self.tbl:findTag(1, "id=" .. tag_id)
  if res ~= nil then
    return res[1]
  else
    return nil
  end
end

---@param son_ids number[]
---@param father_id number
function Model:convertFatherTag(son_ids, father_id)
  for _, son_id in ipairs(son_ids) do
    if son_id ~= father_id then
      self.tbl:editTag(son_id, { father_id = father_id })
    else
      error("convertFatherTag")
    end
  end
end

---@return number[]
function Model:getIdsFromItem(items)
  local res = {}
  if type(items) == "table" then
    for _, item in pairs(items) do
      table.insert(res, item.id)
    end
  end
  return res
end

---@param old_tag_ids number[] tag would_be_delete
---@param new_tag_id number
function Model:mergeTags(old_tag_ids, new_tag_id)
  for _, old_tag_id in ipairs(old_tag_ids) do
    local son_tags = self:findSonTags(old_tag_id)
    --print(vim.inspect(son_tags))
    if son_tags ~= nil then
      --print(vim.inspect(son_tags))
      local son_tag_ids = self:getIdsFromItem(son_tags)
      self:convertFatherTag(son_tag_ids, new_tag_id)
    end
  end
  self.tbl:mergeTags(old_tag_ids, new_tag_id)
end

---@param card_id number
---@param tag_id number
---@return boolean
function Model:checkValidCardTagById(card_id, tag_id)
  --print("checkValidCardTagById")
  local res = self:findFatherTagsInCard(card_id)
  local now_tags = self:findIncludeTagsByCard(card_id)
  local new_fathers = self:findFatherTags(tag_id)
  if now_tags == nil then
    return true
  end
  --print(vim.inspect(now_tags))
  --print(vim.inspect(new_fathers))
  --print(vim.inspect(res))
  for _, new_father in ipairs(new_fathers) do
    for __, now_tag in ipairs(now_tags) do
      if new_father.id == now_tag.id then
        return false
      end
    end
  end
  return not set.contains(res, tag_id)
end

---@param card_id number
---@param tag_id number
function Model:insertCardTagById(card_id, tag_id)
  if not self:checkValidCardTagById(card_id, tag_id) then
    print("insertCardTagById error")
    return
  end
  self.tbl:insertCardTag(card_id, tag_id)
end

---@param card_id number
---@param tag_name string
function Model:insertCardTagByName(card_id, tag_name)
  local tag_item = self:fuzzyFindTag(tag_name, 1)
  if type(tag_item) ~= "table" then
    if not tools.confirmCheck("create new tag name:" .. tag_name) then
      return
    end
    self:addTag(tag_name)
    tag_item = self:fuzzyFindTag(tag_name, 1)
  end
  if tag_item == nil then
    error("failed insertCardTagByName card_id:" .. card_id .. " tag_name:" .. tag_name)
    return
  end
  tag_item = tag_item[1]
  local tag_id = tag_item.id
  if not self:checkValidCardTagById(card_id, tag_id) then
    print("insertCardTagByName error")
    return
  end
  self.tbl:insertCardTag(card_id, tag_id)
end

---@param card_id number
---@return nil | TagField[]
function Model:findExcludeTagsByCard(card_id)
  local tags = self.tbl:findTagsByCard(card_id, true)
  local tag_ids = self:getIdsFromItem(tags)
  --print(vim.inspect(tag_ids))
  local son_exclude_ids = self:findAllSonTags(tag_ids, true)
  --print(vim.inspect(son_exclude_ids))
  local exclude_ids = {}
  local father_set = self:findFatherTagsInCard(card_id)
  for _, id in ipairs(son_exclude_ids) do
    if not set.contains(father_set, id) then
      table.insert(exclude_ids, id)
    end
  end
  return self:findTagByIds(exclude_ids)
end

---@param card_id number
---@return nil | TagField[]
function Model:findIncludeTagsByCard(card_id)
  return self.tbl:findTagsByCard(card_id, true)
end

---@param card_id number
---@param tag_id number
function Model:delCardTag(card_id, tag_id)
  return self.tbl:delCardTag(card_id, tag_id)
end

---@param tag_id number
function Model:delTag(tag_id)
  local now_tag = self:findTagById(tag_id)
  if now_tag == nil then
    error("delTag")
  end
  self:mergeTags({ tag_id }, now_tag.father_id)
end

---@param tag_ids number[]
---@param is_exclude? boolean
---@return number[]
function Model:findAllSonTags(tag_ids, is_exclude)
  if is_exclude == nil then
    is_exclude = false
  end
  local tag_set = set.createSetFromArray(tag_ids)
  local res = {}
  local q = {}
  local now_tag_id = -1
  queue.push(q, now_tag_id)
  while not queue.isEmpty(q) do
    now_tag_id = queue.front(q)
    --print(">>> id:" .. now_tag_id)
    queue.pop(q)
    local son_tags = self:findSonTags(now_tag_id)
    if son_tags ~= nil then
      for _, son_tag in ipairs(son_tags) do
        queue.push(q, son_tag.id)
        local is_need = set.contains(tag_set, son_tag.id) or set.contains(tag_set, son_tag.father_id)
        --print("is_need:" .. tostring(is_need))
        if is_need then
          set.add(tag_set, son_tag.id)
        end
        if is_exclude then
          is_need = not is_need
        end
        if is_need then
          set.add(res, son_tag.id)
        end
      end
    end
  end
  return set.toArray(res)
end

---@param tag_ids number[]
---@param is_and boolean
---@param contain_son boolean
---@param lim? number
---@return nil | CardField[]
function Model:findCardBySelectTags(tag_ids, is_and, contain_son, lim)
  if contain_son == true and is_and == false then
    tag_ids = self:findAllSonTags(tag_ids)
  end
  lim = lim or 10
  if tools.isTableEmpty(tag_ids) then
    return self:fuzzyFindCard("", lim)
  end
  return self.tbl:findCardsByTags(tag_ids, lim, is_and)
end

return Model:getInstance()
