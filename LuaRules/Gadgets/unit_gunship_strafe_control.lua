--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Strafe Control",
      desc      = "Adds toggle for strafe, enables propper hold position control",
      author    = "Google Frog",
      date      = "15 Dec 2010",
      license   = "GNU GPL, v2 or later",
      layer     = 0,
      enabled   = true
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end
---------------------------------

local CMD_AIR_STRAFE = Spring.Utilities.CMD.AIR_STRAFE
local CMD_ATTACK = CMD.ATTACK

local spMoveCtrlGetTag = Spring.MoveCtrl.GetTag

local airStrafeCmdDesc = {
	id      = CMD_AIR_STRAFE,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Strafe',
	action  = 'airstrafe',
	tooltip	= 'Toggles air strafing for gunships',
	params 	= {0, 'Strafe Off','Strafe On'}
}

local spInsertUnitCmdDesc  = Spring.InsertUnitCmdDesc
local spFindUnitCmdDesc    = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc    = Spring.EditUnitCmdDesc
local spMoveCtrlGetTag     = Spring.MoveCtrl.GetTag
local spSetAirMoveTypeData = Spring.MoveCtrl.SetAirMoveTypeData
local spGetUnitHeading     = Spring.GetUnitHeading
local spGetUnitVelocity    = Spring.GetUnitVelocity

local vecAngle  = Spring.Utilities.Vector.Angle
local vecAbsVal = Spring.Utilities.Vector.AbsVal

local wantedUnitDefs = {}
local strafeUnitDefs = {}
local turnRadiusUnitDefs = {}
local extendRadiusUnitDefs = {}

local turnRadiusExtended = {}
local nonStrafeWiggle = {}
local allowedCommandFrame = {}
local gameFrame = Spring.GetGameFrame()
local COMMAND_LEEWAY = 60
local WIGGLE_LEEWAY = 10

for id, data in pairs(UnitDefs) do
	if data.customParams and data.customParams.airstrafecontrol then
		strafeUnitDefs[id] = true
		wantedUnitDefs[id] = true
	end
	if data.customParams.extend_turn_radius then
		turnRadiusUnitDefs[id] = data.turnRadius
		extendRadiusUnitDefs[id] = tonumber(data.customParams.extend_turn_radius)
		wantedUnitDefs[id] = true
	end
end

local unitState = {}

--------------------------------------------------------------------------------
-- Plane turn radius control

local function ResetExtendTurnRadius(unitID, unitDefID, cmdID)
	if turnRadiusExtended[unitID] and not spMoveCtrlGetTag(unitID) then
		local attribute = {
			turnRadius = turnRadiusUnitDefs[unitDefID]
		}
		spSetAirMoveTypeData(unitID, attribute)
		--Spring.Utilities.UnitEcho(unitID, "RESET")
		turnRadiusExtended[unitID] = nil
	end
	allowedCommandFrame[unitID] = gameFrame + COMMAND_LEEWAY
end

function GG.PossiblySetExtendedTurnRadius(unitID, unitDefID)
	if (allowedCommandFrame[unitID] or 0) > gameFrame then
		return
	end
	if not spMoveCtrlGetTag(unitID) and not turnRadiusExtended[unitID] then
		local attribute = {
			turnRadius = extendRadiusUnitDefs[unitDefID]
		}
		--Spring.Utilities.UnitEcho(unitID, "EXT")
		spSetAirMoveTypeData(unitID, attribute)
		turnRadiusExtended[unitID] = true
	end
end

--------------------------------------------------------------------------------
-- Static wiggling

local HEADING_TO_RAD = (math.pi*2/2^16)
local cos = math.cos
local sin = math.sin

local function ResetNonStrafeWiggle(unitID, unitDefID, cmdID)
	if nonStrafeWiggle[unitID] then
		nonStrafeWiggle[unitID] = nil
	end
	allowedCommandFrame[unitID] = gameFrame + WIGGLE_LEEWAY
