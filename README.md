# NVIM-EVIDENCE

## Purpose

fsrs plugin for nvim

## Reference

[free-spaced-repetition-scheduler](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler)

## Usage Scene

### Install && Setup (lazy for example)

```lua
 {
	"Tecpatl/nvim-evidence",
	event = "VeryLazy",
	branch = "master",
	config = function()
		local nvim_rocks = require("nvim_rocks")
		nvim_rocks.ensure_installed("lua-iconv")
		nvim_rocks.ensure_installed("fun")
		nvim_rocks.ensure_installed("lua-cjson")

		local evidence = require("evidence")
		evidence.setup({
            uri = "/root/.config/nvim/sql/evidence.db",
            is_record = true,
            parameter = {
                request_retention = 0.7,
                maximum_interval = 100,
                easy_bonus = 1.0,
                hard_factor = 0.8,
                w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
            },
        })
	end,
	dependencies = {
		{
			"theHamsta/nvim_rocks",  -- luarocks require
		},
		{
			"nvim-telescope/telescope.nvim",
		},
		{
			"ouyangjunyi/sqlite.lua",
		},
	},
}
```

`:EvidenceFlush` 重新打开刷新buffer

`:EvidenceCmd` 弹出搜索框

## Todo

- 各种提示, 悬浮提示每个卡片的tag信息

- 各种find带fuzzy(英文首字母简写)

## Test

bash ./scripts/test.sh -f xxx_spec.lua
