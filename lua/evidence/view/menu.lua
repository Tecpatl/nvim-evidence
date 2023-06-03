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
local function fuzzyFind()
  local res = model:fuzzyFindCard("", 50)
  return {
    prompt_title = "Evidence FuzzyFind",
    menu_item = {},
    main_foo = nil,
    previewer = menuHelper:createCardPreviewer(),
    process_work = menuHelper:createCardProcessWork(),
  }
end

local function addCard()
  if not menuHelper:confirmCheck("addCard") then
    return
  end
  local content = vim.api.nvim_buf_get_lines(winBuf:getInfo().buf, 0, -1, false)
  local content_str = table.concat(content, "\n")
  model:addNewCard(content_str)
end

local function delCard()
  if not menuHelper:confirmCheck("delCard") then
    return
  end
  model:delCard(getNowItem().id)
  nextCard()
end

local function answer()
  winBuf:switchFold(false)
end

local function addTag()
  local card_id = getNowItem().id
  local res = model:findExcludeTagsByCard(card_id)
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        foo = function()
          model:findIncludeTagsByCard(v.id)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence AddTag",
    menu_item = items,
    main_foo = function(value)
      local typename = type(value)
      if typename == "table" then
        for _, v in ipairs(value) do
          model:insertCardTagById(card_id, v.id)
        end
      elseif typename == "string" then
        model:insertCardTagByName(card_id, value)
      end
    end,
  }
end

---@return MenuData
local function findTag()
  local res = model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, { name = v.name, foo = nil })
    end
  end
  return {
    prompt_title = "Evidence FindTag",
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
    name = "findTags",
    foo = findTag,
  },
  {
    name = "addTag",
    foo = addTag,
  },
  {
    name = "fuzzyFind",
    foo = fuzzyFind,
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
