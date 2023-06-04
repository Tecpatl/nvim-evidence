local function add(set, element)
  set[element] = true
end

local function remove(set, element)
  set[element] = nil
end

local function contains(set, element)
  return set[element] ~= nil
end

local function getSize(set)
  local count = 0
  for _ in pairs(set) do
    count = count + 1
  end
  return count
end

local function toArray(set)
  local array = {}
  local index = 1
  for element, _ in pairs(set) do
    array[index] = element
    index = index + 1
  end
  return array
end

---@pararm any[]
local function createSetFromArray(arr)
  local res = {}
  for _, id in ipairs(arr) do
    add(res, id)
  end
  return res
end

return {
  add = add,
  remove = remove,
  contains = contains,
  toArray = toArray,
  createSetFromArray = createSetFromArray,
}
