# NVIM-EVIDENCE

## Purpose

fsrs plugin for nvim

## Reference

[free-spaced-repetition-scheduler](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler)

evidence 适用于确定待执行的长久稳定且需要重复记忆任务. (船桨)

[nvim-orgmode](https://github.com/nvim-orgmode/orgmode)

orgmode 适用于安排有风险不稳定的计划或短期任务. (指南针)

## Usage Scene

### video 

- basic function:

  https://www.youtube.com/watch?v=taGRd-ZwwCU&t=602s

- tags and telescope:

  https://www.youtube.com/watch?v=SoCBgbiWhjw

### Install && Setup (lazy for example) 

```lua
 {
     "Tecpatl/nvim-evidence",
         event = "VeryLazy",
         branch = "main",
         config = function()
             local user_data = {
                uri = "~/sql/v1",
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
             require("evidence").setup(user_data)
         end,
         dependencies = {
             "kkharji/sqlite.lua",
             "nvim-telescope/telescope.nvim"
         }
}
```

`:EvidenceFlush` 重新打开刷新buffer

`:EvidenceCmd` 弹出搜索框

### 当前卡片card操作   

- addCard: 将缓冲区内容生成新卡片, 支持选中内容直接生成

- nextCard: 弹出下一个待处理卡片(30%新卡片,70%旧卡片), 如果有select_tags, 会在tags集合中选中下一个

- setNextCard: 设置全局nextCard模式（auto / review / new） 

- delCard: 删除多个卡片(第一项是当前卡片)

- answer: 显示答案

- editCard:  将缓冲区的内容更新到当前卡片里

- infoCard:  打印多个卡片信息(第一项是当前卡片)

- scoreCard:  给当前卡片打分

- findCard:  开启根据卡片内容的模糊搜索弹出作为当前卡片

- findReviewCard:  开启根据最近需要"复习"卡片且满足select_tags的搜索弹出作为当前卡片

- findNewCard:  开启新卡片且满足select_tags的搜索弹出作为当前卡片

- recordCard: 根据visit, insert, delete, edit 四个方式查看最近处理过的卡片

- setBufferList: 增删查管理多个winbuf

- refreshCard: 刷新卡片, 重置缓冲区修改内容

- addDivider: 对选中内容进行颜色遮盖, 模拟填空题

### 对tags操作 

- findTags:  开启根据tag name的模糊搜索

- findTagsByNowCard:  列表展示当前卡片所拥有的tags 

- addTagsForNowCard:  先展示出当前卡片拥有所有(非直系亲缘)tags, 支持多选添加, 并且如果没有匹配项自动生成一个新的, 个数限制

- delTagsForNowCard:  列表展示当前卡片拥有的tags, 支持多选删除 

- addTag:  全局添加一个tag

- renameTag:  全局修改一个tag名字

- delTags:  全局删除一些tag

- setSelectTags( And/Or ): telescope标题是当前已选tags, 然后可以设置全局选择的tags

- findCardBySelectTags( And/Or ): telescope标题是当前已选tags, 然后展示出所有满足tags要求cards

- tagTree: 展示tag间依赖关系

- convertTagFather: 修改tags的父节点指向

- mergeTag: 将指定tags合并到另一个tag中, 且删掉指定旧的tags

## Todo

- 统计复习过多少, 学了多少新的, 引入加了多少新卡

- 各种提示, 悬浮提示每个卡片的tag信息

- card如果希望关联到另一个card, 或尽量通过建立共同的tag实现

- 各种find带fuzzy(英文首字母简写)
