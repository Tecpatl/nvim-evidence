local tools = require("evidence.util.tools")
local cmd = require("evidence.view.cmd")

local user_data = {
  uri = "~/.config/nvim/sql/v0",
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
  setup = function(data)
    user_data = data or user_data

    vim.api.nvim_create_user_command("EvidenceNormalCmd", function()
      cmd.startNormal()
    end, {
      nargs = 0,
    })

    vim.api.nvim_create_user_command("EvidenceFlush", function()
      cmd.flush(user_data)
    end, {
      nargs = 0,
    })

    local opts = { noremap = true, silent = true }
    keymap("v", user_data.key_map.visual_cmd, function()
      local text = tools.getVisualSelection()
      cmd.startVisual(text)
    end, opts)
  end,
}
