local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local actions = require("telescope.actions")
local entry_display = require("telescope.pickers.entry_display")
local action_state = require("telescope.actions.state")
local ns_previewer = vim.api.nvim_create_namespace("telescope.previewers")
local status1, telescope = pcall(require, "telescope")
local tools = require("evidence.util.tools")
local mappings = require("telescope.mappings")

---@class SimpleMenu
---@field name string
---@field foo? function
---@field info? any custom

---@class EntryMaker
---@field value any
---@field ordinal any
---@field display any

---@class TelescopeMenu
---@field prompt_title string
---@field menu_item SimpleMenu[]
---@field main_foo function
---@field previewer function|nil
---@field process_work function
---@field card_entry_maker function
---@field custom_mappings table
---@field attach_mappings function
local TelescopeMenu = {}
TelescopeMenu.__index = TelescopeMenu

local emptyFoo = function() end

function TelescopeMenu:reset()
  self.prompt_title = "Evidence"
  self.menu_item = {}
  self.main_foo = function(value) end
  self.previewer = nil
  self.process_work = function(prompt, process_result, process_complete)
    return self:processWorkDefault(prompt, process_result, process_complete)
  end
  self.card_entry_maker = function(entry)
    return self:entryMakerDefault(entry)
  end
  self.custom_mappings = {}
  self.attach_mappings = function(prompt_bufnr, map)
    self:refreshMapping(map)
    actions.select_default:replace(function()
      local picker = action_state.get_current_picker(prompt_bufnr)
      local select_item = action_state.get_selected_entry()
      local single = nil
      local res = nil
      if select_item == nil then
        local value = picker:_get_prompt()
        if self.main_foo ~= nil then
          res = self.main_foo(value)
        end
      else
        single = select_item.value
        local multi = picker:get_multi_selection()
        if not tools.isTableEmpty(multi) and self.main_foo ~= nil then
          res = self.main_foo(self:convertValueArray(multi))
        elseif not tools.isTableEmpty(single) and single.foo ~= nil then
          res = single.foo()
        end
      end

      self:flushResult(res, picker, prompt_bufnr, map)
    end)
    return true
  end
end

function TelescopeMenu:new()
  self:reset()
  return setmetatable({}, self)
end

---@param data TelescopeMenu
function TelescopeMenu:setup(data)
  tools.merge(self, data, false)
end

--local self = {}

---@param prompt string
---@param process_result function
---@param process_complete function
function TelescopeMenu:processWorkDefault(prompt, process_result, process_complete)
  for _, v in ipairs(self.menu_item) do
    local val = self.card_entry_maker(v)
    process_result(val)
  end
  process_complete()
end

---@param entry SimpleMenu
---@return EntryMaker
function TelescopeMenu:entryMakerDefault(entry)
  local name = entry.name
  return {
    value = entry,
    ordinal = name,
    display = name,
  }
end

---@class MenuInfo
---@field prompt string

function TelescopeMenu:async_job()
  return setmetatable({
    close = function()
      --print("close")
    end,
    results = {},
    entry_maker = self.card_entry_maker,
  }, {
    __call = function(_, prompt, process_result, process_complete)
      local work = self.process_work
      if work then
        work(prompt, process_result, process_complete)
      end
    end,
  })
end

---@param maker EntryMaker[]
function TelescopeMenu:convertValueArray(maker)
  local result = {}
  for _, v in ipairs(maker) do
    table.insert(result, v.value)
  end
  return result
end

function TelescopeMenu:refreshMapping(map)
  if self.custom_mappings then
    for mode, tbl in pairs(self.custom_mappings) do
      for key, action in pairs(tbl) do
        map(mode, key, action)
      end
    end
  end
end

---@param res TelescopeMenu|nil
---@param picker table
---@param prompt_bufnr number
---@param map? table
function TelescopeMenu:flushResult(res, picker, prompt_bufnr, map)
  if res ~= nil then
    assert(res.prompt_title ~= nil)
    assert(res.menu_item ~= nil)
    self:setup(res)

    picker.prompt_border:change_title(res.prompt_title)
    local finder = picker.finder
    picker:refresh(finder, { reset_prompt = true, multi = picker._multi })

    local last_previewer = picker.previewer
    if res.previewer ~= nil then
      picker.previewer = res.previewer
    else
      picker.previewer = nil
    end
    if last_previewer ~= picker.previewer then
      picker:full_layout_update()
    end
    if self.custom_mappings ~= {} then
      mappings.apply_keymap(prompt_bufnr, self.attach_mappings, self.custom_mappings)
    end
  else
    local ret = tools.get_window_id_from_buffer_id(prompt_bufnr)
    if ret ~= nil then
      actions.close(prompt_bufnr)
    end
  end
end

function TelescopeMenu:liveFd(option)
  pickers
      .new(option, {
        prompt_title = self.prompt_title,
        finder = self:async_job(),
        sorter = conf.generic_sorter(option), -- shouldn't this be default?
        previewer = self.previewer,
        attach_mappings = self.attach_mappings,
      })
      :find()
end

---@param data TelescopeMenu
function TelescopeMenu:start(data)
  self:reset()
  self:setup(data)
  return self:liveFd({})
end

return TelescopeMenu
