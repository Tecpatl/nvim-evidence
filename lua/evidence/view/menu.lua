local model = require("evidence.model.index")
local tools = require("evidence.util.tools")
local winBuf = require("evidence.view.win_buf")
local telescopeMenu = require("evidence.view.telescope")
local menuHelper = require("evidence.view.menu_helper")

---@type ModelTableParam
local user_data = nil
local is_start_ = false

local function nextCard()
  local item = menuHelper:calcNextList()

  if item == nil then
    print("empty table")
    return
  end
  winBuf:viewContent(item[1])
end

---@param data ModelTableParam
local function setup(data)
  if is_start_ == true then
    return
  end
  user_data = data
  is_start_ = true
  model:setup(data)
  winBuf:setup({}, "## answer")
  menuHelper:setup(model)
  winBuf:openSplitWin()
  nextCard()
end

---@return CardItem
local function getNowItem()
  return winBuf:getInfo().item
end

---@return MenuData
local function fuzzyFindCard()
  return {
    prompt_title = "Evidence FuzzyFindCard",
    menu_item = {},
    main_foo = nil,
    previewer = menuHelper:createCardPreviewer(),
    process_work = menuHelper:createCardProcessWork(),
  }
end

local function addCard()
  if not tools.confirmCheck("addCard") then
    return
  end
  local content = vim.api.nvim_buf_get_lines(winBuf:getInfo().buf, 0, -1, false)
  local content_str = table.concat(content, "\n")
  model:addNewCard(content_str)
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
  local content = vim.api.nvim_buf_get_lines(winBuf:getInfo().buf, 0, -1, false)
  local content_str = table.concat(content, "\n")
  local file_type = vim.bo.filetype
  if not file_type or file_type == "" then
    file_type = "markdown"
  end
  model:editCard(getNowItem().id, { content = content_str, file_type = file_type })
end

local function infoCard()
  tools.printDump(getNowItem().card)
end

local function scoreCard()
  local rating = tonumber(tools.uiInput("scoreCard(0,1,2,3):", ""))
  if type(rating) ~= "number" or not menuHelper:checkScore(rating) then
    print("input format error (0,1,2,3)")
    return
  end
  print(rating)
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
          model:insertCardTagById(card_id, v.id)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence addTagsForNowCard",
    menu_item = items,
    main_foo = function(value)
      local typename = type(value)
      if typename == "table" then
        for _, v in ipairs(value) do
          model:insertCardTagById(card_id, v.info.id)
        end
      elseif typename == "string" then
        model:insertCardTagByName(card_id, value)
      end
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
          model:delTag(v.id)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence delTags",
    menu_item = items,
    main_foo = function(value)
      local typename = type(value)
      if typename == "table" then
        for _, v in ipairs(value) do
          model:delTag(v.info.id)
        end
      end
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
            model:editTag(getNowItem().id, { name = new_name })
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
    name = "fuzzyFindTag",
    foo = fuzzyFindTag,
  },
  {
    name = "fuzzyFindCard",
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
}

---@param data ModelTableParam
local function start(data)
  setup(data)
  telescopeMenu.setup({ prompt_title = "Evidence MainMenu", menu_item = menuItem, main_foo = nil })
end

return {
  start = start,
}
