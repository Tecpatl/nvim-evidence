local model = require("evidence.model.index")
local _ = require("evidence.model.fsrs_models")
local tools = require("evidence.util.tools")

local eq = function(a, b)
  assert.are.same(a, b)
end

local data = {
  --uri = "~/sql/v4",
  uri = "",
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
    model:addNewCard("# mock" .. i .. "\n\n ## answer \n\n" .. i .. "abc")
  end
  return n
end

local reset_tags_no_insert = function(n)
  if n == nil or n < 8 then
    n = 8
  end
  reset(n)
  for i = 1, n do
    model:addTag("tag_" .. i)
  end
  model:convertFatherTag({ 2, 3 }, 1)
  model:convertFatherTag({ 4, 5 }, 2)
  model:convertFatherTag({ 6, 7 }, 3)
end

local reset_tags = function(n)
  reset_tags_no_insert(n)
  model:insertCardTagById(1, 1)
  model:insertCardTagById(2, 2)
  model:insertCardTagById(2, 6)
  model:insertCardTagById(3, 3)
  model:insertCardTagById(3, 4)
  model:insertCardTagById(3, 5)
end

describe("card", function()
  it("info", function()
    local info = model:getAllInfo()
    --print(vim.inspect(info))
  end)
  it("add_del", function()
    local n = 10
    reset(n)
    local data = model:findAllCards()
    assert(data ~= nil)
    eq(n, #data)
    for i = 1, n - 1 do
      model:delCard(data[i].id)
    end
    data = model:findAllCards()
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
    local data = model:findAllCards()
    --tools.printDump(data)
    model:ratingCard(1, _.Rating.Again, os.time() + 5 * 24 * 60 * 60)
    data = model:findAllCards()
    --tools.printDump(data)
  end)
end)

describe("tag", function()
  it("add_del_Tag", function()
    reset_tags_no_insert(8)
    model:insertCardTagById(1, 4)
    model:insertCardTagById(1, 6)
    local q = model:findIncludeTagsByCard(1)
    q = model:findExcludeTagsByCard(1)
    --print(vim.inspect(q))

    --model:insertCardTagByName(1, "x")
    --q = model:findIncludeTagsByCard(1)
    --print(vim.inspect(q))

    model:delCardTag(1, 4)
    q = model:findIncludeTagsByCard(1)
    model:insertCardTagById(1, 4)
    model:insertCardTagById(2, 4)
    model:insertCardTagById(2, 6)
    model:insertCardTagById(2, 8)
    model:insertCardTagById(3, 4)
    --print(vim.inspect(q))
    q = model:findCardBySelectTags({ 4, 6 }, true, false, -1)
    --print(vim.inspect(q))
    q = model:findCardBySelectTags({ 4, 3 }, false, true, -1)
    --print(vim.inspect(q))
    model:ratingCard(2, _.Rating.Again, os.time() + 5 * 24 * 60 * 60)
    q = model:getMinDueItem({ 2, 3 }, false, true, -1)
    --print(vim.inspect(q))
  end)
  it("merge_tag", function()
    local n = 8
    reset_tags_no_insert(n)

    model:insertCardTagById(1, 4)
    model:insertCardTagById(2, 4)
    model:insertCardTagById(2, 6)
    model:insertCardTagById(2, 8)
    model:insertCardTagById(3, 4)

    model:mergeTags({ 2, 6 }, 8)

    local q = model:findAllTags()
    --print(vim.inspect(q))
  end)
  it("mock", function()
    reset_tags()
  end)
end)
