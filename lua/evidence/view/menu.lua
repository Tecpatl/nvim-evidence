local model = require("evidence.model.index")
local tools = require("evidence.util.tools")
local winBuf = require("evidence.view.win_buf")
local telescopeMenu = require("evidence.view.telescope")
local menuHelper = require("evidence.view.menu_helper")
local set = require("evidence.util.set")

--- @alias NextCardMode integer
local NextCardMode = {
  auto = 0,
  review = 1,
  new = 2,
}

---@type ModelTableParam
local user_data = nil
local is_start_ = false
---@type number[]
local select_tags = {}
local is_select_tag_and = true
local next_card_mode = NextCardMode.auto

local function selectTagNameStr()
  local res = ""
  if select_tags ~= {} then
    local status_msg = "AND"
    if is_select_tag_and == false then
      status_msg = "OR"
    end
    local tags = model:findTagByIds(select_tags)
    if tags ~= nil then
      res = status_msg .. " current:" .. tools.array2Str(tags, "name")
    end
  end
  return res
end

local function nextCard()
  local item = nil
  if next_card_mode == NextCardMode.auto then
    item = menuHelper:calcNextList(select_tags, is_select_tag_and)
  elseif next_card_mode == NextCardMode.review then
    item = model:getMinDueItem(select_tags, is_select_tag_and, true, 1)
  elseif next_card_mode == NextCardMode.new then
    item = model:getNewItem(select_tags, is_select_tag_and, true, 1)
  end

  if item == nil then
    print("empty table")
    return
  end
  winBuf:viewContent(item[1])
end

local function setNextCard()
  local items = {}
  for k, v in pairs(NextCardMode) do
    table.insert(items, {
      name = k,
      foo = function()
        next_card_mode = v
      end,
    })
  end
  return {
    prompt_title = "Evidence setNextCard",
    menu_item = items,
    main_foo = nil,
  }
end

---@return boolean
local function checkStartInSelfBuf()
  local start_buf = vim.api.nvim_get_current_buf()
  if is_start_ == false or not winBuf:checkSelfBuf(start_buf) then
    print("evidence need in self buf. call flush first if buf is closed")
    return false
  end
  return true
end

---@param data ModelTableParam
local function setup(data)
  if is_start_ == true then
    return
  end
  user_data = data
  is_start_ = true
  is_select_tag_and = true
  select_tags = {}
  model:setup(data)
  winBuf:setup({}, "## answer")
  menuHelper:setup(model)
end

---@return CardItem
local function getNowItem()
  return winBuf:getInfo().item
end

---@return MenuData
local function fuzzyFindCard()
  local foo = function(prompt)
    return model:fuzzyFindCard(prompt, 50)
  end
  return {
    prompt_title = "Evidence FuzzyFindCard",
    menu_item = {},
    main_foo = nil,
    previewer = menuHelper:createCardPreviewer(),
    process_work = menuHelper:createCardProcessWork(foo),
  }
end

local function addCard()
  if not tools.confirmCheck("addCard") then
    return
  end
  local buf_id = winBuf:getInfo().buf
  local content = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  local content_str = table.concat(content, "\n")
  local file_type = vim.api.nvim_buf_get_option(buf_id, "filetype")
  if not file_type or file_type == "" then
    file_type = "markdown"
  end
  local card_id = model:addNewCard(content_str, file_type)
  local item = model:getItemById(card_id)
  winBuf:viewContent(item)
end

local function delCard()
  if not tools.confirmCheck("delCard") then
    return
  end
  model:delCard(getNowItem().id)
  nextCard()
end

local function answer()
  winBuf:switchFold(false)
end

local function editCard()
  if not tools.confirmCheck("editCard") then
    return
  end
  local buf_id = winBuf:getInfo().buf
  local content = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  local content_str = table.concat(content, "\n")
  local file_type = vim.api.nvim_buf_get_option(buf_id, "filetype")
  if not file_type or file_type == "" then
    file_type = "markdown"
  end
  model:editCard(getNowItem().id, { content = content_str, file_type = file_type })
