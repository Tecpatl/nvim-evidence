local function push(queue, element)
  table.insert(queue, element)
end

local function pop(queue)
  if #queue > 0 then
    return table.remove(queue, 1)
  end
end

local function front(queue)
  if #queue > 0 then
    return queue[1]
  end
end

local function isEmpty(queue)
  return #queue == 0
end

local function size(queue)
  return #queue
end

return {
  push = push,
  pop = pop,
  front = front,
  isEmpty = isEmpty,
  size = size,
}
