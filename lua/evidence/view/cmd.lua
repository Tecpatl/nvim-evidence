local menu = require("evidence.view.menu")
local model = require("evidence.model.index")
local tools = require("evidence.util.tools")
local winBuf = require("evidence.view.win_buf")

---@class Cmd
---@field user_data ModelTableParam
---@field telescope_menu TelescopeMenu
---@field visual_content string
---@field file_type string
---@field is_setup boolean
local Cmd = {}

Cmd.__index = function(self, key)
  local value = rawget(Cmd, key)
  if key ~= "setup" then
    if not self.is_setup then
      error("Class not initialized. Please call setup() first.", 2)
    end
  end
  return value
end

Cmd.__newindex = function()
  error("Attempt to modify a read-only table")
end

---@return Cmd
function Cmd:getInstance()
  if not self.instance then
    self.instance = setmetatable({
      is_setup = false,
      user_data = {},
      telescope_menu = {},
      visual_content = "",
      file_type = "",
    }, self)
  end
  return self.instance
end

---@return boolean
function Cmd:checkStartInSelfBuf()
  local start_buf = vim.api.nvim_get_current_buf()
  if start_buf == -1 or not winBuf:checkSelfBuf(start_buf) then
    print("evidence need in self buf. call flush first if buf is closed")
    return false
  end
  return true
end

---@param data ModelTableParam
function Cmd:setup(data)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  user_data = data
  model:setup(data)
  winBuf:setup({ model = model }, "## answer")
  menu:setup({ winBuf = winBuf, model = model })
  winBuf:setBufferSaveCallback(function()
    local info = self:setNowBufWin(false)
    if winBuf:checkSelfBufValid(info.buf_id) then
      menu:editCard()
    else
      print("card_id not exist cannot save")
    end
  end)
end

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
local emptyNormalMenu = {
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
    name = "findCardById",
    foo = function()
      return menu:findCardById()
    end,
  },
  {
    name = "fuzzyFindCard",
    foo = function()
      return menu:fuzzyFindCard()
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
      return menu:findCardBySelectTags(menu.select_tags, menu.is_select_tag_and, menu:selectTagNameStr())
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
}

---@type SimpleMenu[]
local normalMenu = tools.table_concat({
  {
    name = "refreshCard",
    foo = function()
      return menu:refreshCard()
    end,
  },
  {
    name = "findTagsByNowCard",
    foo = function()
      local card_id = menu:getNowItem().id
      return menu:findTagsByNowCard(card_id)
    end,
  },
  {
    name = "setTagsForNowCard",
    foo = function()
      return menu:setTagsForNowCardMain()
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
      menu:findFsrsByNowCard()
    end,
  },
  {
    name = "scoreCard",
    foo = function()
      return menu:scoreCard()
    end,
  },
  {
    name = "addFsrsMark",
    foo = function()
      menu:addFsrsMark()
    end,
  },
  {
    name = "postponeFsrs",
    foo = function()
      return menu:postponeFsrs()
    end,
  },
}, emptyNormalMenu)

---@type SimpleMenu[]
local visualMenu = tools.table_concat({
  {
    name = "addDivider",
    foo = function()
      menu:addDivider()
    end,
  },
}, emptyVisualMenu)

---@param is_region? boolean
---@return WinBufIdInfo
function Cmd:setNowBufWin(is_region)
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
function Cmd:startVisual(content)
  if not self:checkStartInSelfBuf() then
    return
  end
  local info = self:setNowBufWin(true)
  file_type = vim.api.nvim_buf_get_option(info.buf_id, "filetype")
  visual_content = content
  local msg = "EmptyVisualMenu"
  local menuList = emptyVisualMenu
  if winBuf:checkSelfBufValid(info.buf_id) then
    menuList = visualMenu
    msg = "visualMenu"
  end
  menu:telescopeStart(msg, menuList)
end

function Cmd:startNormal()
  if not self:checkStartInSelfBuf() then
    return
  end
  local info = self:setNowBufWin()
  local msg = "EmptyNormalMenu"
  local menuList = emptyNormalMenu
  if winBuf:checkSelfBufValid(info.buf_id) then
    menuList = normalMenu
    msg = "NormalMenu"
  end
  menu:telescopeStart(msg, menuList)
end

function Cmd:flush()
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
  self:setNowBufWin()
  if is_next then
    menu:nextCard()
  end
end

return Cmd:getInstance()
