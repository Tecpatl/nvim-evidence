local model = require("evidence.model.index")
local _ = require("evidence.model.fsrs_models")
local tools = require("evidence.util.tools")

local data = {
  --uri = "/root/mine/repos/web-evidence/master/prisma/test.db",
  uri = "/root/.local/share/nvim/lazy/nvim-evidence/sql/test.db",
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

describe("table", function()
  it("alterFsrsInfo", function()
    local res = model:alterFsrsInfo({
      due = 1699011173,
      info =
      [[{"stability":0,"due":1699011173,"state":0,"due_date":"2023-11-03 19:32:53","last_review_date":"2023-11-03 19:32:53","elapsed_days":0,"lapses":0,"reps":0,"difficulty":0,"scheduled_days":0}]],
    })
  --  print(vim.inspect(res))
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
