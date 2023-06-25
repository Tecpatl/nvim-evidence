local tools = require("evidence.util.tools")
local queue = require("evidence.util.queue")
local tblInfo = require("evidence.model.info")

---@class WinBufIdInfo
---@field win_id number
---@field buf_id number

---@class WinBufImpl
---@field buf number
---@field name string
---@field item CardItem | {}
local WinBufImpl = {}
WinBufImpl.__index = WinBufImpl

---@param name string
function WinBufImpl:new(name)
  local new_buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(new_buf, name)
  return setmetatable({
    name = name,
    buf = new_buf,
    item = {},
  }, self)
end

--function WinBufImpl:setup(data)
--  if data.buf ~= nil then
--    self.buf = data.buf
--  end
--  if data.win ~= nil then
--    self.win = data.win
--  end
--end

---@param winnr? number
---@return number
function WinBufImpl:getWinWidth(winnr)
  winnr = winnr or 0
  local winwidth = vim.api.nvim_win_get_width(winnr)

  local win_id
  if winnr == 0 then -- use current window
    win_id = vim.fn.win_getid()
  else
    win_id = vim.fn.win_getid(winnr)
  end

  local wininfo = vim.fn.getwininfo(win_id)[1]
  -- this encapsulates both signcolumn & numbercolumn (:h wininfo)
  local gutter_width = wininfo and wininfo.textoff or 0

  return winwidth - gutter_width
end

function WinBufImpl:openFloatWin()
  self.buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(self.buf, "bufhidden", "wipe")

  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.6 - 4)
  local win_width = math.ceil(width * 0.6)

  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = "rounded",
  }

  local win = vim.api.nvim_open_win(self.buf, true, opts)
  vim.api.nvim_win_set_option(win, "cursorline", true)
end

local cmd_by_split_mode_list = {
  new_horizontal = string.format("34split"),
  new_vertical = string.format("vsplit"),
  old_horizontal = string.format("belowright sb "),
  old_vertical = string.format("vertical belowright sb "),
}

---@return boolean
function WinBufImpl:checkBufValid()
  return self.buf ~= -1 and vim.api.nvim_buf_is_valid(self.buf)
end

function WinBufImpl:getSplitCmd()
  if not self:checkBufValid() then
    return {
      horizontal = cmd_by_split_mode_list.new_horizontal,
      vertical = cmd_by_split_mode_list.new_vertical,
    }
  else
    return {
      horizontal = cmd_by_split_mode_list.old_horizontal .. self.buf,
      vertical = cmd_by_split_mode_list.old_vertical .. self.buf,
    }
  end
end

function WinBufImpl:bufferDelete()
  vim.api.nvim_buf_delete(self.buf, {})
end

function WinBufImpl:bufferClose()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if bufnr == self.buf then
      vim.api.nvim_win_close(winid, true)
    end
  end
end

---@param win_id number
---@return WinBufIdInfo
function WinBufImpl:openSplitWin(win_id)
  vim.api.nvim_set_current_win(win_id)
  local cmd_by_split_mode = self:getSplitCmd()
  local winwidth = self:getWinWidth(win_id)
  if (winwidth / 2) >= 80 then
    vim.cmd(cmd_by_split_mode.vertical)
    vim.w.org_window_split_mode = "vertical"
  else
    vim.cmd(cmd_by_split_mode.horizontal)
    vim.w.org_window_split_mode = "horizontal"
  end
  local new_win_id = vim.api.nvim_get_current_win()
  if not self:checkBufValid() then
    vim.api.nvim_win_set_buf(new_win_id, self.buf)
  end
  vim.keymap.set("n", "q", ":call nvim_win_close(win_getid(), v:true)<CR>", { buffer = self.buf, silent = true })
  return {
    buf_id = self.buf,
    win_id = new_win_id,
  }
end

function WinBufImpl:viewContent(form)
  if form == nil then
    error("viewContent nil")
    return
  end
  local formTbl = tools.str2table(form)
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, formTbl)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
  if not self.item.file_type or self.item.file_type == "" then
    self.item.file_type = "markdown"
  end
  vim.api.nvim_buf_set_option(self.buf, "filetype", self.item.file_type)
  vim.wo.number = true
  vim.wo.relativenumber = true
  vim.o.cursorcolumn = true
  vim.wo.cursorline = true
  --vim.api.nvim_feedkeys("gg", "n", false)
  -- vim.wo.foldmethod = "expr"
  -- vim.wo.foldlevel = 1
  --vim.api.nvim_feedkeys("za", "n", false)
  --vim.api.nvim_feedkeys("zx", "n", false)
