local model = require("evidence.model.index")
local tools = require("evidence.util.tools")
local winBuf = require("evidence.view.win_buf")
local telescopeFull = require("evidence.view.telescope_full")
local telescopeSimple = require("evidence.view.telescope_simple")

---@type ModelTableInfo
local user_data = nil
local is_start_ = false

local function setup()
  if is_start_ == true then
    return
  end
  is_start_ = true
  model:setup(user_data)
  winBuf:setup({}, "## answer")
end

local function add()
  print("add")
end

---@return MenuData
local function findTag()
  local res = model:findTag()
  local items = {}
  for _, v in ipairs(res) do
    table.insert(items, { name = v.name, foo = nil })
  end
  return {
    prompt_title = "EvidenceFindTag",
    menu_item = items,
    main_foo = nil,
  }
end

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

---@param info MenuInfo
---@return MenuData
local function fuzzyFind(info)
  local res = model:fuzzyFind("", 50)
  --local items = {}
  --for _, v in ipairs(res) do
  --  table.insert(items, { name = v.name, foo = nil })
  --end
  local previewers = require("telescope.previewers")
  local putils = require("telescope.previewers.utils")
  local previewer = previewers.new_buffer_previewer({
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
          vim.api.nvim_command("call matchadd('EvidenceWord','" .. info.prompt .. "')")
        end)
      end)
    end,
  })
  local entry_maker = function(entry)
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

  local process_work = function(prompt, process_result, process_complete)
    local x = nil
    --	if now_search_mode == SearchMode.fuzzy then
    x = model:fuzzyFind(prompt, 50)
    --	elseif now_search_mode == SearchMode.min_due then
    --		x = model:getMinDueItem(50)
    --	end
    if type(x) ~= "table" then
      process_result(empty_maker(info.prompt))
      process_complete()
      return
    end
    for _, v in ipairs(x) do
      process_result(entry_maker(v))
    end
    process_complete()
  end
  return {
    prompt_title = "EvidenceFuzzyFind",
    menu_item = {},
    main_foo = nil,
    previewer = previewer,
    process_work = process_work,
  }
end

---@type SimpleMenu[]
local menuItem = {
  {
    name = "findTags",
    foo = findTag,
  },
  {
    name = "fuzzyFind",
    foo = fuzzyFind,
  },
}

---@param data ModelTableInfo
local function start(data)
  user_data = data
  setup()
  telescopeSimple.setup({ prompt_title = "EvidenceMainMenu", menu_item = menuItem, main_foo = nil })
end

return {
  start = start,
}
