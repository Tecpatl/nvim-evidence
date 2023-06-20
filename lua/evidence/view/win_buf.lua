local tools = require("evidence.util.tools")
local tblInfo = require("evidence.model.info")

---@class WinBufImpl
---@field buf number
---@field item CardItem | {}
local WinBufImpl = {}
WinBufImpl.__index = WinBufImpl

function WinBufImpl:new()
  self.buf = -1
  self.item = {}
  return setmetatable({}, self)
end

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

function WinBufImpl:BufferClose()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if bufnr == self.buf then
      vim.api.nvim_win_close(winid, true)
    end
  end
end

---@param start_buf number
---@return boolean
function WinBufImpl:checkSelfBuf(start_buf)
  return start_buf ~= -1 and start_buf == self.buf
end

function WinBufImpl:openSplitWin()
  self:BufferClose()
  local cmd_by_split_mode = self:getSplitCmd()

  local winwidth = self:getWinWidth()
  if (winwidth / 2) >= 80 then
    vim.cmd(cmd_by_split_mode.vertical)
    vim.w.org_window_split_mode = "vertical"
  else
    vim.cmd(cmd_by_split_mode.horizontal)
    vim.w.org_window_split_mode = "horizontal"
  end
  if not self:checkBufValid() then
    self.buf = vim.api.nvim_create_buf(true, true)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, self.buf)
  end
  vim.keymap.set("n", "q", ":call nvim_win_close(win_getid(), v:true)<CR>", { buffer = self.buf, silent = true })
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
  vim.wo.foldmethod = "expr"
  vim.wo.foldlevel = 1
  --vim.api.nvim_feedkeys("za", "n", false)
  --vim.api.nvim_feedkeys("zx", "n", false)
end

function WinBufImpl:setup(data)
  if data.buf ~= nil then
    self.buf = data.buf
  end
  if data.win ~= nil then
    self.win = data.win
  end
end

---@class WinBuf
---@field _ WinBufImpl
---@field model Model
---@field is_setup boolean
---@field instance WinBuf
---@field divider string
local WinBuf = {}

WinBuf.__index = function(self, key)
  print(key)
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
    self._ = WinBufImpl:new()
    self.instance = setmetatable({
      model = {},
      is_setup = false,
      divider = "================",
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
  vim.api.nvim_command("highlight EvidenceWordHidden guibg=white guifg=white")
  self._:setup(data)
end

---@class WinBufInfo
---@field win number
---@field buf number
---@field item CardItem

---@return WinBufInfo
function WinBuf:getInfo()
  return {
    win = self._.win,
    buf = self._.buf,
    item = self._.item,
  }
end

function WinBuf:openFloatWin()
  self._:openFloatWin()
end

function WinBuf:extractString(inputString)
  local startIndex, endIndex = string.find(inputString, self.divider)
  if endIndex then
    local extractedString = string.sub(inputString, 1, endIndex)
    return extractedString
  else
    return inputString
  end
end

---@param item CardItem
---@param is_fold? boolean
function WinBuf:viewContent(item, is_fold)
  self.model:insertRecordCard(item.id, tblInfo.AccessWay.visit)
  is_fold = is_fold or true
  self._.item = item
  self:switchFold(is_fold)
end

---@param is_fold boolean
function WinBuf:switchFold(is_fold)
  local content = self._.item.content
  if is_fold then
    -- content = self:extractString(content)
    vim.fn.matchadd("EvidenceWordHidden", "{{<\\_.\\{-}>}}")
  else
    local winid = tools.get_window_id_from_buffer_id(self._.buf)
    if winid ~= nil then
      tools.clear_match("EvidenceWordHidden", winid)
    end
  end
  self._:viewContent(content)
end

function WinBuf:openSplitWin()
  self._:openSplitWin()
end

---@param start_buf number
---@return boolean
function WinBuf:checkSelfBuf(start_buf)
  return self._:checkSelfBuf(start_buf)
end

return WinBuf:getInstance()
