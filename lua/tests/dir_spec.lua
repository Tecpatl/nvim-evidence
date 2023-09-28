--local lazypath = vim.fn.stdpath("data") .. "/lazy"
--vim.notify = print
--vim.opt.rtp:append(".")
--vim.opt.rtp:append(lazypath .. "/nvim-treesitter")
--vim.opt.rtp:append(lazypath .. "/sqlite.lua")
----vim.opt.rtp:append(lazypath .. "/hydra.nvim")
--vim.opt.rtp:append(lazypath .. "/telescope.nvim")

--require "lua.tests.minimal_init"

print(vim.inspect(vim.opt.rtp))

local sqlite = require("sqlite")
local tele = require("telescope")

print(vim.inspect(sqlite))
print(vim.inspect(tele))


--local model = require("evidence.model.index")
--local _ = require("evidence.model.fsrs_models")
--local tools = require("evidence.util.tools")
--
--local data = {
--  uri = "~/.config/nvim/sql/evidence.db",
--  is_record = false,
--  parameter = {
--    request_retention = 0.7,
--    maximum_interval = 100,
--    easy_bonus = 1.0,
--    hard_factor = 0.8,
--    w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
--  },
--}
--
--model:setup(data)
--
--local info = function(n)
--  local info = model:getAllInfo()
--  print(vim.inspect(info))
--end

describe("directory", function()
  it("info", function()
    --info()
    print("asdf")
  end)
end)
