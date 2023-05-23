local hydra = require("evidence.view.hydra")

local user_data = {
  uri = "~/.config/nvim/sql/v2",
  all_table = {
    t1 = {},
    t2 = {
      request_retention = 0.7,
      maximum_interval = 100,
      easy_bonus = 1.0,
      hard_factor = 0.8,
      w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
    },
  },
  now_table_id = "t1",
}

local command_list = {
  init = function()
    hydra.setup(user_data)
  end,
}

local function complete_key()
  local keys = {}
  for key, _ in pairs(command_list) do
    table.insert(keys, key)
  end
  return keys
end

local function work(arg)
  local command = command_list[arg]
  if command == nil then
    print("not match command for spectre")
    return
  end
  command()
end

return {
  setup = function(data)
    user_data = data or user_data

    hydra.setup(user_data)

    -- TODO cmd start
    --vim.api.nvim_create_user_command("Evidence", function(tb1)
    --  work(tb1.args)
    --end, {
    --  nargs = 1,
    --  complete = function(ArgLead, CmdLine, CursorPos)
    --    return complete_key()
    --  end,
    --})
  end,
}
