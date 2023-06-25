local tools = require("evidence.util.tools")
local set = require("evidence.util.set")
local tblInfo = require("evidence.model.info")
local action_state = require("telescope.actions.state")
local telescopeMenu = require("evidence.view.telescope")

--- @alias NextCardMode integer
local NextCardMode = {
  auto = 0,
  review = 1,
  new = 2,
  rand = 3,
}

---@class SelectRegion
---@field startRow number
---@field startCol number
---@field endRow number
---@field endCol number

---@class Menu
---@field select_region SelectRegion
---@field now_buf_id number
---@field now_win_id number
---@field tbl SqlTable
---@field select_tags number[]
---@field is_select_tag_and boolean
---@field next_card_mode NextCardMode
---@field is_mapping_convert boolean
---@field is_mapping_merge boolean
---@field tag_tree_exclude_ids table
---@field convert_tag_son_id number
---@field merge_tag_son_id number
---@field suggest_tag_ids number[]
---@field win_buf WinBuf
---@field model Model
---@field helper MenuHelper
---@field telescope_menu TelescopeMenu
local Menu = {}

Menu.__index = function(self, key)
  local value = rawget(Menu, key)
  if key ~= "setup" then
    if not self.is_setup then
      error("Class not initialized. Please call setup() first.", 2)
    end
  end
  return value
end

Menu.__newindex = function()
  error("Attempt to modify a read-only table")
end

---@return Menu
function Menu:getInstance()
  if not self.instance then
    self.instance = setmetatable({
      now_buf_id = -1,
      select_region = {},
      now_win_id = -1,
      is_setup = false,
      select_tags = {},
      is_select_tag_and = true,
      next_card_mode = NextCardMode.auto,
      is_mapping_convert = false,
      is_mapping_merge = false,
      tag_tree_exclude_ids = {},
      convert_tag_son_id = -1,
      merge_tag_son_id = -1,
      win_buf = {},
      model = {},
      helper = require("evidence.view.menu_helper"),
      telescope_menu = telescopeMenu:new(),
      suggest_tag_ids = {},
    }, self)
  end
  return self.instance
end

---@class MenuProps
---@field winBuf WinBuf
---@field model Model

---@param data MenuProps
function Menu:setup(data)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  self.win_buf = data.winBuf
  self.model = data.model
  self.helper:setup(self.model)
end

function Menu:selectTagNameStr()
  local res = ""
  if self.select_tags ~= {} then
    local status_msg = "AND"
    if self.is_select_tag_and == false then
      status_msg = "OR"
    end
    local tags = self.model:findTagByIds(self.select_tags)
    if tags ~= nil then
      res = status_msg .. " current:" .. tools.array2Str(tags, "name")
    end
  end
  return res
end

function Menu:nextCard()
  local items = nil
  if self.next_card_mode == NextCardMode.auto then
    items = self.helper:calcNextList(self.select_tags, self.is_select_tag_and)
  elseif self.next_card_mode == NextCardMode.review then
    items = self.model:getMinDueItem(self.select_tags, self.is_select_tag_and, true, 1)
  elseif self.next_card_mode == NextCardMode.new then
    items = self.model:getNewItem(self.select_tags, self.is_select_tag_and, true, 1)
  elseif self.next_card_mode == NextCardMode.rand then
    items = self.model:getRandomItem(self.select_tags, self.is_select_tag_and, true, 1)
  end

  if items == nil then
    print("empty table")
    return
  end
  local item = items[1]
  self.win_buf:viewContent(self.now_buf_id, item)
end

function Menu:setNextCard()
  local items = {}
  for k, v in pairs(NextCardMode) do
    table.insert(items, {
      name = k,
      foo = function()
        self.next_card_mode = v
      end,
    })
  end
  return {
    prompt_title = "Evidence setNextCard",
    menu_item = items,
    main_foo = nil,
  }
end

---@return CardItem
function Menu:getNowItem()
  return self.win_buf:getNowInfo(self.now_buf_id).item
end

---@class BufferHelper
---@field id number
---@field name string
---@field foo function