end

local function GetCommandPosition(cp_1, cp_2, cp_3)
	if cp_1 and not cp_3 then
		cp_1, cp_2, cp_3 = Spring.GetUnitPosition(cp_1)
	end
	return cp_1, cp_2, cp_3
end

function GG.PossiblyDoNonStrafeWiggle(unitID, unitDefID, wigglePeriod, baseMag)
	if ((allowedCommandFrame[unitID] or 0) > gameFrame) or spMoveCtrlGetTag(unitID) then
		return
	end
	if not (unitState[unitID] and not unitState[unitID].active) then
		return
	end
	local cmdID, _, cmdTag, cp_1, cp_2, cp_3 = Spring.GetUnitCurrentCommand(unitID)
	if not (cmdID == CMD_ATTACK or not cmdID) then
		return
	end
	local heading = Spring.GetUnitHeading(unitID)*HEADING_TO_RAD
	local cx, cy, cz = GetCommandPosition(cp_1, cp_2, cp_3)
	local angleDiff = 0
	local distance = 600
	if cz then
		local ux, _, uz = Spring.GetUnitPosition(unitID)
		if uz then
			local fireAngle = vecAngle(cz - uz, cx - ux)
			angleDiff = (fireAngle - heading)%(math.pi*2)
			if angleDiff > 3 then
				angleDiff = math.pi*2 - angleDiff
			end
			if angleDiff > 0.1 then
				return
			end
			distance = vecAbsVal(cz - uz, cx - ux)
		end
	end
	allowedCommandFrame[unitID] = gameFrame + wigglePeriod
	local _,_,_,speed = spGetUnitVelocity(unitID)
	local speedFactor = (speed + 8)/(speed+3)/(speed*speed*0.15 + 1)
	local hx = math.sin(heading)
	local hz = math.cos(heading)
	local distFactor = math.pow(math.min(550, distance)/550, 2)
	local wiggleMag = baseMag*speedFactor*(1 - angleDiff*4)*distFactor
	Spring.AddUnitImpulse(unitID, hz*wiggleMag, 0, -hx*wiggleMag)
	return true
end

--------------------------------------------------------------------------------
-- Command Handling

local function ToggleCommand(unitID, cmdParams, unitDefID)
	if unitState[unitID] and strafeUnitDefs[unitDefID] then
		if spMoveCtrlGetTag(unitID) ~= nil then
			return
		end
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_AIR_STRAFE)
		
		if (cmdDescID) then
			airStrafeCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = airStrafeCmdDesc.params})
		end
		unitState[unitID].active = (state == 1)
		Spring.MoveCtrl.SetGunshipMoveTypeData(unitID, {airStrafe = unitState[unitID].active})
	end
	
end

function gadget:AllowCommand_GetWantedCommand()
	return true
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return wantedUnitDefs
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_AIR_STRAFE) then
		ToggleCommand(unitID, cmdParams, unitDefID)
		return false -- command was used
	end
	if extendRadiusUnitDefs[unitDefID] then
		ResetExtendTurnRadius(unitID, unitDefID, cmdID)
	end
	if strafeUnitDefs[id] then
		ResetNonStrafeWiggle(unitID, unitDefID, cmdID)
	end
	return true -- command was not used
end

--------------------------------------------------------------------------------
-- Unit adding/removal

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_AIR_STRAFE)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	local ud = UnitDefs[unitDefID]
	if ud and strafeUnitDefs[unitDefID] then
		unitState[unitID] = {active = ud.airStrafe}
		spInsertUnitCmdDesc(unitID, airStrafeCmdDesc)
		if unitState[unitID].active then
			ToggleCommand(unitID, {1}, unitDefID)
		end
	end
end

function gadget:GameFrame(n)
	gameFrame = n
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	unitState[unitID] = nil
	turnRadiusExtended[unitID] = nil
	nonStrafeWiggle[unitID] = nil
end
