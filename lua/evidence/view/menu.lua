local model = require("evidence.model.index")
local tools = require("evidence.util.tools")
local winBuf = require("evidence.view.win_buf")
local telescopeMenu = require("evidence.view.telescope")
local menuHelper = require("evidence.view.menu_helper")

---@type ModelTableParam
local user_data = nil
local is_start_ = false

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
end

local function add()
  print("add")
end

---@return MenuData
local function findTag()
  local res = model:findTag()
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

---@return MenuData
local function fuzzyFind()
  local res = model:fuzzyFind("", 50)
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

---@type SimpleMenu[]
local menuItem = {
  {
    name = "addCard",
    foo = addCard,
  },
  {
    name = "findTags",
    foo = findTag,
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
