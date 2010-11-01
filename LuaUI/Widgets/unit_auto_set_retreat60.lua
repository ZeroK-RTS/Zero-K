local versionNumber = "1.2"

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
_ Set every units exiting from factories to retreat @60% automaticaly.
_ Set Commander to same value @ game start.
_ Set everything to 60% when reloaded (/luaui reload) as a safety.
_ Is disabled when player go spec/use replay. NEED TESTING TO KNOW IF WIDGET STOPS (and need to be reactivated) WHEN RE-JOINING GAME AFTER CRASH !!

-- to do : probably fusion with unit_news.lua.

Changelog:
-- versus666, 			v1.2	(01nov2010)	: .
-- versus666, 			v1.1	(18oct2010)	: added debug mode and optimised.
-- versus666, 			v1.0	(17oct2010)	: creation
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--CMD_RETREAT = 10000-- taken from CarRepairer widget, see no use, maybe a workaround

local Echo				= Spring.Echo
local spGetMyTeamID		= Spring.GetMyTeamID
local spGetTeamUnits	= Spring.GetTeamUnits
local spGetUnitDefID	= Spring.GetUnitDefID
local debug = false --generates debug message


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if (IsSpec()) then return false end
end

function IsSpec()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget()
		return true
	end
end

--function widget:GameStart()
-- init already present units
--	printDebug("<unit_auto_retreat60>: game start !")
--	checkUnits()
end

function checkUnits()
-- init already present units
	for _,unitID in ipairs(spGetTeamUnits(spGetMyTeamID())) do
	local unitDefID = spGetUnitDefID(unitID)
	local ud = UnitDefs[unitDefID]
		if ((ud ~= nil) and not (ud.isBuilding or not ud.canMove)) then -- test if exist and (is mobile and not a building) [I know buildings can't move but you never know]
			WG['retreat'].addRetreatCommand(unitID, unitDefID, 2)
			printDebug("<unit_auto_retreat60>: autorepair level 2 for unit : " .. unitID)
		end
	end
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam)
	printDebug("<unit_auto_retreat60> : unit from factory with ID: " .. unitID)
	if (unitTeam == spGetMyTeamID()) then 
		printDebug("<unit_auto_retreat60>: unit from factory 1st test, ID: " .. unitID)
		local ud = UnitDefs[unitDefID]
		if ((ud ~= nil) and (ud.canMove or not ud.isBuilding)) then	-- test if exist and (is mobile and not a building) [I know buildings can't move but you never know what some devs can do next]
			WG['retreat'].addRetreatCommand(unitID, unitDefID, 2)
			printDebug("<unit_auto_retreat60>: autorepair level 2 for unit : " .. unitID)
		end
	end
end

function widget:UnitCreated()-- need for resurected units
	printDebug("<unit_auto_retreat60>: unit created & set to 60% retreat !")
	checkUnits()
-- for chickens faction units, to do.
--end

function printDebug( value )
	if ( debug ) then Echo( value )
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------