local tools = require("evidence.util.tools")
local cmd = require("evidence.view.cmd")

---@class EvidenceParam
---@field uri string
---@field is_record boolean
---@field parameter Parameters
---@field key_map table
---@field pdf PdfField

local user_data_sample = {
  uri = "~/.config/nvim/sql/v0",
  pdf = {
    host = ""
  },
  is_record = true,
  key_map = {
    visual_cmd = "<leader>Ev",
  },
  parameter = {
    request_retention = 0.7,
    maximum_interval = 100,
    easy_bonus = 1.0,
    hard_factor = 0.8,
    w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
  },
}

local keymap = vim.keymap.set

return {
  ---@param data EvidenceParam
  setup = function(data)
    if data == nil or data == {} then
      error("evidence not setup")
    end
    if not tools.file_exists(data.uri) then
      return
    end
    cmd:setup({
      uri = data.uri,
      pdf = data.pdf,
      is_record = data.is_record,
      parameter = data.parameter,
    })

    vim.api.nvim_create_user_command("EvidenceNormalCmd", function()
      cmd:startNormal()
    end, {
      nargs = 0,
    })

    vim.api.nvim_create_user_command("EvidenceFlush", function()
      cmd:flush()
    end, {
      nargs = 0,
    })

    local opts = { noremap = true, silent = true }
    keymap("v", data.key_map.visual_cmd, function()
      local text = tools.getVisualSelection()
      cmd:startVisual(text)
    end, opts)
  end,
}
