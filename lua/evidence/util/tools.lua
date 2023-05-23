require("evidence.util.dumper")

local function isInTable(v, tb)
	for _, value in ipairs(tb) do
		if value == v then
			return true
		end
	end
	return false
end

-- array concat
local function table_concat(...)
	local nargs = select("#", ...)
	local argv = { ... }
	local t = {}
	for i = 1, nargs do
		local array = argv[i]
		if type(array) == "table" then
			for j = 1, #array do
				t[#t + 1] = array[j]
			end
		else
			t[#t + 1] = array
		end
	end

	return t
end

-- t2 merge into t1
-- force overlay
local function merge(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k] or false) == "table") then
			merge(t1[k], t2[k])
		else
			t1[k] = v
		end
	end
	return t1
end

local function str2table(str)
	local lines = {}
	for s in str:gmatch("[^\r\n]+") do
		local s1 = s:gsub("\\n", "\n")
		for ss in s1:gmatch("[^\r\n]+") do
			table.insert(lines, ss)
			table.insert(lines, "")
		end
	end
	return lines
end

--- check {{{}}}
local function isTableEmpty(t, visited)
	if type(t) ~= "table" then
		return false
	end
	visited = visited or {} -- 初始化 visited 表
	if visited[t] then
		return true -- 如果 t 已经被访问过，认为它是空表
	end
	visited[t] = true -- 将 t 加入 visited 表中
	for _, v in pairs(t) do
		if type(v) == "table" then
			if not isTableEmpty(v, visited) then
				return false
			end
		else
			if v ~= nil then
				return false
			end
		end
	end
	return true
end

---@return integer
local function parseDate(date_string, date_format)
	local year, month, day, hour, minute, second = date_string:match(date_format)
	local date_table = {
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(minute),
		sec = tonumber(second),
	}
	assert(isTableEmpty(date_table) == false)
	return os.time(date_table)
end

local function copy(orig)
	local copy_item = {}
	for k, v in pairs(orig) do
		copy_item[k] = v
	end
	return copy_item
end

local function deepCopy(orig)
	local copy_item
	if type(orig) == "table" then
		copy_item = {}
		for k, v in next, orig, nil do
			copy_item[deepCopy(k)] = deepCopy(v)
		end
		setmetatable(copy_item, deepCopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy_item = orig
	end
	return copy_item
end

local function printDump(obj)
	local meta = getmetatable(obj)
	setmetatable(obj, nil)
	print(vim.inspect(obj))
	setmetatable(obj, meta)
end

local function parse(data)
	local obj = loadstring(data)
	if obj then
		obj = obj()
		return obj
	else
		error("loadstring parse failed")
	end
end

---@return string
local function stringify(data)
	return DataDumper(data)
end

---@param prompt string
---@param default string
local function uiInput(prompt, default, ...)
	if select("#", ...) > 0 then
		local arg = select(1, ...)
		return vim.fn.input(prompt, default, "customlist," .. (arg.name or ""))
	end
	return vim.fn.input(prompt, default)
end

return {
	isInTable = isInTable,
	table_concat = table_concat,
	merge = merge,
	str2table = str2table,
	isTableEmpty = isTableEmpty,
	parseDate = parseDate,
	copy = copy,
	deepCopy = deepCopy,
	printDump = printDump,
	parse = parse,
	stringify = stringify,
	uiInput = uiInput,
}