end

---@class HighlightWord
---@field id number
---@field name string
---@field guibg string
---@field guifg string

---@class WinBuf
---@field _ WinBufImpl[]
---@field model Model
---@field is_setup boolean
---@field instance WinBuf
---@field divider string
---@field data_ table
---@field highlight_words_ HighlightWord[]
---@field highlight_lim number
local WinBuf = {}

WinBuf.__index = function(self, key)
  local value = rawget(WinBuf, key)
  if key ~= "setup" then
    if not self.is_setup then
      error("Class not initialized. Please call setup() first.", 2)
    end
  end
  return value
end

WinBuf.__newindex = function()
  error("Attempt to modify a read-only table")
end

function WinBuf:getInstance()
  if not self.instance then
    self.instance = setmetatable({
      _ = {},
      data_ = {},
      model = {},
      is_setup = false,
      divider = "================",
      highlight_words_ = {},
      highlight_lim = 3,
    }, self)
  end
  return self.instance
end

---@param data table
---@param divider? string
function WinBuf:setup(data, divider)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  self.model = data.model
  if divider then
    self.divider = divider
  end
  WinBuf.__index = WinBuf
  self.data_ = data
  self._ = {}
  self:initHighlight(self.highlight_lim)
end

---@param count number
function WinBuf:initHighlight(count)
  local colors = tools.generateDistinctColors(count)
  for i = #colors, 1, -1 do
    local color = colors[i]
    local name = "EvidenceWordHidden" .. i
    table.insert(self.highlight_words_, { id = i, name = name, guibg = color, guifg = color })
    vim.api.nvim_command("highlight " .. name .. " guibg=" .. color .. " guifg=" .. color)
  end
end

---@param win_id number
function WinBuf:addHighlight(win_id)
  for _, v in ipairs(self.highlight_words_) do
    vim.api.nvim_win_call(win_id, function()
      local pattern = "{{<\\[" .. v.id .. "\\]" .. "\\_.\\{-\\}" .. "\\[" .. v.id .. "\\]>}}"
      vim.fn.matchadd(v.name, pattern)
    end)
  end
end

---@param win_id number
function WinBuf:delHighlight(win_id)
  for _, v in ipairs(self.highlight_words_) do
    tools.clear_match(v.name, win_id)
  end
end

---@class WinBufInfo
---@field buf number
---@field item CardItem
---@field name string

---@return WinBufImpl
function WinBuf:getNowBufItem(buf_id)
  for k, v in ipairs(self._) do
    if v.buf == buf_id then
      return v
    end
  end
  error("getNowBufItem buf_id not exist")
end

---@return WinBufInfo[]
function WinBuf:getAllInfo()
  local items = {}
  for k, v in ipairs(self._) do
    table.insert(items, {
      buf = v.buf,
      item = v.item,
      name = v.name,
    })
  end
  return items
end

---@return WinBufInfo
function WinBuf:getNowInfo(buf_id)
  local buf_item = self:getNowBufItem(buf_id)
  return {
    buf = buf_item.buf,
    item = buf_item.item,
    name = buf_item.name,
  }
end

---@param buf_id number
---@return boolean
function WinBuf:isIncludeBuf(buf_id)
  for k, v in ipairs(self._) do
    if v.buf == buf_id then
      return true
    end
  end
  return false
end

---@return WinBufInfo
function WinBuf:getFirstInfo()
  local buf_item = queue.front(self._)
  if buf_item == nil then
    error("getFirstInfo empty")
  end
  return {
    buf = buf_item.buf,
    item = buf_item.item,
    name = buf_item.name,
  }
end

--function WinBuf:openFloatWin()
--  self._:openFloatWin()
--end

function WinBuf:extractString(inputString)
  local startIndex, endIndex = string.find(inputString, self.divider)
  if endIndex then
    local extractedString = string.sub(inputString, 1, endIndex)
    return extractedString
  else
    return inputString
  end
