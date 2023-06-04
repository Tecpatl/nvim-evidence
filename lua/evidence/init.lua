local user_data = {
  uri = "~/.config/nvim/sql/v0",
  parameter = {
    request_retention = 0.7,
    maximum_interval = 100,
    easy_bonus = 1.0,
    hard_factor = 0.8,
    w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
  },
}

local function start()
  local menu = require("evidence.view.menu")
  menu.start(user_data)
end

return {
  setup = function(data)
    user_data = data or user_data

    vim.api.nvim_create_user_command("Evidence", function()
      start()
    end, {
      nargs = 0,
    })
  end,
}
