local gpu = computer.getPCIDevices(findClass("GPUT1"))[1]

local screen = component.proxy(component.findComponent(findClass("Screen")))[1]
if not screen then
 screen = computer.getPCIDevices(findClass("FINScreen"))[1]
end

local station = component.proxy(component.findComponent(findClass("Build_TrainStation_C")))[1]
local trackGraph = station:getTrackGraph()

event.ignoreAll()
event.clear() -- added to clear the event cache - being paranoid about repeatability

gpu:bindScreen(screen)
gpu:setSize(136,64) -- force to high res. cuz why not?
local w, h = gpu:getSize()
local drawChar = " "
gpu:setBackground(0.0, 0.2, 0.2, 1.0) -- solid Cyan for bounds check. Only seen at init
gpu:fill(0, 0, w, h, drawChar)
gpu:flush()

local tracks = {}
local lastLineNum = 0 -- enable printing debug progress without slowing down too much
local printEveryLineNum = 7 -- enable printing debug progress without slowing down too much

local function addTrack() end -- pre define for lint

local function addTrackConnection(con)
 for _,c in pairs(con:getConnections()) do
  addTrack(c:getTrack())
 end
 if #tracks > lastLineNum then
   print(#tracks, "tracks found")
   lastLineNum = #tracks + printEveryLineNum
 end
end

addTrack = function (track)
 for _,t in pairs(tracks) do
  if t == track then
   return
  end
 end
 table.insert(tracks, track)
 addTrackConnection(track:getConnection(0))
 addTrackConnection(track:getConnection(1))
end

addTrack(station:getTrackPos())
print("Done finding tracks.", #tracks,"total.")

local min = {}
local max = {}
min.x, min.y = nil, nil -- redundant paranoid explicitness
max.x, max.y = nil, nil -- redundant paranoid explicitness

local function connectorBounds(con)
 local x = con.connectorLocation.x
 local y = con.connectorLocation.y
 if not min.x or x < min.x then min.x = x end
 if not max.x or x > max.x then max.x = x end
 if not min.y or y < min.y then min.y = y end
 if not max.y or y > max.y then max.y = y end
end

for _,t in pairs(tracks) do
 connectorBounds(t:getConnection(0))
 connectorBounds(t:getConnection(1))
end

local function actorToScreen(x, y)
 local rangeX = max.x - min.x
 local rangeY = max.y - min.y
 x = x - min.x
 y = y - min.y
 if rangeY > rangeX then
  x = x + (rangeY- rangeX)/2
  rangeX = rangeY
 else -- rangeX >= rangeY
  y = y + (rangeX- rangeY)/2
  rangeY = rangeX
 end
 local wPad, hPad = 5, 4
 return math.floor(x / rangeX * (w-wPad)) + 2, math.floor(y / rangeY * (h-hPad)) + 2
end

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function drawLine(x1, y1, x2, y2)
 local dirX = x2 - x1
 local dirY = y2 - y1
 local l = math.sqrt(dirX*dirX + dirY*dirY)
 if l == 0 then l = 0.1 end -- avoid divide by 0
 for i=0,l,0.5 do
  local x = math.floor(round(x1 + ((dirX/l) * i)))
  local y = math.floor(round(y1 + ((dirY/l) * i)))
  gpu:setText(x, y, drawChar)
 end
end 

local function drawTrack(track)
 local x1, y1 = actorToScreen(track:getConnection(0).connectorLocation.x, track:getConnection(0).connectorLocation.y)
 local x2, y2 = actorToScreen(track:getConnection(1).connectorLocation.x, track:getConnection(1).connectorLocation.y)
 drawLine(x1, y1, x2, y2)
end

while true do
 gpu:setBackground(.25,.25,.25,1)
 gpu:setForeground(.75,.75,.75,1)
 drawChar = "+" -- grey on grey crosshairs suggest foundations as background
 gpu:fill(0, 0, w, h, drawChar) -- grey on grey crosshairs suggest foundations as background

 gpu:setBackground(0,0,0,1) -- draw tracks in solid black
 gpu:setForeground(.75,.75,.75,1) -- foreground unecessary since drawLine() uses space
 drawChar = " "
 for _,t in pairs(tracks) do
  drawTrack(t)
 end

 gpu:setBackground(242/384,101/384,17/384,1) -- use approximation of Satisfactory Orange from default paint slot
 gpu:setForeground(0,0,0,0)
 drawChar = " "
 for _,train in pairs(trackGraph:getTrains()) do
  --print("  [".._.."]", train)
  local v = train:getVehicles()[1] -- must init with something
  local x1,y1 = actorToScreen(v.location.x, v.location.y)
  local x2 = x1
  local y2 = y1
  for _,vehicle in pairs(train:getVehicles()) do -- this should include the locomotive getFirst() and getLast() did not
   --print("    [".._.."]", v)
   local x,y = actorToScreen(vehicle.location.x, vehicle.location.y)
   if x < x1 then x1 = x end
   if x > x2 then x2 = x end
   if y < y1 then y1 = y end
   if y > y2 then y2 = y end
  end
  drawLine(x1, y1, x2, y2) -- TODO make each train car correct size and rotation
 end
 gpu:flush()

 event.pull(1/30) -- limit to 30fps
end
