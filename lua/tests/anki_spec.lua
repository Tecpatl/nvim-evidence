local model = require("evidence.model.index")
local _ = require("evidence.model.fsrs_models")
local tools = require("evidence.util.tools")
local anki_data = require("evidence.tests.anki")

local eq = function(a, b)
  assert.are.same(a, b)
end

local data = {
  uri = "~/.config/nvim/sql/dev_tag",
  parameter = {
    request_retention = 0.7,
    maximum_interval = 100,
    easy_bonus = 1.0,
    hard_factor = 0.8,
    w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
  },
}

model:setup(data)

local reset = function(n)
  --local q = model:findAllCards(10)
  --print(vim.inspect(q))
  model:clear()
  local card_id
  local tag_id = model:addTag("toefl")
  for _, v in ipairs(anki_data) do
    card_id = model:addNewCard(v)
    model:insertCardTagById(card_id, tag_id)
  end
end

describe("fsrs_sql_model", function()
  it("reset", function()
    reset()
  end)
end)
