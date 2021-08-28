--[[--
 IsItFullYet.lua
  Monitor manifold over time. Original idea to help repro max pipe fluid loss bugs
  Even with no fluid or item loss bugs this is a useful way to check 100% efficiency,
  visualize priming, compare load balance vs. manifold or many other.

 Feature Road Map:
  [X] Report internal Inventory on print()
  [ ] Add GPU:Screen bar graphs
  [ ] Add ordering options for first and last machines
  [ ] Support control panel switch, dials widgets for display choices
  [ ] Add history, come up with a metric for rate of fill?  Efficiency over time window?
  [ ] Separate data gathering and data presentation into different Computer Cases
  [ ] Send data over Internet Card to Firebase Realtime Database and make front end web viewer
--]]--

--[[--
 Function definitions
--]]--
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
 sv.x = s.pad.x + math.floor((x / w.range.x) * s.range.x)
 sv.y = s.pad.y + math.floor((y / w.range.y) * s.range.y)
 return sv
end

local drawInventory = function (count, sv)
 gpu:setText(sv.x-6/2, sv.y, tostring(""):padSpaces(6))
 gpu:setText(sv.x-6/2, sv.y, tostring(count):padSpaces(6))
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

screen = component.proxy(component.findComponent(findClass("Build_Screen_C")))[1]
if not screen then
 screen = computer.getPCIDevices(findClass("ScreenDriver_C"))[1]
 if screen == nil then print("No screen found.") else print("Using internal screen.") end
else
 print("Found Large Screen. Nick/Group =", screen.nick, "UUID =", screen.hash)
end
gpu:bindScreen(screen)
gpu:setSize(212/4,100/4) -- force to high res. cuz why not?
local w, h = gpu:getSize()
screenMinMax.min.x = 0; screenMinMax.min.y = 0
screenMinMax.max.x = w; screenMinMax.max.y = h
screenMinMax.pad.x = 4; screenMinMax.pad.y = 1 -- size of border
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
  status = status..tostring(inv.inventory:getStack(0).count):padSpaces()
 end
 print(string.padSpaces(computer.millis()), status)
 drawManifold(m)
 event.pull(1/30) -- update at 90bpm 
end