end

local function infoCard()
  local card = getNowItem().card
  tools.printDump(card)
end

local function scoreCard()
  local rating = tonumber(tools.uiInput("scoreCard(0,1,2,3):", ""))
  if type(rating) ~= "number" or not menuHelper:checkScore(rating) then
    print("input format error (0,1,2,3)")
    return
  end
  --print(rating)
  model:ratingCard(getNowItem().id, rating)
  nextCard()
end

---@return MenuData
local function addTag()
  local res = model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        foo = function()
          print("please add a tag not exist")
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence addTag",
    menu_item = items,
    main_foo = function(value)
      local typename = type(value)
      if typename == "string" then
        if not tools.confirmCheck("addTag") then
          return
        end
        model:addTag(value)
      else
        print("please add a tag not exist")
      end
    end,
  }
end

---@return MenuData
local function addTagsForNowCard()
  local card_id = getNowItem().id
  local res = model:findExcludeTagsByCard(card_id)
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = { id = v.id },
        foo = function()
          if not tools.confirmCheck("addTagsForNowCard") then
            return
          end
          model:insertCardTagById(card_id, v.id)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence addTagsForNowCard",
    menu_item = items,
    main_foo = function(value)
      print("cannot multiple add tags for direct relations")
      --local typename = type(value)
      --if typename == "table" then
      --  for _, v in ipairs(value) do
      --    model:insertCardTagById(card_id, v.info.id)
      --  end
      --elseif typename == "string" then
      --  model:insertCardTagByName(card_id, value)
      --end
    end,
  }
end

---@return MenuData
local function fuzzyFindTag()
  local res = model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, { name = v.name, foo = nil })
    end
  end
  return {
    prompt_title = "Evidence fuzzyFindTag",
    menu_item = items,
    main_foo = nil,
  }
end

---@return MenuData
local function findTagsByNowCard()
  local card_id = getNowItem().id
  local res = model:findIncludeTagsByCard(card_id)
  local items = {}
  if res ~= nil then
    for _, v in ipairs(res) do
      table.insert(items, { name = v.name, foo = nil })
    end
  end
  return {
    prompt_title = "Evidence findTagsByNowCard",
    menu_item = items,
    main_foo = nil,
  }
end

---@return MenuData
local function delTagsForNowCard()
  local card_id = getNowItem().id
  local res = model:findIncludeTagsByCard(card_id)
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = { id = v.id },
        foo = function()
          if not tools.confirmCheck("delTagsForNowCard") then
            return
          end
          model:delCardTag(card_id, v.id)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence delTagsForNowCard",
    menu_item = items,
    main_foo = function(value)
      local typename = type(value)
      if typename == "table" then
        for _, v in ipairs(value) do
          model:delCardTag(card_id, v.info.id)
        end
      end
    end,
  }
end

---@param del_tag number[] | number
local function updateSelectTags(del_tag)
  local s = set.createSetFromArray(select_tags)
  local typename = type(del_tag)
  if typename == "table" then
    for _, id in ipairs(del_tag) do
      set.remove(s, id)
    end
  elseif typename == "number" then
    set.remove(s, del_tag)
  end
  select_tags = set.toArray(s)
end

---@return MenuData
local function delTags()
  local res = model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = { id = v.id },
        foo = function()
          if not tools.confirmCheck("delTags") then
            return
          end
          model:delTag(v.id)
          updateSelectTags(v.id)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence delTags",
    menu_item = items,
    main_foo = function(value)
      print("cannot multiple del tags for direct relations")
      --local typename = type(value)
      --if typename == "table" then
      --  for _, v in ipairs(value) do
      --    model:delTag(v.info.id)
      --    updateSelectTags(v.id)
      --  end
      --end
    end,
  }
end

