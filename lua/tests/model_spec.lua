local model = requireSubPlugin("evidence.model.index")
local _ = requireSubPlugin("evidence.model.fsrs_models")
local tools = requireSubPlugin("evidence.util.tools")

local eq = function(a, b)
  assert.are.same(a, b)
end

local data = {
  --uri = "~/sql/v4",
  uri = "",
  is_record = true,
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
  it("findCardById", function()
    reset(3)
    local ret = model:findCardById(1)
    assert(ret ~= nil)
    eq(1, ret.id)
  end)
  it("editById", function()
    reset()
    local content = "xx"
    local ret = model:editCard(1, { content = content })
    local obj = model:findCardById(1)
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
    q = model:findIncludeTagsByCard(2)
    --print(vim.inspect(q))
  end)
  --it("mock", function()
  --  reset_tags(10)
  --end)
  it("record_card", function()
    reset_tags(15)
    model:delCard(1)
    model:editCard(2, { content = "123" })
    model:delCard(3)
    local cards = model:findRecordCard({})
    print(vim.inspect(cards))
  end)
end)
