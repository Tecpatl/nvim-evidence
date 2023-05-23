local model = require("evidence.model.index")
local _ = require("evidence.model.fsrs_models")
local tools = require("evidence.util.tools")
local anki_data = require("evidence.tests.anki")

local eq = function(a, b)
  assert.are.same(a, b)
end

local data = {
  uri = "~/.config/nvim/sql/v2",
  all_table = {
    toefl = {},
  },
  now_table_id = "toefl",
}

model:setup(data)

local reset = function(n)
  model:clear()
  for _, v in ipairs(anki_data) do
    model:addNewCard(v)
  end
end

describe("fsrs_sql_model", function()
  it("reset", function()
    reset()
  end)
end)
