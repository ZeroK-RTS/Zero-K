local versionNumber = "1.3.4"

function widget:GetInfo()
	return {
		name	= "Unit Marker compatible Zero-K",
		desc	= "[v" .. string.format("%s", versionNumber ) .. "] Marks spotted buildings of interest. Support ZK chicken games",
		author	= "very_bad_soldier",
		date	= "October 21, 2007 / September 08, 2010",
		license	= "GNU GPL v2",
		layer	= 0,
		enabled	= true
	}
end

--[[
Features:
-multiple mod support, deactivate if used on unknown mod.
-no multiple markers if multiple players use it.
-check for ZK chicken game to add more PoI.
- Is disabled when player go spec/use replay. NEED TESTING TO KNOW IF WIDGET STOPS (and need to be reactivated) WHEN RE-REJOINING GAME AFTER CRASH !!
---- TODO ----
Probably erase the BA & XTA config as this is a ZK only widget. Left for now as it may be useful to a LUA (beginner or not) even just as an exemple.
---- CHANGELOG -----
-- versus666, 			v1.3.4	(01nov2010)	: added marker where own commander die + message to allies.
-- versus666, 			v1.3.3	(29oct2010)	: added IsSpec & isChickenGame for more PoI for chicken games and cleaned code.
-- versus666,			v1.3.2	(28oct2010)	: added chickens buildings.
-- versus666,			v1.2.1	(08seot2010): added compatibility to CA1F.
--		?				v1.3				: fixed: double markers for one unit.
--		?				v1.2				: added XTA support (thx to manolo_), deactivates older defense range widget (thx to TFC).
--		?				v1.1				: auto-disable when spec.
-- very_bad_soldier,	v1.0	(21oct2007)	: initial release.
--]]
local debug = false --generates debug message

local unitList = {}
--MARKER LIST ------------------------------------ NEED TO UPDATE CA1F TO ZK WHEN MOD DO.
unitList["BA"] = {} --initialize table
unitList["BA"]["armamd"] = { markerText = "Anti Nuke" }
unitList["BA"]["corfmd"] = { markerText = "Anti Nuke" }
unitList["BA"]["armsilo"] = { markerText = "Nuke" }
unitList["BA"]["corsilo"] = { markerText = "Nuke" }

unitList["CA"] = {} --initialize table
unitList["CA"]["armamd"] =		{ markerText = "Anti Nuke" }
unitList["CA"]["corfmd"] =		{ markerText = "Anti Nuke" }
unitList["CA"]["armsilo"] =		{ markerText = "Nuke" }
unitList["CA"]["corsilo"] =		{ markerText = "Nuke" }
unitList["CA"]["nest"] =		{ markerText = "Nest" }
unitList["CA"]["thicket"] =		{ markerText = "Thicket" }
unitList["CA"]["corint"] =		{ markerText = "Intimidator" }
unitList["CA"]["corbhmth"] =	{ markerText = "Behemoth" }
unitList["CA"]["armbrtha"] =	{ markerText = "Big Bertha" }
unitList["CA"]["kettle"] =		{ markerText = "Kettle" }
unitList["CA"]["starlight"] =	{ markerText = "Mah Lazer" }
unitList["CA"]["corebeac"] =	{ markerText = "Zenith" }
unitList["CA"]["corfus"] =		{ markerText = "Graviton Power Gen" }
unitList["CA"]["cafus"] =		{ markerText = "Singularity Reactor" }
unitList["CA"]["armfus"] =		{ markerText = "Fusion Reactor" }
unitList["CA"]["aafus"] =		{ markerText = "Tachyon Collider" }
unitList["CA"]["cmgeo"] =		{ markerText = "MOHO GEO" }
unitList["CA"]["amgeo"] =		{ markerText = "MOHO GEO" }
unitList["CA"]["armgmm"] =		{ markerText = "Prude" }
unitList["CA"]["armgeo"] =		{ markerText = "Geo" }
unitList["CA"]["corgeo"] =		{ markerText = "Geo" }
unitList["CA1F"] = {} --initialize table, should contain ZK buildings currently used.
unitList["CA1F"]["armamd"] =		{ markerText = "Anti Nuke" }
unitList["CA1F"]["corsilo"] =		{ markerText = "Nuke" }
unitList["CA1F"]["missilesilo"] =	{ markerText = "Missle Silo" }
unitList["CA1F"]["armbrtha"] =		{ markerText = "Big Bertha" }
unitList["CA1F"]["corbhmth"] =		{ markerText = "Behemoth" }
unitList["CA1F"]["armanni"] =		{ markerText = "Annihilator" }
unitList["CA1F"]["cordoom"] =		{ markerText = "Doomsday" }
unitList["CA1F"]["starlight"] =		{ markerText = "Mah Lazer" }
unitList["CA1F"]["cafus"] =			{ markerText = "Singularity Reactor" }
unitList["CA1F"]["armfus"] =		{ markerText = "Fusion Reactor" }
unitList["CA1F"]["amgeo"] =			{ markerText = "Moho Geo" }
unitList["CA1F"]["armgeo"] =		{ markerText = "Geo" }
--END OF MARKER LIST---------------------------------------
local markerTimePerId = 0.2 --400ms

local myPlayerID
local curModID
local updateInt = 1 --seconds for the ::update loop
local lastTimeUpdate = 0

local markersToSet = {} --this is a todo list filled with marker which have to be set, widget waits before setting them to see if another play tags them before to avoid multitagging
local knownUnits = {} --all units that have been marked already, so they wont get marked again

