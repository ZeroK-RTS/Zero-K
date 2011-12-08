local versionNumber = "1.3.9"

function widget:GetInfo()
	return {
		name	= "Unit Marker Zero-K",
		desc	= "[v" .. string.format("%s", versionNumber ) .. "] Marks spotted buildings of interest and commander corpse.",
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
-Is disabled when player go spec/use replay. NEED TESTING TO KNOW IF WIDGET STOPS (and need to be reactivated) WHEN RE-REJOINING GAME AFTER CRASH !

---- TODO ----
erase markers when units die.

---- CHANGELOG -----
-- kingraptor,			v1.3.8	(29nov2010)	: made widget not suck
-- versus666,			v1.3.7	(10nov2010)	: tested many ways to check for comm death/morph and used the most reliable.
-- versus666,			v1.3.6	(04oct2010)	: commented the commander death warning part until I find a reliable ways to check for commanders morphs. Re added ROOST in PoI as it's an important building in chicken games and it have AA.
-- kingraptor,			v1.3.5	(04oct2010)	: moved chickens PoI to general list and commented out isChickenGame().
-- versus666, 			v1.3.4	(01nov2010)	: added marker where own commander die + message to allies, removed other mods refs. Old CA refs left for now as it may be useful to a LUA (beginner or not) even just as an exemple.
-- versus666, 			v1.3.3	(29oct2010)	: added IsSpec & isChickenGame for more PoI for chicken games and cleaned code.
-- versus666,			v1.3.2	(28oct2010)	: added chickens buildings.
-- versus666,			v1.2.1	(08seot2010): added compatibility to CA1F.
--		?				v1.3				: fixed: double markers for one unit.
--		?				v1.2				: added XTA support (thx to manolo_), deactivates older defense range widget (thx to TFC).
--		?				v1.1				: auto-disable when spec.
-- very_bad_soldier,	v1.0	(21oct2007)	: initial release.
--]]
local debug = false --generates debug message
local firstUnitID --for 1rst check when comm die
local secondUnitID -- for 2nd check when comm die

local unitList = {}
--MARKER LIST ------------------------------------
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
unitList["CA"]["starlight"] =	{ markerText = "Starlight" }
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

unitList["ZK"] = {} --initialize table, should contain ZK buildings currently used.
unitList["ZK"]["armamd"] =		{ markerText = "Anti Nuke" }
unitList["ZK"]["corsilo"] =		{ markerText = "Nuke" }
--unitList["ZK"]["missilesilo"] =	{ markerText = "Missile Silo" }
--unitList["ZK"]["armbrtha"] =		{ markerText = "Big Bertha" }
--unitList["ZK"]["corbhmth"] =		{ markerText = "Behemoth" }
--unitList["ZK"]["armanni"] =		{ markerText = "Annihilator" }
--unitList["ZK"]["cordoom"] =		{ markerText = "Doomsday" }
unitList["ZK"]["starlight"] =		{ markerText = "Starlight" }
unitList["ZK"]["cafus"] =			{ markerText = "Singularity Reactor" }
--unitList["ZK"]["armfus"] =		{ markerText = "Fusion Reactor" }
--unitList["ZK"]["amgeo"] =			{ markerText = "Moho Geo" }
--unitList["ZK"]["geo"] =			{ markerText = "Geo" }
--unitList["ZK"]["roost"] =				{ markerText = "Roost" }
--unitList["ZK"]["chickenspire"] =		{ markerText = "Spire" }
unitList["ZK"]["chicken_dragon"] =	{ markerText = "White Dragon" }
unitList["ZK"]["chickenflyerqueen"] =	{ markerText = "Chicken Queen Aerial" }
unitList["ZK"]["chickenlandqueen"] =	{ markerText = "Chicken Queen Grounded" }
unitList["ZK"]["chickenqueenlite"] =	{ markerText = "Chicken Queen Junior" }

--END OF MARKER LIST---------------------------------------
local markerTimePerId = 0.2 --400ms

local myPlayerID
local curModID
local myName

local updateInt = 1 --seconds for the ::update loop
local lastTimeUpdate = 0

local markersToSet = {} --this is a todo list filled with marker which have to be set, widget waits before setting them to see if another play tags them before to avoid multitagging
local knownUnits = {} --all units that have been marked already, so they wont get marked again

--local myTeamID	 = Spring.GetLocalTeamID
local GetMyTeamID			= Spring.GetMyTeamID
local GetUnitTeam			= Spring.GetUnitTeam
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
local spGetLastAttacker		= Spring.GetUnitLastAttacker

local function CheckSpecState()
	if (Spring.GetSpectatingState() or Spring.IsReplay()) then
		Echo("<Unit Marker> Spectator mode or replay. Widget removed.")
		widgetHandler:RemoveWidget()
	end
end

function widget:Initialize()
	printDebug("<Unit Marker>: init")
	CheckSpecState()
	myPlayerID = spGetLocalPlayerID() --spGetMyPlayerID() --spGetLocalTeamID()
	myName = Spring.GetPlayerInfo(myPlayerID)
	curModID = upper(Game.modShortName or "")
	printDebug("<Unit Marker DEBUG>: my Player ID: " .. myPlayerID .. " myname " .. myName .. " MOD ID: " .. curModID)
	if ( unitList[curModID] == nil ) then
		Echo("<Unit Marker>: unsupported Mod, shutting down...")
		widgetHandler:RemoveWidget()
		return
	end

