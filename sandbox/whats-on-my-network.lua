local thisNetwork = component.findComponent("") -- this is effectively findAll as everything will match the empty string

print("All Components on Network")
for _, uuid in pairs(thisNetwork) do
  local c = component.proxy(uuid)
  print(" [".._.."] UUID=\""..uuid.."\" Nickname/Group=\""..c.nick.."\"", "Class=\""..c:getType().name.."\" child of \""..c:getType():getParent():await().name.."\" child of \""..c:getType():getParent():await():getParent():await().name.."\"")
end

print("\r\nAll PCI Devices in ComputerCase (a.k.a Computer_C)")
local thisPCIBus = computer.getPCIDevices(findClass(""))
for _, d in pairs(thisPCIBus) do
  print(" [".._.."] Class=\""..tostring(d).."\" child of \""..d:getType():getParent():await().name.."\" child of \""..d:getType():getParent():await():getParent():await().name.."\"")
end
