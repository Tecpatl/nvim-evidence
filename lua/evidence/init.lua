local user_data = {
  uri = "~/.config/nvim/sql/v0",
  is_record = true,
  parameter = {
    request_retention = 0.7,
    maximum_interval = 100,
    easy_bonus = 1.0,
    hard_factor = 0.8,
    w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
  },
}

local function cmd() end

return {
  setup = function(data)
    user_data = data or user_data

    vim.api.nvim_create_user_command("EvidenceCmd", function()
      local cmd = require("evidence.view.cmd")
      cmd.start()
    end, {
      nargs = 0,
    })

    vim.api.nvim_create_user_command("EvidenceFlush", function()
      local cmd = require("evidence.view.cmd")
      cmd.flush(user_data)
    end, {
      nargs = 0,
    })
  end,
}