--local spGetLocalTeamID	 = Spring.GetLocalTeamID
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitPosition		= Spring.GetUnitPosition
local spSendLuaUIMsg		= Spring.SendLuaUIMsg
local spGetGameSeconds		= Spring.GetGameSeconds
local spMarkerAddPoint		= Spring.MarkerAddPoint
local spIsUnitAllied		= Spring.IsUnitAllied
local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local Echo					= Spring.Echo
local spGetPlayerList		= Spring.GetPlayerList
local spArePlayersAllied	= Spring.ArePlayersAllied
local spGetLocalPlayerID 	= Spring.GetLocalPlayerID
local spGetSideData			= Spring.GetSideData
local spGetSpectatingState	= Spring.GetSpectatingState
local spIsReplay			= Spring.IsReplay
local upper					= string.upper
local floor					= math.floor
local max					= math.max
local min					= math.min

function widget:Initialize()
	--Echo("<Unit Marker>: init")
	if isSpec then
		Echo("<Unit Marker>: Spectator mode or replay. Widget removed.")
		widgetHandler:RemoveWidget()
	end

myPlayerID = spGetLocalPlayerID() --spGetMyPlayerID() --spGetLocalTeamID()
curModID = upper(Game.modShortName or "")
printDebug("<Unit Marker DEBUG>: my Player ID: " .. myPlayerID .. "MOD ID: " .. curModID)
	if ( unitList[curModID] == nil ) then
		Echo("<Unit Marker>: unsupported Mod, shutting down...")
		widgetHandler:RemoveWidget()
		return
	end

--	if (unitList[curModID] == "CA1F" and check for GameRule 'difficulty' showing presence of chicken game (weird and a bit unreliable in the futur but easy) as there seems to be no way to extract info from luaAI.lua data. If someone know a better method please do.
	if (curModID =="CA1F" and isChickenGame()) then --mod CA1F->ZK
		--add chicken game POI markers
		unitList["CA1F"]["roost"] =				{ markerText = "Roost" }
		unitList["CA1F"]["roostfact"] =			{ markerText = "Roostfact" }
		unitList["CA1F"]["chickend"] =			{ markerText = "Tube" } --regular orange tube
		unitList["CA1F"]["chickenspire"] =		{ markerText = "Spire" } -- green tube-of-death
		unitList["CA1F"]["nest"] =				{ markerText = "Nest" }
		unitList["CA1F"]["chicken_dragon"] =	{ markerText = "White Dragon" }
		unitList["CA1F"]["chickenflyerqueen"] =	{ markerText = "Chicken Queen" }
	end
end

function IsSpec()
		if spGetSpectatingState or spIsReplay then
		return true
	end
end

function isChickenGame()
	if (Spring.GetGameRulesParam("difficulty")) then
		printDebug("<Unit Marker DEBUG>: chicken game detected, new PoI markers added.")
		return true
		else printDebug("<Unit Marker DEBUG>: normal game detected, normal PoI markers used.")
	end
end

function widget:Update()
	local timef = spGetGameSeconds()
	local time = floor(timef)
	-- update timers once every <updateInt> seconds
	if (time % updateInt == 0 and time ~= lastTimeUpdate) then	
		lastTimeUpdate = time
		--do update stuff:
		if ( not IsSpec ) then
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
	
	if ( unitList[curModID] ~= nil ) and ( unitList[curModID][udef.name] ~= nil ) and  ( unitList[curModID][udef.name]["markerText"] ~= nil ) then
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
	printDebug("<Unit Marker DEBUG>: storing to markerQueue. UnitId #" .. unitId )
	markersToSet[unitId] = { time = spGetGameSeconds(), pos = pos, text = markerText }
end
--this one receives lua msgs from allied players. the player with the lowest id sets the marker first
--the others discard their markers when receiving a message from a lower player id
function widget:RecvLuaMsg(msg, playerID)
	if (msg:sub(1,3)=="dfT") then
		local unitId = tonumber( msg:sub( 4 ) ) -- take from pos 4 to the end
		printDebug( "<Unit Marker DEBUG>: df-Msg rcvd: player " .. playerID .. " can tag unitId: " .. unitId )
		if (playerID==myPlayerID) then 
			printDebug( "...from me")
			return true; 
		end
		if ( playerID < myPlayerID ) then
			--he is first, delete mine
			printDebug("<Unit Marker DEBUG>: player #" .. playerID .. " is first. Removing my marker #" .. unitId )
			markersToSet[unitId] = nil
		end
		--printDebugTable( markersToSet )
		return true; 
	end
end

function widget:DrawWorld()
	local now = spGetGameSeconds()
	printDebug(now)
	for k, marker in pairs( markersToSet ) do
if ( now >= ( myPlayerID * markerTimePerId + marker["time"] ) ) then 
			spMarkerAddPoint( marker["pos"][1], marker["pos"][2], marker["pos"][3],  marker["text"] )
			markersToSet[k] = nil
		--else	printDebug("Key: " .. k .. " Waiting: " .. ( myPlayerID * markerTimePerId + marker["time"] ) - now .. "ms" )
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID)-- to do: use this to remove markers
 local ud = UnitDefs[unitDefID]
	if (ud.isCommander==true) then
		local x, y, z = spGetUnitPosition(unitID)
		local myName	= Spring.GetPlayerInfo(Spring.GetMyPlayerID())
		spMarkerAddPoint( x, y, z, myName .. "\nCommander corpse")
		Spring.SendCommands({'say a:I lost my commander !'})
	end
end

function printDebug( value )
	if ( debug ) then
		if ( type( value ) == "boolean" ) then
			if ( value == true ) then Echo( "true" )
				else Echo("false") end
		elseif ( type(value ) == "table" ) then
			Echo("Dumping table:")
			for key,val in pairs(value) do 
				Echo(key,val) 
			end
		else
			Echo( value )
		end
	end
end
-------
-------