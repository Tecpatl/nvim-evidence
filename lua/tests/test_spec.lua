local tools = requireSubPlugin("evidence.util.tools")

describe("test", function()
  it("tt11", function()
    local sourceString = [[asdf{{<[12]asdf asdf 
    asdf
    asfasdf[12]>}}
    {{<[13]asdf[13]>}}
asdf {{<[32]asdf[32]>}}
    ]]
    --local pattern = [[{{<%_.%{-%}>}}]]
    --local pattern = [[{{<%[(%d+)%].->}}]]
    local pattern = [[{{<%[(%d+)%].-%[(%d+)%]>}}]]

    for match in string.gmatch(sourceString, pattern) do
      print(match)
    end
  end)
  it("min", function()
    local lim = 255 * 255 * 255

    -- 示例用法
    local array = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 } -- 假设数组中的数字不重复且范围为0到100000000
    local missingNumber = tools.findMinMissingNumber(array, lim)
    print("Missing number:", missingNumber)
  end)
  it("kk", function()
    local ret = tools.generateDistinctColors(10)
    print(vim.inspect(ret))
  end)
end)
