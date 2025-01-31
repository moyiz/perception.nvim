local perception = require "perception"

local function main()
  math.randomseed(os.time())
  perception.ui:show()
  local filters = perception.list_filters()
  for _ = 1, 10 do
    local name = filters[math.random(1, #filters)]
    vim.print(name)
    local filter = perception.config.filters[name]
    local value = math.random(filter.level.min / 4, filter.level.max / 6)
    local current = perception.get(name)
    local step = 2
    if current > value then
      step = -step
    end
    for i = current, value, step do
      perception.set(name, i)
      vim.uv.sleep(40)
    end
  end
end

main()
