local model = require("evidence.model.index")
local make_entry = require("telescope.make_entry")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local tools = require("evidence.util.tools")
local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local winBuf = require("evidence.view.win_buf")

---@class MenuHelper
---@field instance MenuHelper
---@field model Model
---@field prompt string
local MenuHelper = {}

MenuHelper.__index = function(self, key)
  local value = rawget(MenuHelper, key)
  if key ~= "setup" then
    if not self.is_setup then
      error("Class not initialized. Please call setup() first.", 2)
    end
  end
  return value
end

MenuHelper.__newindex = function()
  error("Attempt to modify a read-only table")
end

function MenuHelper:getInstance()
  if not self.instance then
    self.instance = setmetatable({ is_setup = false, model = {}, prompt = "" }, self)
  end
  return self.instance
end

---@param model Model
function MenuHelper:setup(model)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  self.model = model
end

vim.api.nvim_command("highlight EvidenceWord guibg=red")

function MenuHelper:createCardPreviewer()
  local this = self
  return previewers.new_buffer_previewer({
    keep_last_buf = true,
    get_buffer_by_name = function(_, entry)
      return entry.value.id
    end,
    define_preview = function(self, entry, status)
      local content = entry.ordinal:gsub("\\n", "\n")
      local formTbl = tools.str2table(content)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, formTbl)
      local file_type = entry.value.file_type
      if not file_type or file_type == "" then
        file_type = "markdown"
      end
      putils.highlighter(self.state.bufnr, file_type)
      vim.schedule(function()
        vim.api.nvim_buf_call(self.state.bufnr, function()
          tools.clear_match("EvidenceWord")
          vim.api.nvim_command("call matchadd('EvidenceWord','" .. this.prompt .. "')")
        end)
      end)
    end,
  })
end

---@param buf_id number
---@param entry CardItem
---@param win_id? number
function MenuHelper:card_entry_maker(buf_id, entry, win_id)
  if entry.content == nil then
    return
  end
  entry.foo = function()
    if entry.is_active ~= nil and entry.is_active == false then
      assert(win_id ~= nil)
      local info = winBuf:createSplitWin(win_id) -- will close telescope while create new win
      winBuf:viewContent(info.buf_id, entry, false, false)
      return
    end
    winBuf:viewContent(buf_id, entry)
  end
  local content = entry.content:gsub("\n", "\\n")
  local bar_content = content
  if entry.is_active ~= nil then
    if entry.is_active == true then
      bar_content = "[active]" .. bar_content
    else
      bar_content = "[inactive]" .. bar_content
    end
  end
  return {
    value = entry,
    ordinal = content,
    display = bar_content,
  }
end

function MenuHelper:empty_maker(entry)
  return {
    value = entry,
    ordinal = entry,
    display = "",
  }
end

---@param buf_id number
---@param foo function
---@param win_id? number
function MenuHelper:createCardProcessWork(buf_id, foo, win_id)
  return function(prompt, process_result, process_complete)
    self.prompt = prompt
    local x = foo(prompt)
    if type(x) ~= "table" then
      process_result(self:empty_maker(prompt))
      process_complete()
      return
    end
    for _, v in ipairs(x) do
      process_result(self:card_entry_maker(buf_id, v, win_id))
    end
    process_complete()
  end
end

---@param select_tags number[]
---@param is_select_tag_and boolean
---@return CardItem[]|nil
function MenuHelper:calcNextList(select_tags, is_select_tag_and)
  local new_ratio = 40
  local rand_ratio = 5
  local item = nil
  local random = math.floor(math.random(0, 100))
  if random > new_ratio then
    item = self.model:getMinDueItem(select_tags, is_select_tag_and, true, 1)
    print("next min due")
  elseif random > rand_ratio then
    item = self.model:getNewItem(select_tags, is_select_tag_and, true, 1)
    print("next new")
  end
  if item == nil then
    item = self.model:getRandomItem(select_tags, is_select_tag_and, true, 1)
    print("next random")
  end
  return item
end

---@return boolean
function MenuHelper:checkScore(score)
  return score == 0 or score == 1 or score == 2 or score == 3
end

---@param entry BufferHelper
function MenuHelper:buffer_entry_maker(entry)
  return {
    value = entry,
    ordinal = entry.name,
    display = entry.name,
  }
end

---@param buffers BufferHelper[]
function MenuHelper:createBufferProcessWork(buffers)
  return function(prompt, process_result, process_complete)
    for _, v in ipairs(buffers) do
      process_result(self:buffer_entry_maker(v))
    end
    process_complete()
  end
end

---@param opts table
function MenuHelper:createBasicPreviewer(opts)
  local this = self
  return previewers.new_buffer_previewer({
    keep_last_buf = true,
    get_buffer_by_name = function(_, entry)
      return entry.value.id
    end,
    define_preview = function(self, entry, status)
      local info = entry.value.info
      if info == nil then
        return
      end
      local target_buf_id = info.id
      if not winBuf:checkSelfBuf(target_buf_id) then
        return
      end
      local lines = vim.api.nvim_buf_get_lines(target_buf_id, 0, -1, false)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    end,
  })
end

---@param content string
---@return number
function MenuHelper:getNewDividerId(content)
  local pattern = [[{{<%[(%d+)%].-%[(%d+)%]>}}]]
  local ids = { 0 } -- id start with 1
  for match in string.gmatch(content, pattern) do
    table.insert(ids, tonumber(match))
  end
  return tools.findMinMissingNumber(ids, 255)
end

---@param bufnr number
---@param region SelectRegion
---@param prefixStr string
---@param suffixStr string
function MenuHelper:addPrefixAndSuffix(bufnr, region, prefixStr, suffixStr)
  local INT_MAX = 2147483647
  --vim.api.nvim_set_current_win(tmp_win_id)
  --print(vim.inspect(region))
  local startRow = region.startRow
  local startCol = region.startCol
  local endRow = region.endRow
  local endCol = region.endCol

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  --print(vim.inspect(lines))
  --print(vim.inspect(startRow .. " " .. startCol))
  --print(vim.inspect(endRow .. " " .. endCol))

  for row = startRow, endRow do
    local line = lines[row]
    if row == startRow then
      line = tools.insertStringAtPosition(line, startCol - 1, prefixStr)
    end
    if row == endRow then
      if endCol == INT_MAX then
        line = line .. suffixStr
      else
        line = tools.insertStringAtPosition(line, endCol + #prefixStr, suffixStr)
      end
    end
    lines[row] = line
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

return MenuHelper:getInstance()