---@return TelescopeMenu
function Menu:setBufferList()
  local info = self.win_buf:getAllInfo()
  local items = {}
  for k, v in pairs(info) do
    table.insert(items, {
      info = {
        id = v.buf,
      },
      name = v.name,
      foo = function()
        local info = self.win_buf:remainOne()
        self.win_buf:openSplitWin(info.win_id, { v.buf })
        if info.buf_id ~= v.buf then
          self.win_buf:closeBufId(info.buf_id)
        end
      end,
    })
  end
  return {
    prompt_title = "Evidence setBufferList",
    menu_item = {},
    main_foo = function(value)
      local typename = type(value)
      if typename == "table" then
        local buf_ids = {}
        for _, item in pairs(value) do
          table.insert(buf_ids, item.info.id)
        end
        local info = self.win_buf:remainOne()
        self.win_buf:openSplitWin(info.win_id, buf_ids)
        if not tools.isInTable(info.buf_id, buf_ids) then
          self.win_buf:closeBufId(info.buf_id)
        end
      end
    end,
    previewer = self.helper:createBasicPreviewer({}),
    process_work = self.helper:createBufferProcessWork(items),
    custom_mappings = {
      ["i"] = {
        --- keymap help
        ["<c-h>"] = function()
          print("<c-d>:delBuffer <c-e>:addNewEmptyBuffer")
        end,
        ["<c-e>"] = function(prompt_bufnr)
          self.win_buf:createSplitWin(self.now_win_id) -- will close telescope while create new win
        end,
        ["<c-d>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          self.win_buf:delete(v.id)
          local res = self:setBufferList()
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
      },
    },
  }
end

---@return TelescopeMenu
function Menu:fuzzyFindCard()
  local foo = function(prompt)
    return self.model:fuzzyFindCard(prompt, 50)
  end
  return {
    prompt_title = "Evidence FuzzyFindCard",
    menu_item = {},
    main_foo = nil,
    previewer = self.helper:createCardPreviewer(),
    process_work = self.helper:createCardProcessWork(self.now_buf_id, foo),
  }
end

function Menu:delCard()
  if not tools.confirmCheck("delCard") then
    return
  end
  self.model:delCard(self:getNowItem().id)
  self:nextCard()
end

function Menu:hidden()
  self.win_buf:switchFold(self.now_buf_id, true)
end

function Menu:answer()
  self.win_buf:switchFold(self.now_buf_id, false)
end

function Menu:editCard()
  if not tools.confirmCheck("editCard") then
    return
  end
  local buf_id = self.win_buf:getNowInfo(self.now_buf_id).buf
  local content = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  local content_str = table.concat(content, "\n")
  local file_type = vim.api.nvim_buf_get_option(buf_id, "filetype")
  if not file_type or file_type == "" then
    file_type = "markdown"
  end
  self.model:editCard(self:getNowItem().id, { content = content_str, file_type = file_type })
  local item = self.model:getItemById(self:getNowItem().id)
  self.win_buf:viewContent(self.now_buf_id, item)
end

function Menu:infoCard()
  local card = self:getNowItem().card
  tools.printDump(card)
end

function Menu:scoreCard()
  local rating = tonumber(tools.uiInput("scoreCard(0,1,2,3):", ""))
  if type(rating) ~= "number" or not self.helper:checkScore(rating) then
    print("input format error (0,1,2,3)")
    return
  end
  --print(rating)
  self.model:ratingCard(self:getNowItem().id, rating)
  self:nextCard()
end

---@return TelescopeMenu
function Menu:addTag()
  local res = self.model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        foo = function()
          print("please add a tag not exist")
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence addTag",
    menu_item = items,
    main_foo = function(value)
      local typename = type(value)
      if typename == "string" then
        if not tools.confirmCheck("addTag") then
          return
        end
        self.model:addTag(value)
      else
        print("please add a tag not exist")
      end
    end,
  }
end

function Menu:setTagsForNowCardMain()
  self.suggest_tag_ids = {}
  local card_id = self:getNowItem().id
  local now_tag_tree_exclude_ids = self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id))
  return self:setTagsForNowCardTree(-1, now_tag_tree_exclude_ids, true)
end

---@param card_id number
---@return string
function Menu:tagsNameInCardStr(card_id)
  local tag_items = self.model:findIncludeTagsByCard(card_id)
  return tools.array2Str(tag_items, "name")
end

