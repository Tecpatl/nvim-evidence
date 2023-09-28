local model = require("evidence.model.index")
local _ = require("evidence.model.fsrs_models")
local tools = require("evidence.util.tools")

local data = {
  uri = "~/.config/nvim/sql/evidence.db",
  is_record = false,
  parameter = {
    request_retention = 0.7,
    maximum_interval = 100,
    easy_bonus = 1.0,
    hard_factor = 0.8,
    w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
  },
}

model:setup(data)

local info = function(n)
  local info = model:findAllTags()
  print(vim.inspect(info))
end

local addCard = function(content, tag_id)
  if tag_id == -1 then
    error("tag_id empty")
  end
  local card_id = model:addNewCard(content, "markdown")
  model:insertCardTagById(card_id, tag_id)
end

local tranverse = function(directory, tag_id)
  local dir = io.popen('find "' .. directory .. '" -type f')
  if dir then
    for file in dir:lines() do
      print(file)
      local pfile = io.open(file)
      if pfile then
        local content = pfile:read("*a")
        --print(vim.inspect(content))
        addCard(content, tag_id)
        pfile:close()
      end
    end
    dir:close()
  else
    error("directory not exist")
  end
end

describe("directory", function()
  it("all_tags", function()
    info()
  end)
  it("tranverse", function()
    --------------------------
    --------------------------
    local tag_id = -1
    local directory = ""
    --------------------------
    --------------------------
    if directory == "" then
      error("directory empty")
    end
    if tag_id == -1 then
      error("tag_id empty")
    end
    tranverse(directory, tag_id)
  end)
end)
