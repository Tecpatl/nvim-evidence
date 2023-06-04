# NVIM-EVIDENCE

## Status

under development

## Purpose

fsrs plugin for nvim

orgmode 适用于安排有风险不稳定的计划或短期任务. (指南针)

evidence 适用于确定待执行的长久稳定且需要重复记忆任务. (船桨)

## Reference

[free-spaced-repetition-scheduler](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler)

[nvim-orgmode](https://github.com/nvim-orgmode/orgmode)

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

`<leader>E` 弹出搜索框

### 当前卡片card操作   

- addCard: 将缓冲区内容生成新卡片

- nextCard: 弹出下一个待处理卡片(30%新卡片,70%旧卡片), 如果有select_tags, 会在tags集合中选中下一个

- nextNewCard: 弹出最新需要复习卡片, 如果有select_tags, 会在tags集合中选中下一个

- nextReviewCard: 弹出新卡片, 如果有select_tags, 会在tags集合中选中下一个

- delCard: 删除多个卡片(第一项是当前卡片)

- answer: 显示答案

- editCard:  将缓冲区的内容更新到当前卡片里

- infoCard:  打印多个卡片信息(第一项是当前卡片)

- scoreCard:  给当前卡片打分

- findCard:  开启根据卡片内容的模糊搜索弹出作为当前卡片

- findReviewCard:  开启根据最近需要"复习"卡片且满足select_tags的搜索弹出作为当前卡片

- findNewCard:  开启新卡片且满足select_tags的搜索弹出作为当前卡片

### 对tags操作 

- findTags:  开启根据tag name的模糊搜索

- findTagsByNowCard:  列表展示当前卡片所拥有的tags 

- addTagsForNowCard:  先展示出当前卡片拥有所有(todo非直系亲缘)tags, 支持多选添加, 并且如果没有匹配项自动生成一个新的, 个数限制

- delTagsForNowCard:  列表展示当前卡片拥有的tags, 支持多选删除 

- addTag:  全局添加一个tag

- renameTag:  全局修改一个tag名字

- delTags:  全局删除一些tag

- setSelectTags( And/Or ): telescope标题是当前已选tags, 然后可以设置全局选择的tags

- findCardBySelectTags( And/Or ): telescope标题是当前已选tags, 然后展示出所有满足tags要求cards

- findFather: 打印父tags 

- findSon: 打印子tags

## Todo

- 支持多 winbuf

- 撤销

- record 统计

- 超前学习提示下
