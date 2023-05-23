local tools = require("evidence.util.tools")

--- @alias RatingType integer
--- @class Rating
local Rating = {
  Again = 0,
  Hard = 1,
  Good = 2,
  Easy = 3,
}

--- @alias StateType integer
--- @class State
local State = {
  New = 0,
  Learning = 1,
  Review = 2,
  Relearning = 3,
}

--- @alias Timestamp integer
--- @alias Days integer

--- @class Card
--- @field due Timestamp
--- @field stability number
--- @field difficulty number
--- @field elapsed_days Days 前后两次实际复习时间间隔
--- @field scheduled_days Days
--- @field reps integer
--- @field lapses Days
--- @field state StateType
--- @field last_review Timestamp
local Card = {}

---@return Card
function Card:copy()
  local newCard = Card:new()
  return tools.merge(newCard, tools.copy(self))
end

---@return string
function Card:dumpStr()
  return tools.stringify(self:dump())
end

function Card:dump()
  local format = "%Y-%m-%d %H:%M:%S"
  local obj = tools.merge(self:copy(), {
    last_review_date = os.date(format, self.last_review),
    due_date = os.date(format, self.due),
  })
  setmetatable(obj, nil)
  return obj
end

---@param data Card|{}|nil
---@return Card
function Card:new(data)
  data = data or {}
  local obj = {
    due = os.time(),
    stability = 0.0,
    difficulty = 0,
    elapsed_days = 0,
    scheduled_days = 0,
    reps = 0,
    lapses = 0,
    state = State.New,
    last_review = os.time(),
  }
  tools.merge(obj, data)
  setmetatable(obj, self)
  self.__index = self
  return obj
end

--- @class SchedulingInfo
--- @field card Card
local SchedulingInfo = {}

function SchedulingInfo:new(card)
  local obj = {
    card = card:copy(),
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

--- @class SchedulingCards
--- @field again Card
--- @field hard Card
--- @field good Card
--- @field easy Card
local SchedulingCards = {}

---@param card Card
---@return SchedulingCards
function SchedulingCards:new(card)
  local obj = {
    again = card:copy(),
    hard = card:copy(),
    good = card:copy(),
    easy = card:copy(),
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

---@param state StateType
function SchedulingCards:update_state(state)
  if state == State.New then
    self.again.state = State.Learning
    self.hard.state = State.Learning
    self.good.state = State.Learning
    self.easy.state = State.Review
    self.again.lapses = self.again.lapses + 1
  elseif state == State.Learning or state == State.Relearning then
    self.again.state = state
    self.hard.state = state
    self.good.state = State.Review
    self.easy.state = State.Review
  elseif state == State.Review then
    self.again.state = State.Relearning
    self.hard.state = State.Review
    self.good.state = State.Review
    self.easy.state = State.Review
    self.again.lapses = self.again.lapses + 1
  end
end

---@param now Timestamp
---@param hard_interval Days
---@param good_interval Days
---@param easy_interval Days
function SchedulingCards:schedule(now, hard_interval, good_interval, easy_interval)
  self.again.scheduled_days = 0
  self.hard.scheduled_days = hard_interval
  self.good.scheduled_days = good_interval
  self.easy.scheduled_days = easy_interval
  self.again.due = now + 5 * 60
  if hard_interval > 0 then
    self.hard.due = now + hard_interval * 24 * 3600
  else
    self.hard.due = now + 10 * 60
  end
  self.good.due = now + good_interval * 24 * 3600
  self.easy.due = now + easy_interval * 24 * 3600
end

---@return table<RatingType,SchedulingInfo>
function SchedulingCards:record_log()
  return {
        [Rating.Again] = SchedulingInfo:new(self.again),
        [Rating.Hard] = SchedulingInfo:new(self.hard),
        [Rating.Good] = SchedulingInfo:new(self.good),
        [Rating.Easy] = SchedulingInfo:new(self.easy),
  }
end

--- @class Parameters
--- @field request_retention number
--- @field maximum_interval number
--- @field easy_bonus number
--- @field hard_factor number
--- @field w table<number>
local Parameters = {}

---@param obj Parameters|{}|nil
function Parameters:new(obj)
  obj = obj or {}
  local data = {
    request_retention = 0.9,
    maximum_interval = 36500,
    easy_bonus = 1.3,
    hard_factor = 1.2,
    w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
  }
  tools.merge(data, obj)
  setmetatable(data, self)
  self.__index = self
  return data
end

---@return Parameters
function Parameters:copy()
  local new_p = Parameters:new({})
  return tools.merge(new_p, tools.copy(self))
end

function Parameters:print_dump()
  tools.printDump(self:copy())
end

return {
  SchedulingInfo = SchedulingInfo,
  Rating = Rating,
  State = State,
  Card = Card,
  SchedulingCards = SchedulingCards,
  Parameters = Parameters,
}
