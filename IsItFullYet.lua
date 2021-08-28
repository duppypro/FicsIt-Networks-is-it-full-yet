local thisNetwork = component.findComponent("") -- this is effectively findAll as everything will match the empty string

print("All Components on Network")
for _, uuid in pairs(thisNetwork) do
  local c = component.proxy(uuid)
  print(" [".._.."] UUID=\""..uuid.."\" Nickname/Group=\""..c.nick.."\"", "Class=\""..c:getType().name.."\" child of \""..c:getType():getParent():await().name.."\" child of \""..c:getType():getParent():await():getParent():await().name.."\"")
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

local function pad(s)
  if s:len() >= 8 then
    return s
  else
    return ("        "..tostring(s)):sub(-8)
  end
end

local status = ""
while true do
  status = ""
  for uuid, inv in pairs(myFuelGenInventories) do
    status = status..pad(inv.inventory:getStack(0).count)
  end
  print(pad(computer.millis()), status)
  event.pull(1/30) -- update at 90bpm  
end
