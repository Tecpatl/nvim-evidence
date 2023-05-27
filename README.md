# NVIM-EVIDENCE

## Status

under development

## Purpose

fsrs plugin for nvim

orgmode 适用于安排有风险不稳定的计划或短期任务. (指南针)

evidence 适用于确定待执行的长久稳定且需要重复记忆任务. (船桨)

## Reference

[free-spaced-repetition-scheduler](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler)

## Usage Scene

### Install && Setup (lazy for example) 

```lua
 {
     "Tecpatl/nvim-evidence",
         event = "VeryLazy",
         branch = "main",
         config = function()
             local user_data = {
                 uri = "~/.config/nvim/sql/v1",
                 all_table = {
                     table_name1 = {
                         request_retention = 0.9,
                         maximum_interval = 36500,
                         easy_bonus = 1.3,
                         hard_factor = 1.2,
                         w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
                     },
                     table_name2 = {},
                 },
                 now_table_id = "table_name1",
             }
             require("evidence").setup(user_data)
         end,
         dependencies = {
             "anuvyklack/hydra.nvim",
             "ouyangjunyi/sqlite.lua",
             "nvim-telescope/telescope.nvim"
         }
}
```

`<Leader>E` 启动hydra

### Hydra + Telescope

- a: add   将缓冲区内容添加到数据库

- x: start  开始学习, 弹出最新需要复习卡片

- d: del  删除当前卡片

- o: viewAnser 显示答案

- s: switchTable  切换 table

- e: edit  将缓冲区的内容更新到当前卡片里

- i: info  打印当前缓冲区卡片信息

- s: score  给当前卡片打分

- f: fuzzyFind  开启根据卡片内容的模糊搜索

- m: minFind  开启根据最近需要复习卡片的搜索

## Module

Models (FSRS, SqlTable)
Controller
Views (WinBuf, Telescope, Hydra)

## Todo

- 支持多 winbuf

- 撤销

- 自定义hydra 或者 将hydra 换成 modern search menu

- lru最近访问过的卡片

- record 统计

- tags

- 超前学习提示下
