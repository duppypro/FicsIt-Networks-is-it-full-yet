local nickname = "turbo"
print("Enumerate Factory Connectors and Inventories with Nickname containing", nickname,". on this computer case\'s network.")
local factoryArray = component.findComponent(nickname)
local factory1 = component.proxy(factoryArray[1])

event.ignoreAll()
event.clear()

local getStackCount = function(n,sn)
  local inventory = factory1:getInventories()[n]
  local c = "-"

  if inventory == nil then
    c = "#"
  elseif inventory.internalName == "InventoryPotential" then
    c = "#" -- I don't know what the InventoryPotential type is - from observation it does not reflect inventory
  elseif inventory:getStack(sn) == nil then
    c = "#"
  elseif inventory:getStack(sn).item ~= nil then
    if inventory:getStack(sn).item.type and inventory:getStack(sn).item.type.form == 2 then -- form==2 is fluid with different units than belts
      c = string.format("% 3.3f", inventory:getStack(sn).count/1000)
    else -- assume form == 1 is belts. TODO: handle gases and heat? other forms
      c = string.format("% 3.0f", inventory:getStack(sn).count)
    end
  end
  return c
end

local fc = factory1:getFactoryConnectors()
local i=1
while fc[i] do
  print(fc[i], "#"..i, "Type", fc[i].type..",", fc[i].internalName..", Dir", fc[i].direction..", Connected", fc[i].isConnected)
  event.listen(fc[i])
  i = i + 1
end

print("===========================")
local fi = factory1:getInventories()
i = 0 -- Factory Connectors and Inventories start with index 1
while fi[i+1] do
  i = i + 1
  print(i, "-- Inv size", fi[i].size..",", fi[i].internalName..", count", string.format("% 6.0f",fi[i].itemCount))
  for s=0,fi[i].size-1 do -- getStack indexes start with 0
    --print("<",s,">")
    local stack = fi[i]:getStack(s)
    if stack.item.type then
      print("   ",s,stack.item.type.form,string.format("% 6.0f", stack.count),stack.item.type.name, "form:",stack.item.type.form)
    end
  end  
end
local numInventories = i

print("- - - - - - - - - - - - - - - -")
local timeout = 3 -- 0.166666 or 0.666666 or 1.333333

local now = computer.time()
local now_ms = computer.millis()
local last_time = now
local last_ms = now_ms

while true do --true do
  local etype, source, val = event.pull(timeout)
  now = computer.time(); now_ms = computer.millis()
  --print(etype, "|", source, "|", val, "|")

  print(string.format("Progress % 3.0f%%",factory1.progress*100))

  if etype == "ItemTransfer" then
    print(etype, now - last_time, string.format("% 3.3f",(now_ms - last_ms)/1000), source.internalName, val.type.internalName)
    last_time = now; last_ms = now_ms   
  elseif etype ~= nil then
    print("<<< Unknown event:", etype, ">>>", source, source.internalName, val)--, source.type.internalName)
  else
    print("pull timed out without event")
  end

  for fn = 1,numInventories do
    if fi[fn].internalName ~= "InventoryPotential" then
      print(fn, fi[fn].internalName, getStackCount(fn,0), getStackCount(fn,1), getStackCount(fn,2), getStackCount(fn,3))
    end
  end
end
