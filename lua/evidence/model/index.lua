local SqlTable = require("evidence.model.table")
local tblInfo = require("evidence.model.info")
local _FSRS_ = require("evidence.model.fsrs")
local _ = _FSRS_.model
local tools = require("evidence.util.tools")
local set = require("evidence.util.set")
local queue = require("evidence.util.queue")

---@alias CardItem CardField

---@alias RecordCardItem RecordCardField

-----@class RecordCardItem
-----@field id number
-----@field card_id number
-----@field content string
-----@field file_type string "markdown" | "org"
-----@field timestamp Timestamp
-----@field access_way AccessWayType

---@class ModelTableParam
---@field uri string
---@field is_record boolean
---@field parameter Parameters
---@field pdf PdfField

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
    is_record = data.is_record,
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
---@param file_type? string
---@return number id
function Model:addNewCard(content, file_type)
  local card_info = _.Card:new()
  file_type = file_type or "markdown"

  content = tools.remove_invalid_utf8(content)

  local card_id = self.tbl:insertCard(content, file_type)
  local info = card_info:dumpStr()
  local due = card_info.due
  self.tbl:insertFsrs(card_id, info, due, { 0 })
  return card_id
end

---@param id number
---@param row table
function Model:editCard(id, row)
  self.tbl:editCard(id, row)
end

---@param query string
function Model:execute(query)
  self.tbl:execute(query)
end

---@param id number
---@param row table
function Model:editTag(id, row)
  self.tbl:editTag(id, row)
end

---@return nil | CardItem[]
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
  if limit_num == nil then
    limit_num = -1
  end
  local item = self.tbl:minDueCardWithTags(tag_ids, is_and, limit_num)
  --return self:cardFields2CardItems(item)
  return item
end

---@param id number
---@return CardItem
function Model:getItemById(id)
  local item = self:findCardById(id)
  return item
  --return self:cardField2CardItem(item)
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
  local item = self.tbl:findCardWithTags(
    tag_ids,
    is_and,
    limit_num,
    "c.id in (select c2.id from card as c2 join fsrs on fsrs.card_id=c2.id where fsrs.info like '%reps=0%')",
    true
  )
  return item
end

---@param tag_ids number[]
---@param is_and boolean
---@param contain_son boolean
---@return CardItem[]|nil
function Model:getRandomItem(tag_ids, is_and, contain_son, limit_num)
  if contain_son == true and is_and == false then
    tag_ids = self:findAllSonTags(tag_ids)
  end
  local item = self.tbl:findCardWithTags(tag_ids, is_and, limit_num, "", true)
  return item
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
  return item
  --return self:cardFields2CardItems(item)
end

-----@param item CardField
-----@return CardItem
--function Model:cardField2CardItem(item)
--  return {
--    id = item.id,
--    content = item.content,
--    file_type = item.file_type,
--    is_active = true,
--  }
--  --return tools.merge(item, {
--  --  card = self:convertRealCard(item),
--  --})
--end

-----@param item RecordCardField
-----@return CardItem
--function Model:recordCardField2CardItem(item)
--  item.id = item.card_id
--  item.card_id = nil
--  item.timestamp = nil
--  item.access_way = nil
--  return {
--    id = item.card_id,
--    content = item.content,
--    file_type = item.file_type,
--    is_active = item.is_active,
--  }
--  --return tools.merge(item, {
--  --  card = self:convertRealCard(item),
--  --})
--end

--
-----@param item RecordCardField
-----@return RecordCardItem
--function Model:recordCardField2RecordCardItem(item)
--  return tools.merge(item, {
--    card = self:convertRealCard(item),
--  })
--end

-----@param item CardField | nil
-----@return CardItem[] | nil
--function Model:cardFields2CardItems(item)
--  if type(item) == "table" then
--    local arr = {}
--    for _, v in ipairs(item) do
--      table.insert(arr, self:cardField2CardItem(v))
--    end
--    return arr
--  else
--    return nil
--  end
--end

