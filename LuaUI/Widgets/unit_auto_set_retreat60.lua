local versionNumber = "1.3"

function widget:GetInfo()
	return {
	name		= "Auto Set Retreat @60",
	desc		= "[v" .. string.format("%s", versionNumber ) .. "] Automatically set units when built to 'Retreat at 60% health', support /luaui reload (re-set retreat for every unit). Based on 'Auto Retreat' by CarRepairer",
	author		= "versus666",
	date		= "Oct 17, 2010",
	license		= "GNU GPL, v2 or later",
	layer		= 1,
	enabled		= false  --  loaded by default?
	}
end
--[[
Features:
_ Set every units exiting from factories to retreat @60% automatically. Don't trigger auto retreat.
_ Set Commander to same value @ game start.
_ Set everything to 60% when reloaded (/luaui reload) as a safety.
_ Is disabled when player go spec/use replay. NEED TESTING TO KNOW IF WIDGET STOPS (and need to be reactivated) WHEN RE-JOINING GAME AFTER CRASH !!

-- to do : probably fusion with unit_news.lua.

Changelog:
-- versus666, 			v1.3	(07jan2011)	: changed detection logic to avoid to triger auto retreat for units being built. Doesn't check
-- versus666, 			v1.2	(01nov2010)	: some changes.
-- versus666, 			v1.1	(18oct2010)	: added debug mode and optimised.
-- versus666, 			v1.0	(17oct2010)	: creation.
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--CMD_RETREAT = 10000-- taken from CarRepairer widget, see no use, maybe a workaround

local Echo				= Spring.Echo
local spGetMyTeamID		= Spring.GetMyTeamID
local spGetTeamUnits	= Spring.GetTeamUnits
local spGetUnitDefID	= Spring.GetUnitDefID
local spGetUnitTeam		= Spring.GetUnitTeam
local debug = false --generates debug message

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function IsSpec()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget()
		return true
	end
end

function widget:Initialize()
	MyTeam = spGetMyTeamID()
	if (IsSpec()) then return false end
	-- init already present units
	for _,unitID in ipairs(spGetTeamUnits(spGetMyTeamID())) do
		local unitDefID = spGetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID " .. unitID .. " presence detected !")
		checkUnits(unitID,unitDefID)
	end
end

function checkUnits(unitID,unitDefID)
	local ud = UnitDefs[unitDefID]
	printDebug("<unit_auto_retreat60>: checking " .. ud.humanName .. " with ID " .. unitID .. " in team " .. spGetUnitTeam(unitID))
	if ((spGetUnitTeam(unitID) == MyTeam) and ((ud ~= nil) and not (ud.isBuilding or not ud.canMove))) then -- test if exist and (is mobile and not a building) [I know buildings can't move but you never know]
			WG['retreat'].addRetreatCommand(unitID, unitDefID, 2)
			printDebug("<unit_auto_retreat60>: set autorepair level 2 for " .. ud.humanName .. " with ID " .. unitID)
		else printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID ".. unitID .. " NOT suitable -> rejected !")
		end
	end

--[[function widget:UnitFromFactory(unitID, unitDefID, unitTeam)
	printDebug("<unit_auto_retreat60> : unit " .. unitID .. " from factory detected !")
	checkUnits(unitID)
end]]--

function widget:UnitCreated(unitID,unitDefID)-- needed for resurrected units
	local ud = UnitDefs[unitDefID]
	printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID" .. unitID .. " created detected !")
	checkUnits(unitID)
end

function widget:UnitFinished(unitID)-- test
	local ud = UnitDefs[unitDefID]
	printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID ".. unitID .. " finished detected !")
	checkUnits(unitID)
end

function widget:UnitTaken(unitID)-- needed for taken units
	local ud = UnitDefs[unitDefID]
	printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID ".. unitID .. " taken detected !")
	checkUnits(unitID)
end

--[[
function widget:UnitIdle()-- test, check if executed every frame -> bad
	printDebug("<unit_auto_retreat60>: unit idle detected !")
	checkUnits()
end
	]]--
	
function printDebug( value )
	if ( debug ) then Echo( value )
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------