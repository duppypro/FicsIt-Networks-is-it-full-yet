local station = component.proxy(component.findComponent(findClass("TrainPlatform")))[1]
-- search for any "TrainPlatform" class which is parent of all the cargo and fluid platforms and stations
local trains = station:getTrackGraph():getTrains()
print("Found", #trains, "trains.")

local myTracks = {} -- this is actually all tracks *and* stations *and* cargo and fluid platforms

local function addTrack() end -- pre define for lint because addTrackConnection() references addTrack()

local function addTrackConnection(tracks, con)
 for _,c in pairs(con:getConnections()) do
  addTrack(tracks, c:getTrack())
 end
end

addTrack = function (tracks, track) -- now safe to add definition that references addTrackConnection()
 -- add track to the table tracks
 -- check for duplicates and only add if it doesn't already exist (tracks loop back on themsleves)
 if tracks[track.hash] == nil then
  tracks[track.hash] = track
  -- follow each end of the track
  addTrackConnection(tracks, track:getConnection(0))
  addTrackConnection(tracks, track:getConnection(1)) -- as far as I can tell there is always a getConnection(1)
  -- !!NEVER!! call track:getConnection(2) it will hit an assert and insta crash.  Bug filed in GitHub.
  if track.isOwnedByPlatform then print("isOwnedByPlatform", track, track:getType():getParent():await().name, track:getType():getParent():await():getParent():await().name) end
end
end

addTrack(myTracks, station:getTrackPos()) -- can start with any track/station/platform. BUGBUG sometimes this is empty at game load
print("Done.")