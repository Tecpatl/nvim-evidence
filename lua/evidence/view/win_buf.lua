local tools = require("evidence.util.tools")

---@class WinBufImpl
---@field win number
---@field buf number
---@field item CardItem | {}
local WinBufImpl = {}
WinBufImpl.__index = WinBufImpl

function WinBufImpl:new()
  self.win = -1
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

  self.win = vim.api.nvim_open_win(self.buf, true, opts)
  vim.api.nvim_win_set_option(self.win, "cursorline", true)
end

function WinBufImpl:openSplitWin()
  if self.win ~= -1 then
    local wininfo = vim.fn.getwininfo(self.win)[1]
    if wininfo ~= nil then
      vim.api.nvim_win_close(self.win, true)
      -- vim.cmd(":call nvim_win_close(" .. win .. ", v:true)")
    end
  end
  local cmd_by_split_mode = {
    horizontal = string.format("34split"),
    vertical = string.format("vsplit"),
  }

  local winwidth = self:getWinWidth()
  if (winwidth / 2) >= 80 then
    vim.cmd(cmd_by_split_mode.vertical)
    vim.w.org_window_split_mode = "vertical"
  else
    vim.cmd(cmd_by_split_mode.horizontal)
    vim.w.org_window_split_mode = "horizontal"
  end
  self.win = vim.api.nvim_get_current_win()
  self.buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(self.win, self.buf)
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
  if not self.item.filetype or self.item.filetype == "" then
    self.item.filetype = "markdown"
  end
  vim.api.nvim_buf_set_option(self.buf, "filetype", self.item.filetype)
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
  print("setup")
end

---@class WinBuf
---@field _ WinBufImpl
---@field is_setup boolean
---@field instance WinBuf
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
    self.instance = setmetatable({ is_setup = false }, self)
  end
  return self.instance
end

---@param data table<string,number>
function WinBuf:setup(data)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  WinBuf.__index = WinBuf
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

---@param item CardItem
function WinBuf:viewContent(item)
  self._.item = item
  self._:viewContent(item.content)
end

function WinBuf:openSplitWin()
  self._:openSplitWin()
end

return WinBuf:getInstance()
