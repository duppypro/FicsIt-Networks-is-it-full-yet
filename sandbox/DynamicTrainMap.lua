local gpu = computer.getPCIDevices(findClass("GPU_T1_C"))[1]

local screen = component.proxy(component.findComponent(findClass("Build_Screen_C")))[1]
if not screen then
 screen = computer.getPCIDevices(findClass("ScreenDriver_C"))[1]
end

local station = component.proxy(component.findComponent(findClass("TrainPlatform")))[1]
local trains = station:getTrackGraph():getTrains()
print("Found", #trains, "trains.")

gpu:bindScreen(screen)
gpu:setSize(212,100) -- force to high res. cuz why not?
local w, h = gpu:getSize()
print("Screen found", screen.nick, screen, "W x H", w, h)
local drawChar = " "
local brightness = 0.34 -- less than 0.33 seems to end up black, but 1 is too bright on external screens)
gpu:setBackground(0.0, 0.2, 0.2, brightness) -- solid Cyan for bounds check. Only seen at init
gpu:fill(0, 0, w, h, drawChar)
gpu:flush()

local tracks = {}
local numTracks = 0
local lastLineNum = 0 -- enable printing debug progress without slowing down too much
local skipNLines = 100 -- enable printing debug progress without slowing down too much

local function addTrack() end -- pre define for lint because addTrackConnection() references addTrack()

local function addTrackConnection(con)
 for _,c in pairs(con:getConnections()) do
  addTrack(c:getTrack())
 end
 if numTracks > lastLineNum then
   print(numTracks, "tracks found")
   lastLineNum = lastLineNum + skipNLines
 end
end

addTrack = function (track) -- now safe to add definition that references addTrackConnection()
 -- check for duplicates and only add if it doesn't already exist (tracks loop back on themsleves)
 if tracks[track.hash] == nil then
  -- cache end locations
  local cachedTrack = {}
  local c0 = track:getConnection(0)
  local c1 = track:getConnection(1)
  cachedTrack.loc0 = c0.connectorLocation
  cachedTrack.loc1 = c1.connectorLocation
  tracks[track.hash] = cachedTrack
  numTracks = numTracks + 1
  -- follow each end of the track
  addTrackConnection(c0)
  addTrackConnection(c1)
 end
end

addTrack(station:getTrackPos()) -- can start with any track. BUGBUG sometimes this is empty at game load
print("Done finding tracks.", numTracks,"total.")

local min = {}
local max = {}
min.x, min.y = nil, nil -- redundant paranoid explicitness
max.x, max.y = nil, nil -- redundant paranoid explicitness

local function connectorBounds(loc)
 local x = loc.x
 local y = loc.y
 if not min.x or x < min.x then min.x = x end
 if not max.x or x > max.x then max.x = x end
 if not min.y or y < min.y then min.y = y end
 if not max.y or y > max.y then max.y = y end
end

-- find min and max world x,y bounds of all the tracks
for _,t in pairs(tracks) do
 connectorBounds(t.loc0)
 connectorBounds(t.loc1)
end

local function actorToScreen(x, y)
-- convert world actor x,y to screen x,y
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

local function drawLine(x1, y1, x2, y2)
 local dirX = x2 - x1
 local dirY = y2 - y1
 local l = math.sqrt(dirX*dirX + dirY*dirY)

 if l == 0 then l = 0.1 end -- avoid divide by 0 and still do loop once for 1 pixel
 for i=0,l,0.5 do
  local x = math.floor(x1 + (dirX/l) * i + 0.5)
  local y = math.floor(y1 + (dirY/l) * i + 0.5)
  gpu:setText(x, y, drawChar)
 end
end

local function drawTrack(track)
 if track.x1 == nil then
  -- cache the converted locations
  track.x1, track.y1 = actorToScreen(track.loc0.x, track.loc0.y)
  track.x2, track.y2 = actorToScreen(track.loc1.x, track.loc1.y)
 end
 drawLine(track.x1, track.y1, track.x2, track.y2)
end

while true do
--print("start loop")
 local startMillis = computer.millis()

-- Draw background.
 gpu:setBackground(.25,.25,.25,brightness)
 gpu:setForeground(.75,.75,.75,brightness)
 drawChar = "+" -- grey on grey crosshairs suggest foundations as background
 gpu:fill(0, 0, w, h, drawChar) -- grey on grey crosshairs suggest foundations as background

-- Draw Tracks
 gpu:setBackground(0,0,0,0) -- draw tracks in solid black
 gpu:setForeground(.75,.75,.75,0) -- foreground unecessary since drawLine() uses space
 drawChar = " "
 for _,t in pairs(tracks) do
  drawTrack(t)
 end
 --print("draw", #tracks, "tracks done in split ", computer.millis() - startMillis, "millis.")

-- Draw Trains
 gpu:setBackground(242/512, 101/512, 17/512, brightness) -- use approximation of Satisfactory Orange from default paint slot
 gpu:setForeground(0,0,0,0)
 drawChar = " "
 for _,train in pairs(trains) do
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
 --print("drawTrains done in split", computer.millis() - startMillis, "millis.")

-- Don't forget to flush it to the visible buffer
 gpu:flush()
 --print("flushed")
 print("loop total", computer.millis() - startMillis, "millis.")
end