---@param now_tag_tree_exclude_ids number[]
---@param is_add_mode boolean
function Menu:setTagsForNowCardList(now_tag_tree_exclude_ids, is_add_mode)
  local card_id = self:getNowItem().id
  local all_items = self.model:findAllTags()
  if all_items == nil then
    return
  end
  local items = {}
  for _, v in ipairs(all_items) do
    local ret = tools.isInTable(v.id, now_tag_tree_exclude_ids)
    if is_add_mode then
      ret = not ret
    end
    if ret then
      table.insert(items, {
        name = v.name,
        info = { id = v.id, name = v.name },
        foo = nil,
      })
    end
  end
  local mode_str = "del_mode"
  if is_add_mode then
    mode_str = "add_mode"
  end
  return {
    prompt_title = "Evidence setTagsForNowCardList (" .. mode_str .. ")" .. self:tagsNameInCardStr(card_id),
    menu_item = items,
    --- addTag
    main_foo = function(prompt)
      if not tools.confirmCheck("setTagsForNowCardList") then
        return
      end
      local tag_id = self.model:addTag(prompt)
      local ret = self.model:insertCardTagById(card_id, tag_id)
      if ret == false then
        print("insertCardTagById failed")
        return
      end
      print("setTagsForNowCardList new tag name:" .. prompt)
      now_tag_tree_exclude_ids = self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id, true))
      return self:setTagsForNowCardList(now_tag_tree_exclude_ids, is_add_mode)
    end,
    custom_mappings = {
      ["i"] = {
        --- keymap help
        ["<c-h>"] = function()
          print(
            "<c-x>:setTagsForNowCardTree <c-l>:setTreeAutoLocation <c-e>:addTagsForNowCard <c-d>:delTagsForNowCard <c-v>:replaceWithSuggestion"
          )
        end,
        --- replace with suggestion tags
        ["<c-v>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          if self.suggest_tag_ids == {} then
            print("suggest_tag_ids empty")
            return
          end
          local tagItems = self.model:findTagByIds(self.suggest_tag_ids)
          if tagItems == nil then
            error("findTagByIds")
          end
          if not tools.confirmCheck(
            "replaceWithSuggestion:" .. tools.array2Str(tools.getValArrayFromItem(tagItems, "name"))
          )
          then
            return
          end
          self.model:delCardAllTag(card_id)
          for _, v in ipairs(tagItems) do
            local ret = self.model:insertCardTagById(card_id, v.id)
            if ret == false then
              print("insertCardTagById failed")
              return
            end
          end
          now_tag_tree_exclude_ids =
          self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id, true))
          local res = self:setTagsForNowCardList(now_tag_tree_exclude_ids, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- convert tree auto location
        ["<c-l>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          now_tag_tree_exclude_ids = self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id))
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          local res = self:setTagsForNowCardTree(v.id, now_tag_tree_exclude_ids, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- convert tree
        ["<c-x>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          now_tag_tree_exclude_ids = self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id))
          local res = self:setTagsForNowCardTree(-1, now_tag_tree_exclude_ids, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- addTagsForNowCard
        ["<c-e>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          if is_add_mode == false then
            now_tag_tree_exclude_ids =
            self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id, true))
            local res = self:setTagsForNowCardList(now_tag_tree_exclude_ids, true)
            self.telescope_menu:flushResult(res, picker, prompt_bufnr)
            return
          end
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          if not tools.confirmCheck("setTagsForNowCardList") then
            return
          end
          local single = select_item.value
          local v = single.info
          local ret = self.model:insertCardTagById(card_id, v.id)
          if ret == false then
            print("insertCardTagById failed")
            return
          end
          now_tag_tree_exclude_ids =
          self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id, true))
          local res = self:setTagsForNowCardList(now_tag_tree_exclude_ids, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- delTagsForNowCard
        ["<c-d>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          if is_add_mode then
            now_tag_tree_exclude_ids = self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id))
            local res = self:setTagsForNowCardList(now_tag_tree_exclude_ids, false)
            self.telescope_menu:flushResult(res, picker, prompt_bufnr)
            return
          end
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          self.model:delCardTag(card_id, v.id)
          now_tag_tree_exclude_ids = self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id))
          local res = self:setTagsForNowCardList(now_tag_tree_exclude_ids, false)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
      },
    },
  }
end

