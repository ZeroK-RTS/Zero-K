-- $Id$
local versionNumber = "1.1"

function widget:GetInfo()
	return {
		name      = "Unit Marker",
		desc      = "[v" .. string.format("%s", versionNumber ) .. "] Marks spotted units of interest.",
		author    = "very_bad_soldier",
		date      = "October 21, 2007",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

--[[
Features:
-multiple mod support
-no multiple markers if multiple players use it

Changelog:
1.1: auto-disable when spec
1.0: initial release
--]]

local unitList = {}
--MARKER LIST ------------------------------------
unitList["BA"] = {} --initialize table
unitList["BA"]["armamd"] = { markerText = "Anti Nuke" }
unitList["BA"]["corfmd"] = { markerText = "Anti Nuke" }
unitList["BA"]["armsilo"] = { markerText = "Nuke" }
unitList["BA"]["corsilo"] = { markerText = "Nuke" }

unitList["CA"] = {} --initialize table
unitList["CA"]["armamd"] = { markerText = "Anti Nuke" }
unitList["CA"]["corfmd"] = { markerText = "Anti Nuke" }
unitList["CA"]["armsilo"] = { markerText = "Nuke" }
unitList["CA"]["corsilo"] = { markerText = "Nuke" }
unitList["CA"]["aafus"] = { markerText = "Tachyon gen" }
unitList["CA"]["cafus"] = { markerText = "Singularity gen" }
unitList["CA"]["corbhmth"] = { markerText = "Behemoth" }
unitList["CA"]["armbrtha"] = { markerText = "Berha" }
unitList["CA"]["corbeac"] = { markerText = "Zenith" }
unitList["CA"]["mahlazer"] = { markerText = "Starlight" }


unitList["CA1F"] = {} --initialize table
unitList["CA1F"]["armamd"] = { markerText = "Anti Nuke" }
unitList["CA1F"]["corfmd"] = { markerText = "Anti Nuke" }
unitList["CA1F"]["armsilo"] = { markerText = "Nuke" }
unitList["CA1F"]["corsilo"] = { markerText = "Nuke" }

unitList["CA1F"]["aafus"] = { markerText = "Tachyon gen" }
unitList["CA1F"]["cafus"] = { markerText = "Singularity gen" }
unitList["CA1F"]["corbhmth"] = { markerText = "Behemoth" }
unitList["CA1F"]["armbrtha"] = { markerText = "Berha" }
unitList["CA1F"]["corbeac"] = { markerText = "Zenith" }
unitList["CA1F"]["mahlazer"] = { markerText = "Starlight" }


--END OF MARKER LIST---------------------------------------

local markerTimePerId = 0.2 --400ms

local myPlayerID
local curModID
local updateInt = 1 --seconds for the ::update loop
local lastTimeUpdate = 0


local markersToSet = {} --this is a todo list filled with marker which have to be set, widget waits before setting them to see if another play tags them before to avoid multitagging
local knownUnits = {} --all units that have been marked already, so they wont get marked again

local spGetLocalTeamID	 	= Spring.GetLocalTeamID
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition     = Spring.GetUnitPosition
local spSendLuaUIMsg    	= Spring.SendLuaUIMsg
local spGetGameSeconds      = Spring.GetGameSeconds
local spMarkerAddPoint      = Spring.MarkerAddPoint
local spIsUnitAllied		= Spring.IsUnitAllied
local spGetMyPlayerID       = Spring.GetMyPlayerID
local spGetPlayerInfo       = Spring.GetPlayerInfo
local spEcho                = Spring.Echo

local upper                 = string.upper
local floor                 = math.floor

function widget:Initialize()
	myPlayerID = spGetLocalTeamID()
	curModID = upper(Game.modShortName or "")
	
	if ( unitList[curModID] == nil ) then
		spEcho("<Unit Marker> Unsupported Game, shutting down...")
		widgetHandler:RemoveWidget()
		return
	end
end

function widget:Update()
	local timef = spGetGameSeconds()
	local time = floor(timef)
	
	-- update timers once every <updateInt> seconds
	if (time % updateInt == 0 and time ~= lastTimeUpdate) then	
		lastTimeUpdate = time
		--do update stuff:
		
		if ( CheckSpecState() == false ) then
			return false
		end
	end
end

function widget:UnitEnteredLos(unitID, allyTeam)
	if ( spIsUnitAllied( unitID ) ) then
		return
	end

	local udefId = spGetUnitDefID(unitID)
	local udef = UnitDefs[udefId]
	local x, y, z = spGetUnitPosition(unitID)
	
	if (  unitList[curModID] ~= nil ) and (  unitList[curModID][udef.name] ~= nil ) and  ( unitList[curModID][udef.name]["markerText"] ~= nil ) then
		--the unit is in the list -> has to get marked
		if ( knownUnits[unitID] == nil ) or ( knownUnits[unitID] ~= udefId ) then
			--unit wasnt marked already or unit changed
			knownUnits[unitID] = udefId
			setMarkerForUnit( unitID, udef, { x,y,z }  )
		end
	end
end

function setMarkerForUnit( unitId, udef, pos )
	local markerText = unitList[curModID][udef.name]["markerText"]
	
	spSendLuaUIMsg("dfT" .. unitId, "allies")

	--printDebug( "Storing to markerQueue. UnitId #" .. unitId )
	markersToSet[unitId] = { time = spGetGameSeconds(), pos = pos, text = markerText }
end

--this one receives lua msgs from allied players. the player with the lowest id sets the marker first
--the others discard their markers when receiving a message from a lower player id
function widget:RecvLuaMsg(msg, playerID)
	if (msg:sub(1,3)=="dfT") then
		local unitId = tonumber( msg:sub( 4 ) ) -- take from pos 4 to the end
		--printDebug( "Df-Msg rcvd: Player " .. playerID .. " can tagged unitId: " .. unitId )
  		
		if (playerID==myPlayerID) then 
			--printDebug( "...from me")
			return true; 
		end

		if ( playerID < myPlayerID ) then
			--he is first, delete mine
			--printDebug( "Player #" .. playerID .. " is first. Removing my marker #" .. unitId )
			markersToSet[unitId] = nil
		end
	
		--printDebugTable( markersToSet )
		return true; 
	end
end

function widget:DrawWorld()
	local now = spGetGameSeconds()
	--printDebug(now)
	for k, marker in pairs( markersToSet ) do
		if ( now >= ( myPlayerID * markerTimePerId + marker["time"] ) ) then 
			spMarkerAddPoint( marker["pos"][1], marker["pos"][2], marker["pos"][3],  marker["text"] )
			markersToSet[k] = nil
		--else	printDebug("Key: " .. k .. " Waiting: " .. ( myPlayerID * markerTimePerId + marker["time"] ) - now .. "ms" )
		end
	end
end

function CheckSpecState()
	local playerID = spGetMyPlayerID()
	local _, _, spec, _, _, _, _, _ = spGetPlayerInfo(playerID)
		
	if ( spec == true ) then
		spEcho("<Unit Marker> Spectator mode. Widget removed.")
		widgetHandler:RemoveWidget()
		return false
	end
	
	return true	
end
