function _G.requireSubPlugin(name)
	local status_ok, plugin = pcall(require, name)
	if not status_ok then
    print("error: " .. name)
		error(" 没有找到evidence子插件：" .. name)
		--vim.notify(" 没有找到插件：" .. name)
		--return nil
	end
	return plugin
end

local tools = requireSubPlugin("evidence.util.tools")
local cmd = requireSubPlugin("evidence.view.cmd")



---@class EvidenceParam
---@field uri string
---@field is_record boolean
---@field parameter Parameters
---@field key_map table
---@field pdf PdfField

local user_data_sample = {
  uri = "~/.config/nvim/sql/v0",
  pdf = {
    host = "",
  },
  is_record = true,
  key_map = {
    visual_cmd = "<leader>Ev",
  },
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
