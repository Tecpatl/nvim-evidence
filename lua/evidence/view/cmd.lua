local menu = require("evidence.view.menu")
local model = require("evidence.model.index")
local tools = require("evidence.util.tools")
local winBuf = require("evidence.view.win_buf")

---@type ModelTableParam
local user_data = nil
local is_start_ = false
local telescope_menu = nil

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
  model:setup(data)
  winBuf:setup({ model = model }, "## answer")
  menu:setup({ winBuf = winBuf, model = model})
end

---@type SimpleMenu[]
local menuItem = {
  {
    name = "addCard",
    foo = function()
      return menu:addCard()
    end,
  },
  {
    name = "nextCard",
    foo = function()
      return menu:nextCard()
    end,
  },
  {
    name = "delCard",
    foo = function()
      return menu:delCard()
    end,
  },
  {
    name = "answer",
    foo = function()
      return menu:answer()
    end,
  },
  {
    name = "editCard",
    foo = function()
      return menu:editCard()
    end,
  },
  {
    name = "infoCard",
    foo = function()
      return menu:infoCard()
    end,
  },
  {
    name = "scoreCard",
    foo = function()
      return menu:scoreCard()
    end,
  },
  {
    name = "findCard",
    foo = function()
      return menu:fuzzyFindCard()
    end,
  },
  {
    name = "findTagsByNowCard",
    foo = function()
      return menu:findTagsByNowCard()
    end,
  },
  {
    name = "setTagsForNowCard",
    foo = function()
      return menu:setTagsForNowCardMain()
    end,
  },
  {
    name = "addTag",
    foo = function()
      return menu:addTag()
    end,
  },
  {
    name = "renameTag",
    foo = function()
      return menu:renameTag()
    end,
  },
  {
    name = "delTags",
    foo = function()
      return menu:delTags()
    end,
  },
  {
    name = "setSelectTagsAnd",
    foo = function()
      return menu:setSelectTagsTreeMode(-1, true, true)
    end,
  },
  {
    name = "setSelectTagsOr",
    foo = function()
      return menu:setSelectTagsTreeMode(-1, false, true)
    end,
  },
  {
    name = "findCardBySelectTags",
    foo = function()
      return menu:findCardBySelectTags()
    end,
  },
  {
    name = "findReviewCard",
    foo = function()
      return menu:findReviewCard()
    end,
  },
  {
    name = "findNewCard",
    foo = function()
      return menu:findNewCard()
    end,
  },
  {
    name = "setNextCard",
    foo = function()
      return menu:setNextCard()
    end,
  },
  {
    name = "tagList",
    foo = function()
      return menu:tagList()
    end,
  },
  {
    name = "tagTree",
    foo = function()
      return menu:tagTreeMain()
    end,
  },
  {
    name = "convertTagFather",
    foo = function()
      return menu:convertTagFatherStart()
    end,
  },
  {
    name = "mergeTag",
    foo = function()
      return menu:mergeTagStart()
    end,
  },
  {
    name = "recordCard",
    foo = function()
      return menu:recordCard()
    end,
  },
}

local function start()
  if not checkStartInSelfBuf() then
    return
  end
  menu:telescopeStart(menuItem)
end

---@param data ModelTableParam
local function flush(data)
  setup(data)
  winBuf:openSplitWin()
  menu:nextCard()
end

return {
  start = start,
  flush = flush,
}
