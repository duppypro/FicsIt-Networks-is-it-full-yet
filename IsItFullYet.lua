--
-- IsItFullYet.lua
--  Monitor manifold over time. Original idea to help repro max pipe fluid loss bugs
--  Even with no fluid or item loss bugs this is a useful way to check 100% efficiency,
--  visualize priming, compare load balance vs. manifold or many other.
--
-- Feature Road Map:
--  [X] Report internal Inventory on print()
--  [X] Add GPU:Screen bar graphs
--  [ ] Add ordering options for first and last machines
--  [ ] Support control panel switch, dials widgets for display choices
--  [ ] Add history, come up with a metric for rate of fill?  Efficiency over time window?
--  [ ] Separate data gathering and data presentation into different Computer Cases
--  [ ] Send data over Internet Card to Firebase Realtime Database and make front end web viewer
--

-------------------------------
-- Function definitions
-------------------------------

local gpu
local screen
local screenMinMax = {min={}, max={}, pad={}, range={}}

local expandMinMax = function(self, vector)
 local x, y = vector.x, vector.y
 if not self.min then self.min = {}; self.max = {} end
 if not self.min.x or x < self.min.x then self.min.x = x end
 if not self.min.y or y < self.min.y then self.min.y = y end
 if not self.max.x or x > self.max.x then self.max.x = x end
 if not self.max.y or y > self.max.y then self.max.y = y end
 if not self.range then self.range = {} end
 self.range.x = self.max.x - self.min.x
 self.range.y = self.max.y - self.min.y
 -- TODO: does not adjust aspect ratio - will stretch to fit screen
end

local worldToScreen = function(w, s, wv)
 -- return vector sv in screen s coord from vector wv in world w coord
 local x = wv.x - w.min.x -- offset in world units
 local y = wv.y - w.min.y -- offset in world units
 local sv = {}
 sv.x = s.pad.x + math.floor((x / w.range.x) * s.range.x + 0.5)
 sv.y = s.pad.y + math.floor((y / w.range.y) * s.range.y + 0.5)
 return sv
end

local countToBarString = function (count, width, opt_rangeMin, opt_rangeMax)
 -- count is between 0 and width inclusive.
 -- Or if included between rangeMin and rangeMax inclusive.
 -- returns a string width characters wide filled with count "#" chars left justified.
 local min = opt_rangeMin or 0
 local max = opt_rangeMax or width
 local range = max - min
 count = math.floor(((count-min)/range) * width + 0.5 + math.random()) -- try random for time averaged jitter extra resolution
 if count < 0 then count = 0 end
 if count > width then count = width end
 return ("#"):rep(count)..(" "):rep(width-count)
end

local drawInventory = function (count, sv)
 local width = 30
 gpu:setText(sv.x-width/2, sv.y-1, countToBarString(count, width, 0, 50000))
 gpu:setText(sv.x-width/2, sv.y, countToBarString(count, width, 0, 50000))
 gpu:setText(sv.x-width/2, sv.y+1, countToBarString(count, width, 0, 50000))
 gpu:setText(sv.x-width/2 + 1, sv.y, string.format("%1.1f", count/1000):padSpaces(5).." ")
end

local drawManifold = function (m)
 gpu:setBackground(0,0,0,0)
 gpu:setForeground(242/512, 101/512, 17/512, 1)
 for uuid, fg in pairs(m.factories) do
  local sv = worldToScreen(m.worldMinMax, screenMinMax, fg.location)
  --print("location", fg.location.x, sv.x, fg.location.y, sv.y)
  drawInventory(fg.inventory:getStack(0).count, sv)
 end
 gpu:flush()
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

--[[--
 Code starts here
--]]--
print("All Fuel Generators connected to this Computer Case.")
local m = {} -- the myFuelGens object
m.UUIDs = component.findComponent(findClass("Build_GeneratorFuel_C"))
m.factories = {}
m.worldMinMax = {}
m.worldMinMax.expand = expandMinMax
for _, uuid in pairs(m.UUIDs) do
 local fg = component.proxy(uuid)
 m.factories[uuid] = {}
 m.factories[uuid].fg = fg
 m.factories[uuid].location = fg.location
 m.factories[uuid].inventory = fg:getInventories()[1] -- assumes fule Gen, assumes [1] is the input
 m.factories[uuid].nick = fg.nick
 m.worldMinMax:expand(fg.location)
end
print("Found", #m.UUIDs, "Fuel Gens.")
print("World Min Max", m.worldMinMax.min.x, m.worldMinMax.min.y, "to", m.worldMinMax.max.x, m.worldMinMax.max.y)
print("Finding screen")
gpu = computer.getPCIDevices(findClass("GPU_T1_C"))[1]

screen = component.proxy(component.findComponent("bargraph"))[1]
if not screen then
 screen = computer.getPCIDevices(findClass("ScreenDriver_C"))[1]
 if screen == nil then print("No screen found.") else print("Using internal screen.") end
else
 print("Found Large Screen. Nick/Group =", screen.nick, "UUID =", screen.hash)
end
gpu:bindScreen(screen)
gpu:setSize(212,100) -- force to high res. cuz why not?
local w, h = gpu:getSize()
screenMinMax.min.x = 0; screenMinMax.min.y = 0
screenMinMax.max.x = w; screenMinMax.max.y = h
screenMinMax.pad.x = 16; screenMinMax.pad.y = 2 -- size of border
screenMinMax.range.x = screenMinMax.max.x - screenMinMax.min.x - screenMinMax.pad.x*2
screenMinMax.range.y = screenMinMax.max.y - screenMinMax.min.y - screenMinMax.pad.y*2
--print("Screen found", screen.nick, screen, "W x H", w, h)
local drawChar = "+"
local brightness = 0.34 -- less than 0.33 seems to end up black, but 1 is too bright on external screens)
gpu:setBackground(0.0, 0.2, 0.2, brightness) -- solid Cyan for bounds check. Only seen at init
gpu:setForeground(1.0, 1.0, 1.0, brightness) -- solid Cyan for bounds check. Only seen at init
gpu:fill(0, 0, w, h, drawChar)
gpu:flush()

local status
while true do
 status = ""
 for uuid, inv in pairs(m.factories) do
  status = status..string.format("%1.1f", inv.inventory:getStack(0).count/1000):padSpaces()
 end
 print(string.padSpaces(computer.millis()), status)
 drawManifold(m)
 event.pull(1/30) -- update at 90bpm 
end
