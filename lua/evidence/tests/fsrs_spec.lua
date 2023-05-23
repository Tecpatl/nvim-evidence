local FSRS = require("evidence.model.fsrs")
local tools = require("evidence.util.tools")
local _ = FSRS.model

local eq = function(a, b)
	assert.are.same(a, b)
end

---@param data table<RatingType,SchedulingInfo>
local printFSRS = function(data)
	print("<<<<<<<")
	print("again.card:")
	tools.printDump(data[_.Rating.Again].card:dump())
	print("hard.card:")
	tools.printDump(data[_.Rating.Hard].card:dump())
	print("good.card:")
	tools.printDump(data[_.Rating.Good].card:dump())
	print("easy.card:")
	tools.printDump(data[_.Rating.Easy].card:dump())
	print(">>>>>>>")
end

describe("fsrs", function()
	--it("fsrs_model", function()
	--	local card = _.Card:new()
	--	local info = _.SchedulingInfo:new(card)
	--	local cards = _.SchedulingCards:new(card)
	--	--dump(card)
	--	--dump(info)
	--	tools.dump(cards)
	--	cards:update_state(_.State.New)
	--	print("======")
	--	tools.dump(cards)
	--end)
	it("fsrs_schedule", function()
		local f = FSRS.fsrs:new()
		local card = _.Card:new()

		local now = os.time({ year = 2022, month = 11, day = 29, hour = 12, min = 30, sec = 0 })
		local scheduling_cards = f:repeats(card, now)
		--printFSRS(scheduling_cards)
		--
		card = scheduling_cards[_.Rating.Good].card
		now = card.due
		scheduling_cards = f:repeats(card, now)
    --
		card = scheduling_cards[_.Rating.Good].card
		now = card.due
		scheduling_cards = f:repeats(card, now)
    --
		card = scheduling_cards[_.Rating.Again].card
		now = card.due
		scheduling_cards = f:repeats(card, now)
    --
		card = scheduling_cards[_.Rating.Good].card
		now = card.due
		scheduling_cards = f:repeats(card, now)

---------------
---------------
---------------

		card = scheduling_cards[_.Rating.Again].card
		now = card.due
		scheduling_cards = f:repeats(card, now)

		card = scheduling_cards[_.Rating.Easy].card
		now = card.due
		scheduling_cards = f:repeats(card, now)

		card = scheduling_cards[_.Rating.Hard].card
		now = card.due
		scheduling_cards = f:repeats(card, now)

		card = scheduling_cards[_.Rating.Good].card
		now = card.due
		scheduling_cards = f:repeats(card, now)

		printFSRS(scheduling_cards)
	end)
end)