---@return MenuData
local function renameTag()
  local res = model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = { id = v.id },
        foo = function()
          local new_name = tools.uiInput("renameTag old_name:" .. v.name .. " new_name:", "")
          if new_name ~= nil then
            model:editTag(v.id, { name = new_name })
          end
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence renameTag",
    menu_item = items,
    main_foo = nil,
  }
end

---@pararm  is_and boolean
---@return MenuData
local function setSelectTags(is_and)
  is_select_tag_and = is_and
  local status_msg = "AND"
  if is_select_tag_and == false then
    status_msg = "OR"
  end
  local res = model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = { id = v.id },
        foo = function()
          select_tags = {}
          table.insert(select_tags, v.id)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence setSelectTags " .. selectTagNameStr(),
    menu_item = items,
    main_foo = function(value)
      local typename = type(value)
      if typename == "table" then
        select_tags = {}
        for _, v in ipairs(value) do
          table.insert(select_tags, v.info.id)
        end
      end
    end,
  }
end

---@return MenuData
local function findCardBySelectTags()
  local status_msg = "AND"
  if is_select_tag_and == false then
    status_msg = "OR"
  end
  local foo = function()
    return model:findCardBySelectTags(select_tags, is_select_tag_and, true, 50)
  end
  return {
    prompt_title = "Evidence findCardBySelectTags " .. selectTagNameStr(),
    menu_item = {},
    main_foo = nil,
    previewer = menuHelper:createCardPreviewer(),
    process_work = menuHelper:createCardProcessWork(foo),
  }
end

---@return MenuData
local function findReviewCard()
  local status_msg = "AND"
  if is_select_tag_and == false then
    status_msg = "OR"
  end
  local foo = function()
    return model:getMinDueItem(select_tags, is_select_tag_and, true, 50)
  end
  return {
    prompt_title = "Evidence findReviewCard " .. selectTagNameStr(),
    menu_item = {},
    main_foo = nil,
    previewer = menuHelper:createCardPreviewer(),
    process_work = menuHelper:createCardProcessWork(foo),
  }
end

---@return MenuData
local function findNewCard()
  local status_msg = "AND"
  if is_select_tag_and == false then
    status_msg = "OR"
  end
  local foo = function()
    return model:getNewItem(select_tags, is_select_tag_and, true, 50)
  end
  return {
    prompt_title = "Evidence findNewCard " .. selectTagNameStr(),
    menu_item = {},
    main_foo = nil,
    previewer = menuHelper:createCardPreviewer(),
    process_work = menuHelper:createCardProcessWork(foo),
  }
end

---@param now_tag_id number
---@return MenuData|nil
local function tagTree(now_tag_id)
  local son_tags = model:findSonTags(now_tag_id)
  local items = {}
  if now_tag_id ~= -1 then
    local now_tag = model:findTagById(now_tag_id)
    if now_tag == nil then
      error("tagTree findTagById")
    end
    table.insert(items, {
      name = "[father] " .. now_tag.name,
      info = { id = now_tag.id },
      foo = function()
        return tagTree(now_tag.father_id)
      end,
    })
  end
  --print(vim.inspect(son_tags))
  if type(son_tags) == "table" then
    for _, v in ipairs(son_tags) do
      table.insert(items, {
        name = v.name,
        info = { id = v.id },
        foo = function()
          return tagTree(v.id)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence tagTree",
    menu_item = items,
    main_foo = nil,
  }
end

---@pararm tag_ids number[]
---@return MenuData
local function convertTagFatherEnd(tag_ids)
  local exclude_son_ids = model:findAllSonTags(tag_ids, true) -- exclude tags
  local res = model:findTagByIds(exclude_son_ids)
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        foo = function()
          if not tools.confirmCheck("convertTagFatherEnd") then
            return
          end
          model:convertFatherTag(tag_ids, v.id)
          updateSelectTags(tag_ids)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence convertTagFather select father tag",
    menu_item = items,
    main_foo = nil,
  }
end

