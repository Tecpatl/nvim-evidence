local menu = require("evidence.view.menu")
local model = require("evidence.model.index")
local tools = require("evidence.util.tools")
local winBuf = require("evidence.view.win_buf")

---@type ModelTableParam
local user_data = nil
local is_start_ = false
local telescope_menu = nil
local visual_content = ""
local file_type = ""

---@return boolean
local function checkStartInSelfBuf()
  local start_buf = vim.api.nvim_get_current_buf()
  if is_start_ == false or start_buf == -1 or not winBuf:checkSelfBuf(start_buf) then
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
  menu:setup({ winBuf = winBuf, model = model })
end

---@type SimpleMenu[]
local emptyNormalMenu = {
  {
    name = "addCard",
    foo = function()
      return menu:addCard()
    end,
  },
}

---@type SimpleMenu[]
local emptyVisualMenu = {
  {
    name = "addCard",
    foo = function()
      return menu:addCardSplit(visual_content, file_type)
    end,
  },
}

---@type SimpleMenu[]
local normalMenu = {
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
    name = "hidden",
    foo = function()
      return menu:hidden()
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
  {
    name = "setBufferList",
    foo = function()
      return menu:setBufferList()
    end,
  },
  {
    name = "refreshCard",
    foo = function()
      return menu:refreshCard()
    end,
  },
}

---@type SimpleMenu[]
local visualMenu = {
  {
    name = "addCard",
    foo = function()
      return menu:addCardSplit(visual_content, file_type)
    end,
  },
  {
    name = "addDivider",
    foo = function()
      menu:addDivider()
    end,
  },
}

---@param is_region? boolean
---@return WinBufIdInfo
local function setNowBufWin(is_region)
  local now_win_id = vim.api.nvim_get_current_win()
  local now_buf_id = vim.api.nvim_get_current_buf()
  local region = {}
  if is_region == true then
    region = tools.getVisualSelectPos()
  end
  menu:setNowBufWinId(now_buf_id, now_win_id, region)
  return {
    win_id = now_win_id,
    buf_id = now_buf_id,
  }
end

---@param content string
local function startVisual(content)
  if not checkStartInSelfBuf() then
    return
  end
  local info = setNowBufWin(true)
  file_type = vim.api.nvim_buf_get_option(info.buf_id, "filetype")
  visual_content = content
  local menuList = emptyVisualMenu
  if winBuf:checkSelfBufValid(info.buf_id) then
    menuList = visualMenu
  end
  menu:telescopeStart("VisualMenu", menuList)
end

local function startNormal()
  if not checkStartInSelfBuf() then
    return
  end
  local info = setNowBufWin()
  local menuList = emptyNormalMenu
  if winBuf:checkSelfBufValid(info.buf_id) then
    menuList = normalMenu
  end
  menu:telescopeStart("NormalMenu", menuList)
end

---@param data ModelTableParam
local function flush(data)
  setup(data)
  local buf_id = -1
  local now_win_id = vim.api.nvim_get_current_win()
  local now_buf_id = vim.api.nvim_get_current_buf()
  local is_include = winBuf:isIncludeBuf(now_buf_id)
  if is_include then
    return
  end
  local is_next = false
  if #winBuf._ == 0 then
    local info = winBuf:createSplitWin(now_win_id)
    buf_id = info.buf_id
    is_next = true
  else
    local info = winBuf:getFirstInfo()
    buf_id = info.buf
    local win_id = tools.get_window_id_from_buffer_id(buf_id)
    --- win is closed, need reopen
    if win_id == nil then
      is_next = true
      winBuf:createSplitWin(now_win_id, buf_id)
    end
    winBuf:openSplitWin(now_win_id, { buf_id })
  end
  setNowBufWin()
  if is_next then
    menu:nextCard()
  end
end

return {
  startNormal = startNormal,
  startVisual = startVisual,
  flush = flush,
}
