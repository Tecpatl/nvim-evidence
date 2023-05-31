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

local function del()
  print("del")
end

local function findTags()
  local res = model:findTag()
  print(vim.inspect(res))
  local items = {}
  for _, v in ipairs(res) do
    table.insert(items, { name = v.name, foo = nil })
  end
  return {
    prompt_title = "EvidenceFindTags",
    menu_item = items,
    main_foo = nil,
  }
end

---@type SimpleMenu[]
local menuItem = {
  {
    name = "findTags",
    foo = findTags,
  },
  {
    name = "add",
    foo = add,
  },
  {
    name = "del",
    foo = del,
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