--[[	if (unitList[curModID] == "ZK" and check for GameRule 'difficulty' showing presence of chicken game (weird and a bit unreliable in the futur but easy) as there seems to be no way to extract info from luaAI.lua data. If someone know a better method please do.
	if (curModID =="ZK" and isChickenGame()) then --mod ->ZK
		--add chicken game POI markers
		unitList["ZK"]["roost"] =				{ markerText = "Roost" }
		unitList["ZK"]["roostfact"] =			{ markerText = "Roostfact" }
		unitList["ZK"]["chickend"] =			{ markerText = "Tube" } --regular orange tube
		unitList["ZK"]["chickenspire"] =		{ markerText = "Spire" } -- green tube-of-death
		unitList["ZK"]["nest"] =				{ markerText = "Nest" }
		unitList["ZK"]["chicken_dragon"] =	{ markerText = "White Dragon" }
		unitList["ZK"]["chickenflyerqueen"] =	{ markerText = "Chicken Queen" }
	end
	]]--
end

 --[[	--really pointless, markers can just be added by default
function isChickenGame()
	if (Spring.GetGameRulesParam("difficulty")) then
		printDebug("<Unit Marker DEBUG>: chicken game detected, new PoI markers added.")
		return true
		else printDebug("<Unit Marker DEBUG>: normal game detected, normal PoI markers used.")
	end
end 
]]--

-- what is this function even trying to do?
function widget:Update()
	local timef = spGetGameSeconds()
	local time = floor(timef)
	-- update timers once every <updateInt> seconds
	if (time % updateInt == 0 and time ~= lastTimeUpdate) then	
		lastTimeUpdate = time
		--do update stuff:
		CheckSpecState()
	end
end

function widget:UnitEnteredLos(unitID, unitTeam)
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
		printDebug ( markersToSet ) -- print table of units to mark
		return true; 
	end
end

--function markedUnits() -- to remember marked ones to erase their marker once dead.
--(local x, y, z = Spring.GetUnitPosition(unitID))
--for i,  iterate markedunits array
--if destroyed id=markedunit id then
-- -- Spring.MarkerErasePosition(x, y, z)
--end


function widget:DrawWorld()
	local now = spGetGameSeconds()
	--printDebug(now)
	for k, marker in pairs( markersToSet ) do
if ( now >= ( myPlayerID * markerTimePerId + marker["time"] ) ) then 
			spMarkerAddPoint( marker["pos"][1], marker["pos"][2], marker["pos"][3],  marker["text"] )
			--markedunits(unitID, marker["pos"][1], marker["pos"][2], marker["pos"][3])
			printDebug(unitID, marker["pos"][1], marker["pos"][2], marker["pos"][3])
			printDebug(markersToSet[k])
			markersToSet[k] = nil
		--else	printDebug("Key: " .. k .. " Waiting: " .. ( myPlayerID * markerTimePerId + marker["time"] ) - now .. "ms" )
		end
	end
end
--[[ ]]--
function widget:UnitDestroyed(unitID, unitDefID, unitTeam) --to do: use this to remove markers
--[[	local killer = spGetLastAttacker(unitID) -- last attacker does NOT register splash or wide radius attack, only direct attack.
	if killer == nil then
			Echo("<Unit Marker>: killer is nil.")
	else Echo("<Unit Marker>: killer is " .. killer )
	end
	local teamID = GetUnitTeam(unitID)
	ud = UnitDefs[unitDefID]
	Echo ("<Unit Marker>: " .. unitID .. " from team " .. teamID .. " died.")
	if (ud.customParams.commtype) then --and (teamID == GetMyTeamID()) then
		Echo("<Unit Marker>: " .. unitID .. " is comm !")
		spMarkerAddPoint( x, y, z)
		if killer == nil then
			Echo("<Unit Marker>: Your commander is upgraded.")
		else Echo("<Unit Marker>: comm killed")
			spMarkerAddPoint( x, y, z, myName .. "\nCommander corpse")
			Spring.SendCommands({'say a:I lost my commander !'})
		end
	end ]]--


	local unitTeamID = GetUnitTeam(unitID)
	ud = UnitDefs[unitDefID]
	local x, y, z = spGetUnitPosition(unitID)
	if (ud.customParams.commtype) and (unitTeamID == GetMyTeamID()) then
		printDebug("<Unit Marker>: " .. unitID .. " is comm !")
		firstUnitID = unitID
		unitChecked = Spring.GetUnitsInRectangle (x-1, z-1, x+1, z+1) -- ( number xmin, number zmin, number xmax, number zmax [,number teamID] )
		if unitChecked[1] ~= nil then
			printDebug( "<Unit Marker>: something found !")
			for _,unitID in ipairs (unitChecked) do
				printDebug("<Unit Marker>: Found this : " .. unitID )
				secondUnitID = unitID
				if ( secondUnitID == firstUnitID ) then
					--spMarkerAddPoint( x, y, z, myName .. "\nComm\ncorpse")	-- not really important enough to merit a marker
					--Spring.SendCommands({'say a:I lost my commander !'})	--would it kill you to actually check for spec state before doing this?
				else
					ud = UnitDefs[unitDefID]
					if (ud.customParams.commtype) and (unitTeamID == GetMyTeamID()) then
						Echo ("<Unit Marker>: Your commander is upgraded.")
					return end 
				return end
			end
		else printDebug("<Unit Marker>: nothing found, very weird!")
		end
	else printDebug(unitID .. " is NOT comm !")
	return end 
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