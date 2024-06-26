local _ = requireSubPlugin("evidence.model.fsrs_models")

--- @class FSRS
--- @field p Parameters
local FSRS = {}

--- @param p? Parameters
--- @return FSRS
function FSRS:new(p)
  local p_ = nil
  if p ~= nil then
    p_ = p:copy()
  else
    p_ = _.Parameters:new()
  end
  local obj = {
    p = p_,
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

---@param r RatingType
function FSRS:init_difficulty(r)
  return math.min(math.max(self.p.w[5] - self.p.w[6] * (r - 3), 1), 10)
end

---@param r RatingType
function FSRS:init_stability(r)
  return math.max(self.p.w[r], 0.1)
end

function FSRS:mean_reversion(init, current)
  return self.p.w[8] * init + (1 - self.p.w[8]) * current
end

function FSRS:next_recall_stability(d, s, r, rating)
  --return s * (1 + math.exp(self.p.w[7]) * (11 - d) * math.pow(s, self.p.w[8]) * (math.exp((1 - r) * self.p.w[9]) - 1))
  local hard_penalty
  if rating == _.Rating.Hard then
    hard_penalty = self.p.w[16]
  else
    hard_penalty = 1
  end
  local easy_bonus
  if rating == _.Rating.Easy then
    easy_bonus = self.p.w[17]
  else
    easy_bonus = 1
  end
  return (
    s
    * (
      1
      + math.exp(self.p.w[9])
      * (11 - d)
      * math.pow(s, -self.p.w[10])
      * (math.exp((1 - r) * self.p.w[11]) - 1)
      * hard_penalty
      * easy_bonus
    )
  )
end

function FSRS:next_forget_stability(d, s, r)
  return (
    self.p.w[12]
    * math.pow(d, -self.p.w[13])
    * (math.pow(s + 1, self.p.w[14]) - 1)
    * math.exp((1 - r) * self.p.w[15])
  )
end

function FSRS:next_difficulty(d, r)
  local next_d = d - self.p.w[7] * (r - 3)
  return math.min(math.max(self:mean_reversion(self.p.w[5], next_d), 1), 10)
end

---@param s SchedulingCards
function FSRS:init_ds(s)
  s.again.difficulty = self:init_difficulty(_.Rating.Again)
  s.again.stability = self:init_stability(_.Rating.Again)
  s.hard.difficulty = self:init_difficulty(_.Rating.Hard)
  s.hard.stability = self:init_stability(_.Rating.Hard)
  s.good.difficulty = self:init_difficulty(_.Rating.Good)
  s.good.stability = self:init_stability(_.Rating.Good)
  s.easy.difficulty = self:init_difficulty(_.Rating.Easy)
  s.easy.stability = self:init_stability(_.Rating.Easy)
end

---@param s SchedulingCards
---@param last_d number
---@param last_s number
---@param retrievability number
function FSRS:next_ds(s, last_d, last_s, retrievability)
  s.again.difficulty = self:next_difficulty(last_d, _.Rating.Again)
  s.again.stability = self:next_forget_stability(s.again.difficulty, last_s, retrievability)
  s.hard.difficulty = self:next_difficulty(last_d, _.Rating.Hard)
  s.hard.stability = self:next_recall_stability(s.hard.difficulty, last_s, retrievability, _.Rating.Hard)
  s.good.difficulty = self:next_difficulty(last_d, _.Rating.Good)
  s.good.stability = self:next_recall_stability(s.good.difficulty, last_s, retrievability, _.Rating.Good)
  s.easy.difficulty = self:next_difficulty(last_d, _.Rating.Easy)
  s.easy.stability = self:next_recall_stability(s.easy.difficulty, last_s, retrievability, _.Rating.Easy)
end

---@param s number
---@return Days
function FSRS:next_interval(s)
  local interval = s * 9 * (1 / self.p.request_retention - 1)
  return math.min(math.max(math.floor(interval + 0.5), 1), self.p.maximum_interval)
end

--- Repeat function
--- @param card_ Card
--- @param now Timestamp
--- @return table<RatingType,SchedulingInfo>
function FSRS:repeats(card_, now)
  local card = card_:copy()
  if card.state == _.State.New then
    card.elapsed_days = 0
  else
    card.elapsed_days = os.difftime(now, card.last_review) / (24 * 60 * 60)
  end
  card.last_review = now
  card.reps = card.reps + 1
  local s = _.SchedulingCards:new(card)
  s:update_state(card.state)

  if card.state == _.State.New then
    self:init_ds(s)

    s.again.due = now + 60
    s.hard.due = now + 5 * 60
    s.good.due = now + 10 * 60

    local easy_interval = self:next_interval(s.easy.stability)
    s.easy.scheduled_days = easy_interval
    s.easy.due = now + easy_interval * 24 * 60 * 60
  elseif card.state == _.State.Learning or card.state == _.State.Relearning then
    local hard_interval = 0
    local good_interval = self:next_interval(s.good.stability)
    local easy_interval = math.max(self:next_interval(s.easy.stability), good_interval + 1)

    s:schedule(now, hard_interval, good_interval, easy_interval)
  elseif card.state == _.State.Review then
    local interval = card.elapsed_days
    local last_d = card.difficulty
    local last_s = card.stability
    local retrievability = math.pow(1 + interval / (9 * last_s), -1)
    self:next_ds(s, last_d, last_s, retrievability)
    local hard_interval = self:next_interval(s.hard.stability)
    local good_interval = self:next_interval(s.good.stability)
    hard_interval = math.min(hard_interval, good_interval)
    good_interval = math.max(good_interval, hard_interval + 1)
    local easy_interval = math.max(self:next_interval(s.easy.stability), good_interval + 1)
    s:schedule(now, hard_interval, good_interval, easy_interval)
  end
  return s:record_log()
end

return {
  fsrs = FSRS,
  model = _,
}
