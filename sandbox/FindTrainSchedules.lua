local firstPlatform = component.proxy(component.findComponent(findClass("TrainPlatform")))[1]
-- search for any "TrainPlatform" class which is parent of all the cargo and fluid platforms and stations
local allTrains = firstPlatform:getTrackGraph():getStations()
print("Found", #allTrains, "trains on this track graph of this station.")

for _,s in pairs(allTrains) do
 print(s.name)
end
