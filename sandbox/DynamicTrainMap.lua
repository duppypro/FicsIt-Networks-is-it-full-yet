local gpu = computer.getGPUs()[1]

local screen = component.proxy(component.findComponent("TrainScreen"))[1]
if not screen then
 screen = computer.getScreens()[1]
end

local station = component.proxy(component.findComponent("Station")[1])
local track = station:getTrackGraph()
local train = track:getTrains()[1]

event.ignoreAll()

gpu:bindScreen(screen)
w, h = gpu:getSize()
gpu:setBackground()
gpu:fill(0, 0, w, h, " ")

tracks = {}

function addTrackConnection(con)
 for _,c in pairs(con:getConnections()) do
  addTrack(c:getTrack())
 end
end

function addTrack(track)
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

-- get bounds
min = {}
min.x = 0
min.y = 0
max = {}
max.x = 0
max.y = 0

x, y = tracks[1]:getLocation()
min.x = x
min.y = y
max.x = x
max.y = y

function connectorBounds(con)
 x, y = con:getConnectorLocation()
 if x < min.x then
  min.x = x
 elseif x > max.x then
  max.x = x
 end
 if y < min.y then
  min.y = y
 elseif y > max.y then
  max.y = y
 end
end

for _,t in pairs(tracks) do
 connectorBounds(t:getConnection(0))
 connectorBounds(t:getConnection(1))
end

function actorToScreen(x, y)
 local rangeX = max.x - min.x
 local rangeY = max.y - min.y
 x = x - min.x
 y = y - min.y
 return math.floor(x / rangeX * (w-5)) + 2, math.floor(y / rangeY * (h-4)) + 2
end

print(#tracks)
print(min.x, min.y, max.x, max.y)
print(actorToScreen(min.x, min.y))

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function drawLine(x1, y1, x2, y2)
 local dirX = x2 - x1
 local dirY = y2 - y1
 local l = math.sqrt(dirX*dirX + dirY*dirY)
 for i=0,l,0.5 do
  x = math.floor(round(x1 + ((dirX/l) * i)))
  y = math.floor(round(y1 + ((dirY/l) * i)))
  gpu:setText(x,y," ")
 end
end 

function drawConnector(con)
 local x, y = con:getConnectorLocation()
 x, y = actorToScreen(x, y)
 gpu:setBackground(1,1,1,1)
 gpu:setText(x, y, " ")
end

function drawTrack(track)
 local x1, y1 = actorToScreen(track:getConnection(0):getConnectorLocation())
 local x2, y2 = actorToScreen(track:getConnection(1):getConnectorLocation())
 gpu:setBackground(1,1,1,1)
 drawLine(x1, y1, x2, y2)
end

while true do
 gpu:setBackground()
 gpu:fill(0, 0, w, h, " ")
 
 for _,t in pairs(tracks) do
  drawTrack(t)
 end
 
 for _,train in pairs(track:getTrains()) do
  local x, y = train:getFirst():getLocation()
  x, y = actorToScreen(x,y)
  local x2, y2 = train:getLast():getLocation()
  x2, y2 = actorToScreen(x2,y2)
  gpu:setBackground(1,0,0,1)
  gpu:setForeground(1,1,1,1)
  drawLine(x, y, x2, y2)
 end
 gpu:flush()
end
