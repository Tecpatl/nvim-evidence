
local model = require("evidence.model.index")
local _ = require("evidence.model.fsrs_models")
local tools = require("evidence.util.tools")

local data = {
  uri = "/root/.local/share/nvim/lazy/nvim-evidence/sql/test.db",
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

describe("table", function()
  it("alterFsrsInfo", function()
    local res=model:alterFsrsInfo()
    print(vim.inspect(res))
  end)
  it("insertColumn", function()
    --info()
    -- info()
   -- model:execute([[
   -- ALTER TABLE tag add column timestamp int default 0  
   -- ]])
    -- info()
  end)
end)
