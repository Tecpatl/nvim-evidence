local model = require("evidence.model.index")
local _ = require("evidence.model.fsrs_models")
local tools = require("evidence.util.tools")

local eq = function(a, b)
  assert.are.same(a, b)
end

local data = {
  uri = "~/sql/v4",
  parameter = {
    request_retention = 0.7,
    maximum_interval = 100,
    easy_bonus = 1.0,
    hard_factor = 0.8,
    w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
  },
}

model:setup(data)

local lim = 3

local reset = function(n)
  model:clear()
  n = n or lim
  for i = 1, n do
    model:addNewCard("* mock" .. i .. "abc")
  end
  return n
end

describe("card", function()
  it("info", function()
    local info = model:getAllInfo()
    --print(vim.inspect(info))
  end)
  it("add_del", function()
    local n = 10
    reset(n)
    local data = model:findAll()
    assert(data ~= nil)
    eq(n, #data)
    for i = 1, n - 1 do
      model:delCard(data[i].id)
    end
    data = model:findAll()
    eq(1, #data)
  end)
  it("findById", function()
    reset(3)
    local ret = model:findById(1)
    assert(ret ~= nil)
    eq(1, ret.id)
  end)
  it("editById", function()
    reset()
    local content = "xx"
    local ret = model:editCard(1, { content = content })
    local obj = model:findById(1)
    assert(obj ~= nil)
    eq(content, obj.content)
  end)
  it("ratingCard", function()
    reset(1)
    local data = model:findAll()
    tools.printDump(data)
    model:ratingCard(1, _.Rating.Again, os.time() + 5 * 24 * 60 * 60)
    data = model:findAll()
    tools.printDump(data)
  end)
  it("min", function()
    local item = model:getMinDueItem(1)
    print(vim.inspect(item))
  end)
  it("reset", function()
    reset(100)
  end)
end)
