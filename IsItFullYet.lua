local thisNetwork = component.findComponent("") -- this is effectively findAll as everything will match the empty string

print("All Components on Network")
for _, uuid in pairs(thisNetwork) do
  local c = component.proxy(uuid)
  print(" [".._.."] UUID=\""..uuid.."\" Nickname/Group=\""..c.nick.."\"", "Class=\""..c:getType().name.."\"")
end

print("All Fuel Generators.")
local myFuelGenUUIDs = component.findComponent(findClass("Build_GeneratorFuel_C"))
local myFuelGenInventories = {}
for _, uuid in pairs(myFuelGenUUIDs) do
  local fg = component.proxy(uuid)
  myFuelGenInventories[uuid] = {}
  myFuelGenInventories[uuid].inventory = fg:getInventories()[1]
  myFuelGenInventories[uuid].nick = fg.nick
  print(" [".._.."] Nickname/Group", fg.nick, fg:getInventories()[1]:getStack(0).count)
end

-- add function to base string table
string.padSpaces = function (s, n)
  s = tostring(s)
  local width = n or 8
  local padding = (" "):rep(width)
  if s:len() >= width then
    return s
  else
    return (padding..s):sub(-width)
  end
end

local status
while true do
  status = ""
  for uuid, inv in pairs(myFuelGenInventories) do
    status = status..tostring(inv.inventory:getStack(0).count):padSpaces()
  end
  print(string.padSpaces(computer.millis()), status)
  event.pull(1/30) -- update at 90bpm
end