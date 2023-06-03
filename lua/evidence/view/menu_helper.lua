local model = require("evidence.model.index")
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

local function clear_match()
  vim.api.nvim_exec(
    [[
       for m in filter(getmatches(), { i, v -> l:v.group is? 'EvidenceWord' })
       call matchdelete(m.id)
       endfor
     ]],
    true
  )
end

function MenuHelper:createCardPreviewer()
  local this = self
  return previewers.new_buffer_previewer({
    keep_last_buf = true,
    get_buffer_by_name = function(_, entry)
      return entry.value.id
    end,
    define_preview = function(self, entry, status)
      --print(vim.inspect(entry))
      local formTbl = tools.str2table(entry.display)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, formTbl)
      local file_type = entry.value.file_type
      if not file_type or file_type == "" then
        file_type = "markdown"
      end
      putils.highlighter(self.state.bufnr, file_type)
      vim.schedule(function()
        vim.api.nvim_buf_call(self.state.bufnr, function()
          clear_match()
          vim.api.nvim_command("call matchadd('EvidenceWord','" .. this.prompt .. "')")
        end)
      end)
    end,
  })
end

local card_entry_maker = function(entry)
  local content = entry.content:gsub("\n", "\\n")
  return {
    value = entry,
    ordinal = content,
    display = content,
  }
end

local empty_maker = function(entry)
  return {
    value = entry,
    ordinal = entry,
    display = "",
  }
end

function MenuHelper:createCardProcessWork()
  return function(prompt, process_result, process_complete)
    self.prompt = prompt
    --	if now_search_mode == SearchMode.fuzzy then
    local x = self.model:fuzzyFind(prompt, 50)
    --	elseif now_search_mode == SearchMode.min_due then
    --		x = model:getMinDueItem(50)
    --	end
    if type(x) ~= "table" then
      process_result(empty_maker(prompt))
      process_complete()
      return
    end
    for _, v in ipairs(x) do
      v.foo = function()
        winBuf:viewContent(v)
      end
      process_result(card_entry_maker(v))
    end
    process_complete()
  end
end

---@param name string
---@return boolean
function MenuHelper:confirmCheck(name)
  local confirm = tools.uiInput(name .. "  (y/n):", "")
  if confirm ~= "y" then
    print(name .. " failed")
    return false
  end
  return true
end

---@return CardItem[]|nil
function MenuHelper:calcNextList()
  -- TODO: custom
  local new_ratio = 30
  local item = nil
  if math.floor(math.random(0, 100)) < new_ratio then
    item = self.model:getMinDueItem(1)
    if item == nil then
      item = model:getNewItem(1)
    end
  else
    item = self.model:getNewItem(1)
    if item == nil then
      item = self.model:getMinDueItem(1)
    end
  end
  return item
end

return MenuHelper:getInstance()
