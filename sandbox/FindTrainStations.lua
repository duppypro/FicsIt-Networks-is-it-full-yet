local firstPlatform = component.proxy(component.findComponent(findClass("TrainPlatform")))[1]
-- search for any "TrainPlatform" class which is parent of all the cargo and fluid platforms and stations
local allStations = firstPlatform:getTrackGraph():getStations()
print("Found", #allStations, "stations.")

for _,s in pairs(allStations) do
 print(s.name)
end
