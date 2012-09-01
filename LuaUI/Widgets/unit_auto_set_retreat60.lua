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
_ Set every units exiting from factories to retreat @60% automatically. Don't trigger auto retreat for units being built.
_ Should set Commander to same value @ game start.
_ Is disabled when player go spec/use replay. NEED TESTING TO KNOW IF WIDGET STOPS (and need to be reactivated) WHEN RE-JOINING GAME AFTER CRASH !!

-- to do : probably fusion with unit_news.lua.

Changelog:
-- versus666,			v1.3b	(01mar2011)	: fixed logic.
-- versus666, 			v1.3	(07jan2011)	: changed detection logic to avoid to triger auto retreat for units being built. 
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
local spGetUnitHealth	= Spring.GetUnitHealth

local debug = false --generates debug message

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function IsSpec()
	 if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
		widgetHandler:RemoveWidget()
		return true
	end
end

function widget:Initialize()
	MyTeam = spGetMyTeamID()
	if (IsSpec()) then return false end
	-- init already present units, probably superfluous if CREATED is checked too
--[[	for _,unitID in ipairs(spGetTeamUnits(spGetMyTeamID())) do
		local unitDefID = spGetUnitDefID(unitID)
		--local ud = UnitDefs[unitDefID]
		--printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID " .. unitID .. " presence detected !")
		checkUnits(unitID,unitDefID)
	end
	--]]
end

function checkUnits(unitID,unitDefID,unitTeam)
	local ud = UnitDefs[unitDefID]
	--printDebug("<unit_auto_retreat60>: checking " .. " with ID " .. unitID .. " in team " .. unitTeam)
	if ((unitTeam == MyTeam) and ((ud ~= nil) and not (ud.isBuilding or not ud.canMove))) then -- test if exist and (is mobile and not a building) [I know buildings can't move but you never know]
			WG['retreat'].addRetreatCommand(unitID, unitDefID, 2)
		--printDebug("<unit_auto_retreat60>: set autorepair level 2 for " .. ud.humanName .. " with ID " .. unitID)
		--else printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID ".. unitID .. " & team " .. unitTeam .." NOT suitable -> rejected !")
		end
	end

--[[ function widget:UnitFromFactory(unitID,unitDefID,unitTeam) -- every 'from factory' is created BUT autoretreat makes them retreat if retreat is set while they are built.
	printDebug("<unit_auto_retreat60> : unit " .. unitID .. " from factory detected !")
	checkUnits(unitID,unitDefID,unitTeam)
end ]]--

function widget:UnitCreated(unitID,unitDefID,unitTeam)-- needed for resurrected units/spawned units. check health to know if they are being built.
	--local ud = UnitDefs[unitDefID]
	--printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID " .. unitID .. " and team " .. unitTeam .. " created detected !")
	local health = spGetUnitHealth(unitID)
	--printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID " .. unitID .. " just created have a health of " .. health)
	if health >= 0.3 then
	checkUnits(unitID,unitDefID,unitTeam)
	else
		--printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID " .. unitID .. " is  being built :  do not touch yet.")
		return end
end

function widget:UnitFinished(unitID,unitDefID,unitTeam)--  every 'from factory' is also finished after being created BUT autoretreat makes them retreat if retreat is set while they are built.
	--local ud = UnitDefs[unitDefID]
	--printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID ".. unitID .. " finished detected !")
	checkUnits(unitID,unitDefID,unitTeam)
end

function widget:UnitTaken(unitID,unitDefID,unitTeam)-- needed for taken units
	--local ud = UnitDefs[unitDefID]
	--printDebug("<unit_auto_retreat60>: " .. ud.humanName .. " with ID ".. unitID .. " taken detected !")
	checkUnits(unitID,unitDefID,unitTeam)
end

function printDebug( value )
	if ( debug ) then Echo( value )
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------