---@return MenuData
local function convertTagFatherStart()
  local res = model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = {
          id = v.id,
        },
        foo = function()
          return convertTagFatherEnd({ v.id })
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence convertTagFather select son tags",
    menu_item = items,
    main_foo = function(value)
      print("cannot multiple convertTagFather for direct relations")
      --local typename = type(value)
      --if typename == "table" then
      --  local ids = {}
      --  for _, v in ipairs(value) do
      --    table.insert(ids, v.info.id)
      --  end
      --  return convertTagFatherEnd(ids)
      --end
    end,
  }
end

---@pararm tag_ids number[]
---@return MenuData
local function mergeTagEnd(tag_ids)
  local exclude_son_ids = model:findAllSonTags(tag_ids, true) -- exclude tags
  local res = model:findTagByIds(exclude_son_ids)
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        foo = function()
          if not tools.confirmCheck("mergeTagEnd") then
            return
          end
          model:mergeTags(tag_ids, v.id)
          updateSelectTags(tag_ids)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence mergeTagEnd select new tag",
    menu_item = items,
    main_foo = nil,
  }
end

---@return MenuData
local function mergeTagStart()
  local res = model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = {
          id = v.id,
        },
        foo = function()
          return mergeTagEnd({ v.id })
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence mergeTagStart select old tags",
    menu_item = items,
    main_foo = function(value)
      print("cannot multiple mergeTagStart for direct relations")
      --local typename = type(value)
      --if typename == "table" then
      --  local ids = {}
      --  for _, v in ipairs(value) do
      --    table.insert(ids, v.info.id)
      --  end
      --  return mergeTagEnd(ids)
      --end
    end,
  }
end

---@type SimpleMenu[]
local menuItem = {
  {
    name = "addCard",
    foo = addCard,
  },
  {
    name = "nextCard",
    foo = nextCard,
  },
  {
    name = "delCard",
    foo = delCard,
  },
  {
    name = "answer",
    foo = answer,
  },
  {
    name = "editCard",
    foo = editCard,
  },
  {
    name = "infoCard",
    foo = infoCard,
  },
  {
    name = "scoreCard",
    foo = scoreCard,
  },
  {
    name = "findTag",
    foo = fuzzyFindTag,
  },
  {
    name = "findCard",
    foo = fuzzyFindCard,
  },
  {
    name = "findTagsByNowCard",
    foo = findTagsByNowCard,
  },
  {
    name = "addTagsForNowCard",
    foo = addTagsForNowCard,
  },
  {
    name = "delTagsForNowCard",
    foo = delTagsForNowCard,
  },
  {
    name = "addTag",
    foo = addTag,
  },
  {
    name = "renameTag",
    foo = renameTag,
  },
  {
    name = "delTags",
    foo = delTags,
  },
  {
    name = "setSelectTagsAnd",
    foo = function()
      return setSelectTags(true)
    end,
  },
  {
    name = "setSelectTagsOr",
    foo = function()
      return setSelectTags(false)
    end,
  },
  {
    name = "findCardBySelectTags",
    foo = findCardBySelectTags,
  },
  {
    name = "findReviewCard",
    foo = findReviewCard,
  },
  {
    name = "findNewCard",
    foo = findNewCard,
  },
  {
    name = "setNextCard",
    foo = setNextCard,
  },
  {
    name = "tagTree",
    foo = function()
      return tagTree(-1)
    end,
  },
  {
    name = "convertTagFather",
    foo = convertTagFatherStart,
  },
  {
    name = "mergeTag",
    foo = mergeTagStart,
  },
}

local function cmd()
  if not checkStartInSelfBuf() then
    return
  end
  telescopeMenu.setup({
    prompt_title = "Evidence MainMenu " .. selectTagNameStr(),
    menu_item = menuItem,
    main_foo = nil,
  })
end

---@param data ModelTableParam
local function flush(data)
  setup(data)
  winBuf:openSplitWin()
  nextCard()
end

return {
  cmd = cmd,
  flush = flush,
}
