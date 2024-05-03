local model = requireSubPlugin("evidence.model.index")
local _ = requireSubPlugin("evidence.model.fsrs_models")
local tools = requireSubPlugin("evidence.util.tools")

local data = {
  uri = "~/.config/nvim/sql/evidence.db",
  is_record = false,
  parameter = {
    request_retention = 0.9,
    maximum_interval = 36500,
    w = {
      0.4,
      0.6,
      2.4,
      5.8,
      4.93,
      0.94,
      0.86,
      0.01,
      1.49,
      0.14,
      0.94,
      2.18,
      0.05,
      0.34,
      1.26,
      0.29,
      2.61,
    },
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
