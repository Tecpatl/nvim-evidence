# NVIM-EVIDENCE

## Purpose

fsrs plugin for nvim

## Reference

[free-spaced-repetition-scheduler v4](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler)

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
                request_retention = 0.9,
                maximum_interval = 36500,
                w = { 0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01, 1.49, 0.14, 0.94, 2.18, 0.05, 0.34, 1.26, 0.29, 2.61},
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

## Other Version

[Web-Evidence](https://github.com/Tecpatl/web-evidence)

## Todo

- 各种提示, 悬浮提示每个卡片的tag信息

- 各种find带fuzzy(英文首字母简写)

## Test

bash ./scripts/test.sh -f xxx_spec.lua