end

---@param buf_id number
---@param item CardItem
---@param is_fold? boolean
---@param is_record? boolean
function WinBuf:viewContent(buf_id, item, is_fold, is_record)
  if is_record == nil then
    is_record = true
  end
  if is_record then
    self.model:insertRecordCard(item.id, tblInfo.AccessWay.visit)
  end
  local buf_item = self:getNowBufItem(buf_id)
  is_fold = is_fold or true
  buf_item.item = item
  self:switchFold(buf_id, is_fold)
end

---@param buf_id number
---@param is_fold boolean
function WinBuf:switchFold(buf_id, is_fold)
  local buf_item = self:getNowBufItem(buf_id)
  local content = buf_item.item.content
  local winid = tools.get_window_id_from_buffer_id(buf_item.buf)
  if is_fold then
    content = self:extractString(content)
    if winid ~= nil then
      -- todo
      --vim.api.nvim_win_call(winid, function()
      --  vim.fn.matchadd("EvidenceWordHidden", "{{<\\_.\\{-\\}>}}")
      --end)
      self:addHighlight(winid)
    end
  else
    if winid ~= nil then
      self:delHighlight(winid)
      -- todo
      --tools.clear_match("EvidenceWordHidden", winid)
    end
  end
  buf_item:viewContent(content)
end

---@param backup_win_id number
---@param buf_ids number[]
function WinBuf:openSplitWin(backup_win_id, buf_ids)
  for key, buf_id in pairs(buf_ids) do
    local win_id = tools.get_window_id_from_buffer_id(buf_id)
    if win_id ~= nil then
      vim.api.nvim_set_current_win(win_id)
    else
      local buf_item = self:getNowBufItem(buf_id)
      buf_item:openSplitWin(backup_win_id)
    end
  end
end

---@param win_id number -- outer base_win
---@param buf_id? number
---@return WinBufIdInfo -- inner new_win
function WinBuf:createSplitWin(win_id, buf_id)
  local item = nil
  if buf_id == nil then
    item = WinBufImpl:new("evidence[" .. tostring(#self._) .. "]")
    queue.push(self._, item)
  else
    for k, v in ipairs(self._) do
      if v.buf == buf_id then
        item = v
      end
    end
  end
  if item == nil then
    error("createSplitWin")
  end
  return item:openSplitWin(win_id)
end

function WinBuf:deleteAll()
  local tbl = self._
  for i = #tbl, 1, -1 do
    tbl[i]:bufferDelete()
  end
  self._ = {}
end

---@param buf_id number
function WinBuf:closeBufId(buf_id)
  for key, item in ipairs(self._) do
    if item.buf == buf_id then
      item:bufferClose()
    end
  end
end

function WinBuf:closeAll()
  for key, item in ipairs(self._) do
    item:bufferClose()
  end
end

---@return WinBufIdInfo
function WinBuf:remainOne()
  local tbl = self._
  if #tbl < 1 then
    error("remainOne empty")
  end
  for i = #tbl, 2, -1 do
    tbl[i]:bufferClose()
  end
  local buf_id = tbl[1].buf
  local win_id = tools.get_window_id_from_buffer_id(buf_id)
  return {
    buf_id = buf_id,
    win_id = win_id,
  }
end

---@param buf_id number
function WinBuf:delete(buf_id)
  local tbl = self._
  if #tbl == 1 then
    print("need remain one")
    return
  end
  for i = #tbl, 1, -1 do
    if tbl[i].buf == buf_id then
      tbl[i]:bufferDelete()
      table.remove(tbl, i)
    end
  end
end

---@param buf_id number
---@return boolean
function WinBuf:checkSelfBuf(buf_id)
  for key, buf_item in pairs(self._) do
    if buf_id == buf_item.buf then
      return true
    end
  end
  return false
end

---@param buf_id number
---@return boolean
function WinBuf:checkSelfBufValid(buf_id)
  for key, buf_item in pairs(self._) do
    if buf_id == buf_item.buf then
      local ret = self.model:checkCardExistById(buf_item.item.id)
      buf_item.item.is_active = ret
      return ret
    end
  end
  return false
end

return WinBuf:getInstance()