--
-----@param item RecordCardField[] | nil
-----@return CardItem[] | nil
--function Model:recordCardFields2CardItems(item)
--  if type(item) == "table" then
--    local arr = {}
--    for _, v in ipairs(item) do
--      table.insert(arr, self:recordCardField2CardItem(v))
--    end
--    return arr
--  else
--    return nil
--  end
--end

--
-----@param item RecordCardField[] | nil
-----@return RecordCardItem[]|nil
--function Model:recordCardFields2RecordCardItems(item)
--  if type(item) == "table" then
--    local arr = {}
--    for _, v in ipairs(item) do
--      table.insert(arr, self:recordCardField2RecordCardItem(v))
--    end
--    return arr
--  else
--    return nil
--  end
--end

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

-----@param sql_card CardField | RecordCardField
-----@return Card
--function Model:convertRealCard(sql_card)
--  local data = tools.parse(sql_card.info)
--  --print(vim.inspect(data))
--  return _.Card:new(data)
--end
--

---@param card_id number
---@return FsrsField
function Model:findDefaultFsrsByCard(card_id)
  local fsrs_item = self.tbl:findDefaultFsrsByCard(card_id)
  if fsrs_item == nil then
    error("findDefaultFsrsByCard empty")
  end
  return fsrs_item
end

---@param card_id number
---@return FsrsField
function Model:findMinDueFsrsByCard(card_id)
  local fsrs_items = self:findAllFsrsByCard(card_id)
  return fsrs_items[1]
end

---@param card_id number
---@return FsrsField[]
function Model:findAllFsrsByCard(card_id)
  local fsrs_items = self.tbl:findAllFsrsByCard(card_id)
  if fsrs_items == nil then
    error("findAllFsrsByCard fsrs_items empty")
  end
  return fsrs_items
end

---@param card_id number
---@param mark_id number
---@param next_interval  Timestamp
function Model:postponeFsrs(card_id, mark_id, next_interval)
  local fsrs_item = self.tbl:findFsrsByCardMark(card_id, mark_id)
  if fsrs_item == nil then
    print("postponeFsrs not exist")
    return
  end
  local fsrs = self:getFsrs()
  local data = tools.parse(fsrs_item.info)
  local card_info = _.Card:new(data)
  card_info.due = card_info.due + next_interval
  local info = card_info:dumpStr()
  local due = card_info.due
  self.tbl:editFsrs(card_id, mark_id, { info = info, due = due })
end

---@param card_id number
---@param mark_ids number[]
function Model:resetFsrsMarks(card_id, mark_ids)
  local fsrs_items = self:findAllFsrsByCard(card_id)
  self.tbl:delFsrs(card_id, mark_ids, true)
  local fsrs_item_ids = tools.getValArrayFromItem(fsrs_items, "mark_id")
  local fsrs_item_ids_set = set.createSetFromArray(fsrs_item_ids)
  local new_mark_ids = {}
  for key, id in pairs(mark_ids) do
    if not set.contains(fsrs_item_ids_set, id) then
      table.insert(new_mark_ids, id)
    end
  end
  local card_info = _.Card:new()
  local info = card_info:dumpStr()
  local due = card_info.due
  self.tbl:insertFsrs(card_id, info, due, new_mark_ids)
end

---@param id number
---@param mark_id number
---@param rating RatingType
---@param now_time? Timestamp
function Model:ratingCard(id, mark_id, rating, now_time)
  local fsrs_item = self.tbl:findFsrsByCardMark(id, mark_id)
  if fsrs_item == nil then
    error("ratingCard mark not exist")
  end
  local fsrs = self:getFsrs()
  now_time = now_time or os.time()
  local data = tools.parse(fsrs_item.info)
  local new_card = fsrs:repeats(_.Card:new(data), now_time)[rating].card
  local due = new_card.due
  local info = new_card:dumpStr()
  self.tbl:editFsrs(id, mark_id, { due = due, info = info })
  self:insertRecordCard(id, tblInfo.AccessWay.score)