---@param now_tag_id number
---@param now_tag_tree_exclude_ids number[]
---@param is_add_mode boolean
function Menu:setTagsForNowCardTree(now_tag_id, now_tag_tree_exclude_ids, is_add_mode)
  local card_id = self:getNowItem().id
  local son_tags = self.model:findSonTags(now_tag_id)
  local items = {}
  if now_tag_id ~= -1 then
    local now_tag = self.model:findTagById(now_tag_id)
    if now_tag == nil then
      error("setTagsForNowCardTree findTagById")
    end
    table.insert(items, {
      name = "[father] " .. now_tag.name,
      info = { id = now_tag.id, name = now_tag.name },
      foo = function()
        return self:setTagsForNowCardTree(now_tag.father_id, now_tag_tree_exclude_ids, is_add_mode)
      end,
    })
  end
  --print(vim.inspect(son_tags))
  if type(son_tags) == "table" then
    for _, v in ipairs(son_tags) do
      local ret = tools.isInTable(v.id, now_tag_tree_exclude_ids)
      if is_add_mode then
        ret = not ret
      end
      if ret then
        table.insert(items, {
          name = v.name,
          info = { id = v.id, name = v.name },
          foo = function()
            return self:setTagsForNowCardTree(v.id, now_tag_tree_exclude_ids, is_add_mode)
          end,
        })
      end
    end
  end
  local mode_str = "del_mode"
  if is_add_mode then
    mode_str = "add_mode"
  end
  return {
    prompt_title = "Evidence setTagsForNowCardTree (" .. mode_str .. ")" .. self:tagsNameInCardStr(card_id),
    menu_item = items,
    --- addTag
    main_foo = function(prompt)
      if not tools.confirmCheck("setTagsForNowCardTree") then
        return
      end
      local tag_id = self.model:addTag(prompt)
      self.model:convertFatherTag({ tag_id }, now_tag_id)
      local ret = self.model:insertCardTagById(card_id, tag_id)
      if ret == false then
        print("insertCardTagById failed")
        return
      end
      print("setTagsForNowCardTree new tag name:" .. prompt)
      now_tag_tree_exclude_ids = self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id))
      return self:setTagsForNowCardTree(now_tag_id, now_tag_tree_exclude_ids, is_add_mode)
    end,
    custom_mappings = {
      ["i"] = {
        --- keymap help
        ["<c-h>"] = function(prompt_bufnr)
          print(
            "<c-x>:setTagsForNowCardList <c-e>:addTagsForNowCard <c-d>:delTagsForNowCard <c-v>:replaceWithSuggestion"
          )
        end,
        --- replace with suggestion tags
        ["<c-v>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          if self.suggest_tag_ids == {} then
            print("suggest_tag_ids empty")
            return
          end
          local tagItems = self.model:findTagByIds(self.suggest_tag_ids)
          if tagItems == nil then
            error("findTagByIds")
          end
          if not tools.confirmCheck(
            "replaceWithSuggestion:" .. tools.array2Str(tools.getValArrayFromItem(tagItems, "name"))
          )
          then
            return
          end
          self.model:delCardAllTag(card_id)
          for _, v in ipairs(tagItems) do
            local ret = self.model:insertCardTagById(card_id, v.id)
            if ret == false then
              print("insertCardTagById failed")
              return
            end
          end
          now_tag_tree_exclude_ids = self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id))
          local res = self:setTagsForNowCardTree(now_tag_id, now_tag_tree_exclude_ids, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- convert list
        ["<c-x>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          now_tag_tree_exclude_ids =
          self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id, true))
          local res = self:setTagsForNowCardList(now_tag_tree_exclude_ids, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        ["<c-e>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          if is_add_mode == false then
            local res = self:setTagsForNowCardTree(now_tag_id, now_tag_tree_exclude_ids, true)
            self.telescope_menu:flushResult(res, picker, prompt_bufnr)
            return
          end
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          if not tools.confirmCheck("setTagsForNowCardTree") then
            return
          end
          local ret = self.model:insertCardTagById(card_id, v.id)
          if ret == false then
            print("insertCardTagById failed")
            return
          end
          print("setTagsForNowCardTree tag name:" .. v.name)

          now_tag_tree_exclude_ids = self.model:getIdsFromItem(self.model:findIncludeTagsByCard(card_id))
          local res = self:setTagsForNowCardTree(now_tag_id, now_tag_tree_exclude_ids, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- delSelectTag
        ["<c-d>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local res = self:setTagsForNowCardList(now_tag_tree_exclude_ids, false)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
      },
    },
  }
end

---@param content_str string
---@param file_type? string
function Menu:addCardSplit(content_str, file_type)
  if not tools.confirmCheck("addCardSplit") then
    return
  end
  local father_card_id = self:getNowItem().id
  local father_tags = self.model:findIncludeTagsByCard(father_card_id)
  self.suggest_tag_ids = tools.getValArrayFromItem(father_tags, "id")
  local info = self.win_buf:createSplitWin(self.now_win_id) -- will close telescope while create new win
  self:setNowBufWinId(info.buf_id, info.win_id)
  if file_type == nil or file_type == "" then
    file_type = "markdown"
  end
  local card_id = self.model:addNewCard(content_str, file_type)
  local item = self.model:getItemById(card_id)
  self.win_buf:viewContent(info.buf_id, item)
  local ret = self:setTagsForNowCardTree(-1, {}, true)
  self.telescope_menu:start(ret) -- should start new telescope
end

---@param content_str? string
function Menu:addCard(content_str)
  if not tools.confirmCheck("addCard") then
    return
  end
  local buf_id = self.win_buf:getNowInfo(self.now_buf_id).buf
  if content_str == nil then
    local content = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
    content_str = table.concat(content, "\n")
  end
  local file_type = vim.api.nvim_buf_get_option(buf_id, "filetype")
  if not file_type or file_type == "" then
    file_type = "markdown"
  end
  local card_id = self.model:addNewCard(content_str, file_type)
  local item = self.model:getItemById(card_id)
  self.win_buf:viewContent(self.now_buf_id, item)
  return self:setTagsForNowCardTree(-1, {}, true)
end

---@return TelescopeMenu
function Menu:tagList()
  self.tag_tree_exclude_ids = {}
  self.is_mapping_convert = false
  self.is_mapping_merge = false
  self.convert_tag_son_id = -1
  self.merge_tag_son_id = -1
  local tags = self.model:findAllTags()
  local items = {}
  if type(tags) == "table" then
    for _, v in ipairs(tags) do
      table.insert(items, { name = v.name, info = { id = v.id, name = v.name }, foo = nil })
    end
  end
  return {
    prompt_title = "Evidence tagList",
    menu_item = items,
    main_foo = nil,
    custom_mappings = {
      ["i"] = {
        --- keymap help
        ["<c-h>"] = function(prompt_bufnr)
          print("<c-x>:tagTree <c-l>:tagTreeAutoLocation")
        end,
        --- tagTree auto location
        ["<c-l>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          local res = self:tagTree(v.id)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- tagTree
        ["<c-x>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local res = self:tagTree(-1)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
      },
    },
  }
end

---@return TelescopeMenu
function Menu:findTagsByNowCard()
  local card_id = self:getNowItem().id
  local res = self.model:findIncludeTagsByCard(card_id)
  local items = {}
  if res ~= nil then
    for _, v in ipairs(res) do
      table.insert(items, { name = v.name, foo = nil })
    end
  end
  return {
    prompt_title = "Evidence findTagsByNowCard",
    menu_item = items,
    main_foo = nil,
  }
end

---@return TelescopeMenu
function Menu:delTagsForNowCard()
  local card_id = self:getNowItem().id
  local res = self.model:findIncludeTagsByCard(card_id)
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = { id = v.id },
        foo = function()
          if not tools.confirmCheck("delTagsForNowCard") then
            return
          end
          self.model:delCardTag(card_id, v.id)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence delTagsForNowCard",
    menu_item = items,
    main_foo = function(value)
      local typename = type(value)
      if typename == "table" then
        for _, v in ipairs(value) do
          self.model:delCardTag(card_id, v.info.id)
        end
      end
    end,
  }
end

---@param del_tag number[] | number
function Menu:updateSelectTags(del_tag)
  local s = set.createSetFromArray(self.select_tags)
  local typename = type(del_tag)
  if typename == "table" then
    for _, id in ipairs(del_tag) do
      set.remove(s, id)
    end
  elseif typename == "number" then
    set.remove(s, del_tag)
  end
  self.select_tags = set.toArray(s)
end

---@return TelescopeMenu
function Menu:delTags()
  local res = self.model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = { id = v.id },
        foo = function()
          if not tools.confirmCheck("delTags") then
            return
          end
          self.model:delTag(v.id)
          self:updateSelectTags(v.id)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence delTags",
    menu_item = items,
    main_foo = function(value)
      print("cannot multiple del tags for direct relations")
      --local typename = type(value)
      --if typename == "table" then
      --  for _, v in ipairs(value) do
      --    self.model:delTag(v.info.id)
      --    updateSelectTags(v.id)
      --  end
      --end
    end,
  }
end

---@return TelescopeMenu
function Menu:renameTag()
  local res = self.model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = { id = v.id },
        foo = function()
          local new_name = tools.uiInput("renameTag old_name:" .. v.name .. " new_name:", "")
          if new_name ~= nil then
            self.model:editTag(v.id, { name = new_name })
          end
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence renameTag",
    menu_item = items,
    main_foo = nil,
  }
end

---@param  is_and boolean
---@param now_tag_id number
---@param is_add_mode boolean
---@return TelescopeMenu
function Menu:setSelectTagsTreeMode(now_tag_id, is_and, is_add_mode)
  self.is_select_tag_and = is_and
  local son_tags = self.model:findSonTags(now_tag_id)
  local items = {}
  if now_tag_id ~= -1 then
    local now_tag = self.model:findTagById(now_tag_id)
    if now_tag == nil then
      error("setSelectTagsTreeMode findTagById")
    end
    table.insert(items, {
      name = "[father] " .. now_tag.name,
      info = { id = now_tag.id, name = now_tag.name },
      foo = function()
        return self:setSelectTagsTreeMode(now_tag.father_id, is_and, is_add_mode)
      end,
    })
  end
  --print(vim.inspect(son_tags))
  if type(son_tags) == "table" then
    for _, v in ipairs(son_tags) do
      local ret = tools.isInTable(v.id, self.select_tags)
      if is_add_mode then
        ret = not ret
      end
      if ret then
        table.insert(items, {
          name = v.name,
          info = { id = v.id, name = v.name },
          foo = function()
            return self:setSelectTagsTreeMode(v.id, is_and, is_add_mode)
          end,
        })
      end
    end
  end
  local mode_str = "del_mode"
  if is_add_mode then
    mode_str = "add_mode"
  end
  return {
    prompt_title = "Evidence setSelectTagsTreeMode (" .. mode_str .. ") " .. self:selectTagNameStr(),
    menu_item = items,
    --- addTag
    main_foo = function(prompt) end,
    custom_mappings = {
      ["i"] = {
        --- keymap help
        ["<c-h>"] = function(prompt_bufnr)
          print("<c-x>:switchList <c-e>:addSelectTag <c-d>:delSelectTag <c-v>:replaceNowCardTags")
        end,
        --- switchList
        ["<c-x>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local res = self:setSelectTagsListMode(is_and, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- replaceNowCardTags
        ["<c-v>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local card_id = self:getNowItem().id
          local tags = self.model:findIncludeTagsByCard(card_id)
          if tags == nil then
            print("tags empty")
            return
          end
          self.select_tags = tools.getValArrayFromItem(tags, "id")
          local res = self:setSelectTagsTreeMode(-1, is_and, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- addSelectTag
        ["<c-e>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          if not is_add_mode then
            local res = self:setSelectTagsTreeMode(now_tag_id, is_and, true)
            self.telescope_menu:flushResult(res, picker, prompt_bufnr)
            return
          end
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          table.insert(self.select_tags, v.id)
          if now_tag_id == v.id then
            now_tag_id = -1
          end
          local res = self:setSelectTagsTreeMode(now_tag_id, is_and, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- delSelectTag
        ["<c-d>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local res = self:setSelectTagsListMode(is_and, false)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
      },
    },
  }
end

---@param is_and boolean
---@param is_add_mode boolean
---@return TelescopeMenu
function Menu:setSelectTagsListMode(is_and, is_add_mode)
  self.is_select_tag_and = is_and
  local res = self.model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      local ret = tools.isInTable(v.id, self.select_tags)
      if is_add_mode then
        ret = not ret
      end
      if ret then
        table.insert(items, {
          name = v.name,
          info = { id = v.id, name = v.name },
          foo = nil,
        })
      end
    end
  end
  local mode_str = "del_mode"
  if is_add_mode then
    mode_str = "add_mode"
  end
  return {
    prompt_title = "Evidence setSelectTagsListMode (" .. mode_str .. ") " .. self:selectTagNameStr(),
    menu_item = items,
    main_foo = nil,
    custom_mappings = {
      ["i"] = {
        --- keymap help
        ["<c-h>"] = function(prompt_bufnr)
          print("<c-x>:switchTree <c-e>:addSelectTag <c-d>:delSelectTag <c-v>:replaceNowCardTags")
        end,
        --- switchTree
        ["<c-x>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local select_item = action_state.get_selected_entry()
          local res = self:setSelectTagsTreeMode(-1, is_and, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- replaceNowCardTags
        ["<c-v>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local card_id = self:getNowItem().id
          local tags = self.model:findIncludeTagsByCard(card_id)
          if tags == nil then
            print("tags empty")
            return
          end
          self.select_tags = tools.getValArrayFromItem(tags, "id")
          local res = self:setSelectTagsListMode(is_and, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- addSelectTag
        ["<c-e>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          if not is_add_mode then
            local res = self:setSelectTagsListMode(is_and, true)
            self.telescope_menu:flushResult(res, picker, prompt_bufnr)
            return
          end
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          table.insert(self.select_tags, v.id)
          local res = self:setSelectTagsListMode(is_and, true)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- delSelectTag
        ["<c-d>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          if is_add_mode then
            local res = self:setSelectTagsListMode(is_and, false)
            self.telescope_menu:flushResult(res, picker, prompt_bufnr)
            return
          end
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          local s = set.createSetFromArray(self.select_tags)
          set.remove(s, v.id)
          self.select_tags = set.toArray(s)
          local res = self:setSelectTagsListMode(is_and, false)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
      },
    },
  }
end

---@return TelescopeMenu
function Menu:findCardBySelectTags()
  local foo = function(prompt)
    local res = self.model:findCardBySelectTags(self.select_tags, self.is_select_tag_and, true, 50, prompt)
    if res ~= nil then
      return tools.reverseArray(res)
    else
      print("findCardBySelectTags empty")
    end
  end
  return {
    prompt_title = "Evidence findCardBySelectTags " .. self:selectTagNameStr(),
    menu_item = {},
    main_foo = nil,
    previewer = self.helper:createCardPreviewer(),
    process_work = self.helper:createCardProcessWork(self.now_buf_id, foo),
  }
end

---@return TelescopeMenu | nil
function Menu:findReviewCard()
  local items = self.model:getMinDueItem(self.select_tags, self.is_select_tag_and, true, 50)
  if items == nil then
    print("findReviewCard empty")
    return nil
  end
  return {
    prompt_title = "Evidence findReviewCard " .. self:selectTagNameStr(),
    menu_item = items,
    main_foo = nil,
    previewer = self.helper:createCardPreviewer(),
    card_entry_maker = function(entry)
      return self.helper:card_entry_maker(self.now_buf_id, entry)
    end,
  }
end

---@return TelescopeMenu | nil
function Menu:findNewCard()
  local items = self.model:getNewItem(self.select_tags, self.is_select_tag_and, true, 50)
  if items == nil then
    print("findReviewCard empty")
    return nil
  end
  return {
    prompt_title = "Evidence findNewCard " .. self:selectTagNameStr(),
    menu_item = items,
    main_foo = nil,
    previewer = self.helper:createCardPreviewer(),
    card_entry_maker = function(entry)
      return self.helper:card_entry_maker(self.now_buf_id, entry)
    end,
  }
end

---@return TelescopeMenu|nil
function Menu:tagTreeMain()
  self.tag_tree_exclude_ids = {}
  self.is_mapping_convert = false
  self.is_mapping_merge = false
  self.convert_tag_son_id = -1
  self.merge_tag_son_id = -1
  return self:tagTree(-1)
end

---@param now_tag_id number
---@return TelescopeMenu|nil
function Menu:tagTree(now_tag_id)
  local reset_local_state = function()
    self.is_mapping_convert = false
    self.is_mapping_merge = false
    self.convert_tag_son_id = -1
    self.merge_tag_son_id = -1
  end
  local son_tags = self.model:findSonTags(now_tag_id)
  local items = {}
  if now_tag_id ~= -1 then
    local now_tag = self.model:findTagById(now_tag_id)
    if now_tag == nil then
      error("tagTree findTagById")
    end
    table.insert(items, {
      name = "[father] " .. now_tag.name,
      info = { id = now_tag.id, name = now_tag.name },
      foo = function()
        return self:tagTree(now_tag.father_id)
      end,
    })
  end
  --print(vim.inspect(son_tags))
  if type(son_tags) == "table" then
    for _, v in ipairs(son_tags) do
      if not tools.isInTable(v.id, self.tag_tree_exclude_ids) then
        table.insert(items, {
          name = v.name,
          info = { id = v.id, name = v.name },
          foo = function()
            return self:tagTree(v.id)
          end,
        })
      end
    end
  end
  return {
    prompt_title = "Evidence tagTree",
    menu_item = items,
    --- addTag
    main_foo = function(prompt)
      if not tools.confirmCheck("addTag") then
        return
      end
      local tag_id = self.model:addTag(prompt)
      self.model:convertFatherTag({ tag_id }, now_tag_id)
      return self:tagTree(now_tag_id)
    end,
    custom_mappings = {
      ["i"] = {
        --- keymap help
        ["<c-h>"] = function(prompt_bufnr)
          print(
            "<c-x>:tagList <c-y>:convertTag  <c-g>:mergeTag <c-v>:paste <c-d>:delTag <c-s>:addSon <c-e>editTag"
          )
        end,
        --- tagList
        ["<c-x>"] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local res = self:tagList()
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- convertFatherTag start
        ["<c-y>"] = function(prompt_bufnr)
          reset_local_state()
          self.tag_tree_exclude_ids = {}
          self.is_mapping_convert = true
          self.is_mapping_merge = false
          local picker = action_state.get_current_picker(prompt_bufnr)
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          self.convert_tag_son_id = v.id
          self.tag_tree_exclude_ids = self.model:findAllSonTags({ self.convert_tag_son_id }, false) -- exclude tags
          print("convertFatherTag select start tag name:" .. v.name)
          local res = self:tagTree(now_tag_id)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- mergeTag start
        ["<c-g>"] = function(prompt_bufnr)
          reset_local_state()
          self.tag_tree_exclude_ids = {}
          self.is_mapping_merge = true
          self.is_mapping_convert = false
          local picker = action_state.get_current_picker(prompt_bufnr)
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          self.merge_tag_son_id = v.id
          self.tag_tree_exclude_ids = self.model:findAllSonTags({ self.merge_tag_son_id }, false) -- exclude tags
          print("convertFatherTag select start tag name:" .. v.name)
          local res = self:tagTree(now_tag_id)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- convertFatherTag end
        ["<c-v>"] = function(prompt_bufnr)
          if not self.is_mapping_convert and not self.is_mapping_merge then
            print("not select start tag")
            return
          end
          local picker = action_state.get_current_picker(prompt_bufnr)
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          local end_tag_father_id = v.id
          if self.is_mapping_convert then
            if not tools.confirmCheck("convertFatherTag") then
              return
            end
            self.model:convertFatherTag({ self.convert_tag_son_id }, end_tag_father_id)
            print("convertFatherTag select end tag name:" .. v.name)
          elseif self.is_mapping_merge then
            if not tools.confirmCheck("mergeTag") then
              return
            end
            self.model:mergeTags({ self.merge_tag_son_id }, end_tag_father_id)
            self:updateSelectTags({ self.merge_tag_son_id })
            print("mergeTag select end tag name:" .. v.name)
          end
          self.tag_tree_exclude_ids = {}
          reset_local_state()
          local res = self:tagTree(end_tag_father_id)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- delTag
        ["<c-d>"] = function(prompt_bufnr)
          reset_local_state()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          if not tools.confirmCheck("delTags") then
            return
          end
          self.model:delTag(v.id)
          self:updateSelectTags(v.id)

          local res = self:tagTree(now_tag_id)
          self.telescope_menu:flushResult(res, picker, prompt_bufnr)
        end,
        --- addSonForSelect
        ["<c-s>"] = function(prompt_bufnr)
          reset_local_state()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          local new_name = tools.uiInput("addSonForSelect now_name:" .. v.name .. " son_name:", "")
          if new_name ~= nil and new_name ~= "" then
            local tag_id = self.model:addTag(new_name)
            self.model:convertFatherTag({ tag_id }, v.id)

            local res = self:tagTree(now_tag_id)
            self.telescope_menu:flushResult(res, picker, prompt_bufnr)
          end
        end,
        --- editTag
        ["<c-e>"] = function(prompt_bufnr)
          reset_local_state()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local select_item = action_state.get_selected_entry()
          if select_item == nil then
            return
          end
          local single = select_item.value
          local v = single.info
          local new_name = tools.uiInput("renameTag old_name:" .. v.name .. " new_name:", "")
          if new_name ~= nil and new_name ~= "" then
            self.model:editTag(v.id, { name = new_name })

            local res = self:tagTree(now_tag_id)
            self.telescope_menu:flushResult(res, picker, prompt_bufnr)
          end
        end,
      },
    },
  }
end

---@param tag_ids number[]
---@return TelescopeMenu
function Menu:convertTagFatherEnd(tag_ids)
  local exclude_son_ids = self.model:findAllSonTags(tag_ids, true) -- exclude tags
  local res = self.model:findTagByIds(exclude_son_ids)
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        foo = function()
          if not tools.confirmCheck("convertTagFatherEnd") then
            return
          end
          self.model:convertFatherTag(tag_ids, v.id)
          self:updateSelectTags(tag_ids)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence convertTagFather select father tag",
    menu_item = items,
    main_foo = nil,
  }
end

---@return TelescopeMenu
function Menu:convertTagFatherStart()
  local res = self.model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = {
          id = v.id,
        },
        foo = function()
          return self:convertTagFatherEnd({ v.id })
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence convertTagFather select son tags",
    menu_item = items,
    main_foo = function(value)
      print("cannot multiple convertTagFather for direct relations")
      --local typename = type(value)
      --if typename == "table" then
      --  local ids = {}
      --  for _, v in ipairs(value) do
      --    table.insert(ids, v.info.id)
      --  end
      --  return convertTagFatherEnd(ids)
      --end
    end,
  }
end

---@param tag_ids number[]
---@return TelescopeMenu
function Menu:mergeTagEnd(tag_ids)
  local exclude_son_ids = self.model:findAllSonTags(tag_ids, true) -- exclude tags
  local res = self.model:findTagByIds(exclude_son_ids)
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        foo = function()
          if not tools.confirmCheck("mergeTagEnd") then
            return
          end
          self.model:mergeTags(tag_ids, v.id)
          self:updateSelectTags(tag_ids)
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence mergeTagEnd select new tag",
    menu_item = items,
    main_foo = nil,
  }
end

---@return TelescopeMenu
function Menu:mergeTagStart()
  local res = self.model:findAllTags()
  local items = {}
  if type(res) == "table" then
    for _, v in ipairs(res) do
      table.insert(items, {
        name = v.name,
        info = {
          id = v.id,
        },
        foo = function()
          return self:mergeTagEnd({ v.id })
        end,
      })
    end
  end
  return {
    prompt_title = "Evidence mergeTagStart select old tags",
    menu_item = items,
    main_foo = function(value)
      print("cannot multiple mergeTagStart for direct relations")
      --local typename = type(value)
      --if typename == "table" then
      --  local ids = {}
      --  for _, v in ipairs(value) do
      --    table.insert(ids, v.info.id)
      --  end
      --  return mergeTagEnd(ids)
      --end
    end,
  }
end

---@param ways number[]
---@param str string
---@return TelescopeMenu
function Menu:recordCardList(ways, str)
  local foo = function(prompt)
    local items = self.model:findRecordCard(prompt, ways)
    if items == nil then
      items = {}
    end
    items = tools.reverseArray(items)
    return items
  end
  return {
    prompt_title = "Evidence recordCard {" .. str .. "}",
    menu_item = {},
    main_foo = nil,
    previewer = self.helper:createCardPreviewer(),
    process_work = self.helper:createCardProcessWork(self.now_buf_id, foo, self.now_win_id),
  }
end

---@return TelescopeMenu
function Menu:recordCard()
  local items = {}
  for k, v in pairs(tblInfo.AccessWay) do
    table.insert(items, {
      name = k,
      info = {
        v = v,
        k = v,
      },
      foo = function()
        return self:recordCardList({ v }, tostring(k))
      end,
    })
  end
  return {
    prompt_title = "Evidence recordCard way select",
    menu_item = items,
    main_foo = function(value)
      local typename = type(value)
      if typename == "table" then
        local ways = {}
        local str = ""
        for _, v in ipairs(value) do
          table.insert(ways, v.info.v)
          str = str .. "," .. v.info.k
        end
        return self:recordCardList(ways, str)
      end
    end,
  }
end

---@param buf_id number
---@param win_id number
---@param select_region? SelectRegion
function Menu:setNowBufWinId(buf_id, win_id, select_region)
  self.now_buf_id = buf_id
  self.now_win_id = win_id
  if select_region ~= nil then
    self.select_region = select_region
  end
end

function Menu:refreshCard()
  self.win_buf:viewContent(self.now_buf_id, self:getNowItem())
end

function Menu:addDivider()
  if self.select_region == {} then
    error("addDivider select_region empty")
  end
  local content = vim.api.nvim_buf_get_lines(self.now_buf_id, 0, -1, false)
  local content_str = table.concat(content, "\n")
  local new_id = self.helper:getNewDividerId(content_str)
  local prefixStr = "{{<[" .. new_id .. "] "
  local suffixStr = " [" .. new_id .. "]>}}"
  self.helper:addPrefixAndSuffix(self.now_buf_id, self.select_region, prefixStr, suffixStr)
  self.select_region = {}
end

---@param title string
---@param menuItem SimpleMenu[]
function Menu:telescopeStart(title, menuItem)
  self.telescope_menu:start({
    prompt_title = "Evidence " .. title .. " " .. self:selectTagNameStr(),
    menu_item = menuItem,
  })
end

return Menu:getInstance()
