local tools = require("evidence.util.tools")
local Hydra = require("hydra")
local model = require("evidence.model.index")
local win_buf = require("evidence.view.win_buf")
local telescope = require("evidence.view.telescope")

---@type ModelTableInfo
local user_data = nil
local is_start_ = false

local function hint_list(name, list)
  local res = [[
  # ]] .. name .. [[


  ]]
  for id = 1, #list do
    res = res .. [[_]] .. id .. [[_: ]] .. list[id] .. [[

  ]]
  end
  res = res .. [[

  _<Esc>_: exit  _q_: exit
  ]]
  return res
end

local function WrapHydra(name, hint, heads)
  return Hydra({
    name = name,
    hint = hint,
    config = {
      timeout = 30000,
      color = "teal",
      invoke_on_body = true,
      hint = {
        position = "middle",
        border = "rounded",
      },
    },
    heads = tools.table_concat(heads, {
      { "q", nil, { exit = true, nowait = true, desc = "exit" } },
      { "<Esc>", nil, { exit = true, nowait = true } },
    }),
  })
end

local function WrapListHeads(list, func)
  local res = {}
  for i = 1, #list do
    local id = tostring(i)
    table.insert(res, {
      id,
      function()
        func(i)
      end,
    })
  end
  return res
end

local evidence_hint = [[
 _x_: start _s_: score _t_: switchTable
 _f_: fuzzyFind _m_: minFind
 _e_: edit _d_: delete _a_: add
 ^
     _<Esc>_: exit  _q_: exit
]]

---@param foo_name string
---@return boolean
local function confirmCheck(foo_name)
  local confirm = tools.uiInput(foo_name .. " to table_id:" .. user_data.now_table_id .. "  (y/n):", "")
  if confirm ~= "y" then
    print(foo_name .. " failed")
    return false
  end
  return true
end

local function setup()
  if is_start_ == true then
    return
  end
  is_start_ = true
  model:setup(user_data)
  win_buf:setup({})
  win_buf:openSplitWin()
end

local function next()
  local item = model:getMinDueItem(1)
  if item == nil then
    print("empty table")
    return
  end
  win_buf:viewContent(item[1])
end

local function start()
  setup()
  next()
end

local function checkScore(score)
  return score == 0 or score == 1 or score == 2 or score == 3
end

---@return CardItem
local function getNowItem()
  return win_buf:getInfo().item
end

local function score()
  if is_start_ == false then
    return
  end
  local rating = tonumber(tools.uiInput("score(0,1,2,3):", ""))
  if type(rating) ~= "number" or not checkScore(rating) then
    print("input format error (0,1,2,3)")
    return
  end
  print(rating)
  model:ratingCard(getNowItem().id, rating)
  next()
end

local function fuzzyFind()
  setup()
  telescope.find(telescope.SearchMode.fuzzy)
end

local function minFind()
  setup()
  telescope.find(telescope.SearchMode.min_due)
end

local function edit()
  if is_start_ == false then
    return
  end
  if not confirmCheck("editCard") then
    return
  end
  local content = vim.api.nvim_buf_get_lines(win_buf:getInfo().buf, 0, -1, false)
  local content_str = table.concat(content, "\n")
  local file_type = vim.bo.filetype
  if not file_type or file_type == "" then
    file_type = "markdown"
  end
  model:editCard(getNowItem().id, { content = content_str, file_type = file_type })
end

local function delete()
  if is_start_ == false then
    return
  end
  if not confirmCheck("delCard") then
    return
  end
  model:delCard(getNowItem().id)
  next()
end

local function switchTable()
  setup()
  local tables = model:getTableIds()
  local drillHeads = WrapListHeads(tables, function(id)
    local now_table_id = tables[id]
    model:switchTable(now_table_id)
    user_data.now_table_id = now_table_id
  end)
  local drill_hint = hint_list("drill table", tables)
  local drill_table_hydra = WrapHydra("drill_table_hydra", drill_hint, drillHeads)
  Hydra.activate(drill_table_hydra)
end

local function add()
  if is_start_ == false then
    return
  end
  if not confirmCheck("addCard") then
    return
  end
  local content = vim.api.nvim_buf_get_lines(win_buf:getInfo().buf, 0, -1, false)
  local content_str = table.concat(content, "\n")
  model:addNewCard(content_str)
end

---@param data ModelTableInfo
local setup = function(data)
  user_data = data
  Hydra({
    name = "Evidence",
    hint = evidence_hint,
    config = {
      timeout = 30000,
      color = "teal",
      invoke_on_body = true,
      hint = {
        position = "middle",
        border = "rounded",
      },
    },
    mode = "n",
    body = "<Leader>E",
    heads = {
      { "x", start },
      { "a", add },
      { "s", score },
      { "f", fuzzyFind },
      { "m", minFind },
      { "e", edit },
      { "d", delete },
      { "t", switchTable, { exit = true, nowait = true, desc = "exit" } },
      { "q", nil, { exit = true, nowait = true, desc = "exit" } },
      { "<Esc>", nil, { exit = true, nowait = true } },
    },
  })
end

return {
  setup = setup,
}
