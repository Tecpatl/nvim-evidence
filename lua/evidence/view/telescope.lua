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

---@class SimpleMenu
---@field name string
---@field foo? function
---@field info? any custom

---@class MenuData
---@field prompt_title string
---@field menu_item SimpleMenu[]
---@field main_foo? function
---@field previewer? function
---@field process_work? function

---@type MenuData
local menu_data_ = {
  prompt_title = "Evidence",
  menu_item = {},
  main_foo = nil,
  previewer = nil,
  process_work = nil,
}

---@class EntryMaker
---@field value any
---@field ordinal any
---@field display any

---@param entry SimpleMenu
---@return EntryMaker
local entry_maker = function(entry)
  local name = entry.name
  return {
    value = entry,
    ordinal = name,
    display = name,
  }
end

---@class MenuInfo
---@field prompt string

local process_work_default = function(prompt, process_result, process_complete)
  for _, v in ipairs(menu_data_.menu_item) do
    process_result(entry_maker(v))
  end
  process_complete()
end

local async_job = setmetatable({
  close = function()
    --print("close")
  end,
  results = {},
  entry_maker = entry_maker,
}, {
  __call = function(_, prompt, process_result, process_complete)
    local work = menu_data_.process_work or process_work_default
    work(prompt, process_result, process_complete)
  end,
})

---@param maker EntryMaker[]
local function convertValueArray(maker)
  local result = {}
  for _, v in ipairs(maker) do
    table.insert(result, v.value)
  end
  return result
end

local function live_fd(option)
  pickers
      .new(option, {
        prompt_title = menu_data_.prompt_title,
        finder = async_job,
        sorter = conf.generic_sorter(option), -- shouldn't this be default?
        previewer = menu_data_.previewer,
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local picker = action_state.get_current_picker(prompt_bufnr)
            local select_item = action_state.get_selected_entry()
            local single = nil
            local res = nil
            if select_item == nil then
              local value = picker:_get_prompt()
              if menu_data_.main_foo ~= nil then
                menu_data_.main_foo(value)
              end
            else
              single = select_item.value
              local multi = picker:get_multi_selection()
              if not tools.isTableEmpty(multi) and menu_data_.main_foo ~= nil then
                res = menu_data_.main_foo(convertValueArray(multi))
              elseif not tools.isTableEmpty(single) and single.foo ~= nil then
                res = single.foo()
              end
            end
            if res ~= nil then
              assert(res.prompt_title ~= nil)
              assert(res.menu_item ~= nil)
              menu_data_ = res

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
            else
              actions.close(prompt_bufnr)
            end
          end)
          return true
        end,
      })
      :find()
end

---@param data MenuData
local function setup(data)
  menu_data_ = data
  return live_fd({})
end

return {
  setup = setup,
}
