local sql = require("sqlite.db")
local luv = require("luv")
local tools = require("evidence.util.tools")
local SqlTable = require("evidence.model.table")
local db = SqlTable:new()

describe("sqlite.db", function()
  local path = "~/sql/v2"
  db:setup({ uri = path })

  it("Insert", function()
    db:insertCard("card1", "asdf", 123, "markdown")
    db:insertCard("card2", "asdf", 123, "markdown")
    db:insertCard("card3", "asdf", 123, "markdown")
    db:insertTag("tag1")
    db:insertTag("tag2")
    db:insertTag("tag3")
    db:insertCardTag(1, 1)
    db:insertCardTag(1, 2)
    db:insertCardTag(2, 1)
    db:insertCardTag(2, 3)
    db:insertCardTag(3, 3)
    local q1 = db:findTagsByCard(2)
    print(vim.inspect(q1))
    local q2 = db:findCardsByTags({ 1, 2 }, false)
    local q3 = db:findCardsByTags({ 1, 2 }, true)
    print(vim.inspect(q2))
    print(vim.inspect(q3))
  end)

  it("Update", function() end)

  db:close()
end)
