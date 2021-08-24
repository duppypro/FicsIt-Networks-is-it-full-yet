local myNetwork = component.findComponent("") -- this is effectively findAll as everything will match the empty string

print("All Components on Network")
for _, id in pairs(myNetwork) do
  local c = component.proxy(id)
  print(" [".._.."] ID:", id, "Nick: \""..c.nick.."\"", "Class:", c)
end
print("Found", #myNetwork, "components on the network.")

local filterText = "Build_TrainStation_C"
print("\r\nFilter with \""..filterText.."\"")
myNetwork = component.findComponent(findClass(filterText))
for _, id in pairs(myNetwork) do
  local c = component.proxy(id)
  print(" [".._.."] ID:", id, "Nick: \""..c.nick.."\"", "Class:", c)
end
print("Found", #myNetwork, "components on the network filtered with \""..filterText.."\"")

print("\r\nAll PCI Devices")
local myPCI = computer.getPCIDevices(findClass(""))
for _, device in pairs(myPCI) do
  print(" [".._.."] class:", device)
end
print("found",#myPCI,"PCI Devices.")

filterText = "FINComputerScreen"--"ScreenDriver_C"
print("\r\nPCI filtered  with \""..filterText.."\"")
local myPCI = computer.getPCIDevices(findClass(filterText))
for _, device in pairs(myPCI) do
  print(" [".._.."] class:", device) --, device:getType().name) -- getType() is "Class" whose name property is used when converting an object to a string
end
print("found",#myPCI,"PCI Devices matching filter.")
