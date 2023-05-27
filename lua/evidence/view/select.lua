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

local fn
local s_prompt = ""

local entry_maker = function(entry)
  local val = entry.val
  return {
    value = entry,
    ordinal = val,
    display = val,
  }
end

local arr = {
  {
    val = "aaa11",
  },
  {
    val = "bbb12",
  },
  {
    val = "ccc124",
  },
  {
    val = "x111",
  },
  {
    val = "y222",
  },
}

local process_work = function(prompt, process_result, process_complete)
  for _, v in ipairs(arr) do
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
    s_prompt = prompt
    process_work(prompt, process_result, process_complete)
  end,
})

local function live_fd(opts)
  pickers
      .new(opts, {
        prompt_title = "MultiSelect",
        finder = async_job,
        sorter = conf.generic_sorter(opts), -- shouldn't this be default?
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local picker = action_state.get_current_picker(prompt_bufnr)
            local multi = picker:get_multi_selection()

            actions.close(prompt_bufnr)
          end)
          return true
        end,
      })
      :find()
end

local function find()
  local opts = {}
  return live_fd(opts)
end

return {
  find = find,
}