end

---@return nil | TagField[]
function Model:findAllTags()
  return self.tbl:findTag()
end

function Model:alterFsrsInfo()
  return self.tbl:alterFsrsInfo()
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

---@param son_ids number[] indirect relations
---@param father_id number
function Model:convertFatherTag(son_ids, father_id)
  for _, son_id in ipairs(son_ids) do
    if son_id ~= father_id then
      -- 同时包含两个tag_id的卡片只留son_tag_id这一个
      local cards = self:findCardBySelectTags({ son_id, father_id }, true, false, -1)
      if cards ~= nil then
        for _, card in ipairs(cards) do
          self:delCardTag(card.id, father_id)
        end
      end
      self.tbl:editTag(son_id, { father_id = father_id })
    else
      error("convertFatherTag same")
    end
  end
end

---@param items table|nil
---@return number[]
function Model:getIdsFromItem(items)
  return tools.getValArrayFromItem(items, "id")
end

---@param old_tag_ids number[] indirect relations and tag would_be_delete
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
---@return boolean
function Model:insertCardTagById(card_id, tag_id)
  if not self:checkValidCardTagById(card_id, tag_id) then
    print("insertCardTagById error")
    return false
  end
  self.tbl:insertCardTag(card_id, tag_id)
  return true
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
---@param is_include_son? boolean
---@return nil | TagField[]
--例如: setTagsForNowCardList && add_mode
function Model:findIncludeTagsByCard(card_id, is_include_son)
  local tags = self.tbl:findTagsByCard(card_id, true)
  if tags == nil or is_include_son == nil or is_include_son == false then
    return tags
  end
  local tag_ids = self:getIdsFromItem(tags)
  local son_include_ids = self:findAllSonTags(tag_ids, false)
  return self:findTagByIds(son_include_ids)
end

---@param card_id number
---@param tag_id number
function Model:delCardTag(card_id, tag_id)
  return self.tbl:delCardTag(card_id, tag_id)
end

---@param card_id number
function Model:delCardAllTag(card_id)
  return self.tbl:delCardAllTag(card_id)
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
---@param content? string
---@return nil | RecordCardItem[]
function Model:findCardBySelectTags(tag_ids, is_and, contain_son, lim, content)
  if contain_son == true and is_and == false then
    tag_ids = self:findAllSonTags(tag_ids)
  end
  if content == nil then
    content = ""
  end
  lim = lim or 10
  if tools.isTableEmpty(tag_ids) then
    return self:fuzzyFindCard(content, lim)
  end
  local statement = nil
  if content ~= "" then
    statement = "c.content like '%" .. content .. "%'"
  end
  local item = self.tbl:findCardsByTags(tag_ids, lim, is_and, nil, statement)
  return item
  --return self:cardFields2CardItems(item)
end

---@param access_ways AccessWayType[]
---@return RecordCardItem[] | nil
function Model:findRecordCardRaw(access_ways)
  local items = self.tbl:findRecordCard(-1, access_ways)
  --return self:recordCardFields2RecordCardItems(items)
  return items
end

---@param content string
---@param access_ways AccessWayType[]
---@return RecordCardItem[] | nil
function Model:findRecordCard(content, access_ways)
  local statement = nil
  if content ~= "" then
    statement = "rc.content like '%" .. content .. "%'"
  end
  local items = self.tbl:findRecordCard(-1, access_ways, statement)
  return items
  --return self:recordCardFields2CardItems(items)
end

---@param id number
---@return CardItem
function Model:findCardById(id)
  return self.tbl:findCardById(id)
end

---@param id number
---@return boolean
function Model:checkCardExistById(id)
  return self.tbl:checkCardExistById(id)
end

---@param card_id number
---@param access_way AccessWayType
function Model:insertRecordCard(card_id, access_way)
  self.tbl:insertRecordCard(card_id, access_way)
end

return Model:getInstance()
