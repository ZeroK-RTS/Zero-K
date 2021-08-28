--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Ward Fire",
		desc      = "Tells some units to fire near particular targets.",
		author    = "GoogleFrog",
		date      = "27 February 2021",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedups

local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitVelocity     = Spring.GetUnitVelocity
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spIsPosInLos          = Spring.IsPosInLos
local spGetGroundHeight     = Spring.GetGroundHeight
local sqrt                  = math.sqrt

local GetEffectiveWeaponRange = Spring.Utilities.GetEffectiveWeaponRange

local UPDATE_RATE = 20
local MEX_UPDATE_RATE = 35
local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local unitAIBehaviour = include("LuaRules/Configs/tactical_ai_defs.lua")
local mexShootBehaviour = include("LuaRules/Configs/mex_shoot_defs.lua")

local MEX_DEF_ID = UnitDefNames["staticmex"].id

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

local wardUnits = IterableMap.New()
local mexUnits = IterableMap.New()

local doDebug = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Commands

local CMD_MOVE         = CMD.MOVE
local CMD_ATTACK       = CMD.ATTACK
local CMD_FIGHT        = CMD.FIGHT
local CMD_WAIT         = CMD.WAIT
local CMD_OPT_INTERNAL = CMD.OPT_INTERNAL
local CMD_OPT_RIGHT    = CMD.OPT_RIGHT
local CMD_INSERT       = CMD.INSERT
local CMD_REMOVE       = CMD.REMOVE

include("LuaRules/Configs/customcmds.h.lua")

local wardFireCmdDesc = {
	id      = CMD_WARD_FIRE,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Ward Fire',
	action  = 'wardfire',
	tooltip = 'Toggles warding fire for the unit',
	params  = {0, 'Ward Off', 'Ward On'}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- Common Funcs

local function IsTooBusyToFire(unitID, unitData)
	if (not unitData.active) then
		return true
	end
	if GG.GetUnitHasSetTarget(unitID) then
		return true, GG.GetUnitTarget(unitID)
	end
	
	local cmdID, cmdOpts, cmdTag, cp_1, cp_2, cp_3 = Spring.GetUnitCurrentCommand(unitID)
	if (cmdID == CMD_ATTACK and not Spring.Utilities.CheckBit(DEBUG_NAME, cmdOpts, CMD.OPT_INTERNAL)) then
		-- Manual attack commands should disable this behaviour
		return true, (not cp_2) and cp_1
	end
	local baitLevel = (GG.baitPrevention_GetLevel and GG.baitPrevention_GetLevel(unitID)) or 0
	if baitLevel > 2 then
		return true
	end
	if (Spring.Utilities.GetUnitFireState(unitID) ~= 2) then
		return true
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- Unit Ward Behaviour

local function DoUnitUpdate(unitID, unitData)
	if doDebug then
		Spring.Echo("===== DEBUG WARD FIRE", unitID, "=====")
		Spring.Echo("act", unitData.active, "fire", Spring.Utilities.GetUnitFireState(unitID), "hasTarget", GG.GetUnitHasSetTarget(unitID), "bait", GG.baitPrevention_GetLevel(unitID))
	end
	if IsTooBusyToFire(unitID, unitData) then
		return
	end
	local behaviour = unitData.def
	
	local enemyID = spGetUnitNearestEnemy(unitID, behaviour.searchRange, true)
	local enemyUnitDefID = enemyID and spGetUnitDefID(enemyID)
	
	if doDebug then
		Spring.Echo("enemyID", enemyID, "enemyUnitDefID", enemyUnitDefID, "def", enemyUnitDefID and behaviour.wardFireTargets[enemyUnitDefID])
	end
	
	if not (enemyUnitDefID and behaviour.wardFireTargets[enemyUnitDefID]) then
		return
	end
	
	if behaviour.wardFireShield then
		local enabled, charge = Spring.GetUnitShieldState(enemyID)
		charge = charge or 0
		if (not enabled) or charge < behaviour.wardFireShield then
			return
		end
	end
	
	--Spring.Utilities.UnitEcho(enemyID)
	local targetLeeway = behaviour.wardFireTargets[enemyUnitDefID]
	
	local vx, vy, vz, enemySpeed = spGetUnitVelocity(enemyID)
	local ex, ey, ez, _, aimY = spGetUnitPosition(enemyID, false, true) -- enemy position
	local ux, uy, uz = spGetUnitPosition(unitID) -- my position

	if doDebug then
		Spring.Echo("ex and vx", ex, vx)
	end
	
	if not (ex and vx) then
		return
	end
	
	ey = aimY or ey
	-- The e vector is relative to unit position
	ex, ey, ez = ex - ux, ey - uy, ez - uz
	
	local predict = behaviour.wardFirePredict or 0
	-- The d vector is also relative to unit position.
	local dx, dy, dz = ex + vx*predict, ey + vy*predict, ez + vz*predict
	local eDistSq = ex^2 + ey^2 + ez^2
	local eDist = sqrt(eDistSq)
	-- Scalar projection of prediction vector onto enemy vector
	local predProj = (ex*dx + ey*dy + ez*dz)/eDistSq

	-- Calculate predicted enemy distance
	local predictedDist = eDist
	if predProj > 0 then
		predictedDist = predictedDist*predProj
	else
		-- In this case the enemy is predicted to go past me
		predictedDist = 0
	end
	
	local effectiveRange = (GetEffectiveWeaponRange(unitData.unitDefID, -dy, behaviour.weaponNum) or 0)
	if effectiveRange then
		local wardFireRange = (effectiveRange - behaviour.wardFireLeeway)

		if doDebug then
			Spring.Echo("targetLeeway", effectiveRange + targetLeeway, effectiveRange, predictedDist)
		end
		
		if effectiveRange + targetLeeway > predictedDist and effectiveRange + behaviour.wardFireLeeway + behaviour.wardFireEnableLeeway < predictedDist then
			local tx, tz = ux + wardFireRange*dx/predictedDist, uz + wardFireRange*dz/predictedDist
			if doDebug then
				Spring.MarkerAddPoint(tx, 0, tz, "F")
			end
			local ty = math.max(0, Spring.GetGroundHeight(tx, tz)) + behaviour.wardFireHeight
			GG.SetTemporaryPosTarget(unitID, tx, ty, tz, false, UPDATE_RATE)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- Mex Shooting Behaviour

local function GetMexPos(unitID, behaviour, enemyID)
	if enemyID then
		local x, _, z = spGetUnitPosition(enemyID)
		return x, z
	end
	if GG.GetClosestMetalSpot then
		local x, _, z = spGetUnitPosition(unitID)
		local spot = GG.GetClosestMetalSpot(x, z, behaviour.weaponRange)
		if spot then
			return spot.x, spot.z
		end
	end
	return false
end

local function DoMexShootUnitUpdate(unitID, unitData)
	if doDebug then
		Spring.Echo("===== DEBUG MEX FIRE", unitID, "=====")
		Spring.Echo("act", unitData.active, "fire", Spring.Utilities.GetUnitFireState(unitID), "hasTarget", GG.GetUnitHasSetTarget(unitID), "bait", GG.baitPrevention_GetLevel(unitID))
	end
	local busy, busyUnitID = IsTooBusyToFire(unitID, unitData)
	if busy and not (busyUnitID and spGetUnitDefID(busyUnitID) == MEX_DEF_ID) then
		return
	end
	local behaviour = unitData.def
	
	local enemyID = busyUnitID or spGetUnitNearestEnemy(unitID, behaviour.searchRange, true)
	local enemyUnitDefID = enemyID and spGetUnitDefID(enemyID)
	if enemyID and enemyUnitDefID ~= MEX_DEF_ID then
		return
	end
	
	local spotX, spotZ = GetMexPos(unitID, behaviour, enemyID)
	if not spotX then
		return
	end
	if (not enemyID) and spIsPosInLos(spotX, 0, spotZ, unitData.allyTeamID) then
		return
	end
	local spotY = math.max(0, CallAsTeam(unitData.teamID, function () return spGetGroundHeight(spotX, spotZ) end))
	
	if not behaviour.ignoreHeight then
		local ux, uy, uz = spGetUnitPosition(unitID)
		if spotY - uy < behaviour.lowerHeight or spotY - uy > behaviour.upperHeight then
			if doDebug then
				Spring.MarkerAddPoint(spotX, 0, spotZ, "height")
			end
			return
		end
	end
	
	spotY = spotY +  behaviour.fireHeight
	if doDebug then
		Spring.MarkerAddPoint(spotX, 0, spotZ, "M")
	end
	GG.SetTemporaryPosTarget(unitID, spotX, spotY, spotZ, false, MEX_UPDATE_RATE, true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---- Update Rates

function gadget:GameFrame(n)
	IterableMap.ApplyFraction(wardUnits, UPDATE_RATE, n%UPDATE_RATE, DoUnitUpdate)
	IterableMap.ApplyFraction(mexUnits, MEX_UPDATE_RATE, n%MEX_UPDATE_RATE, DoMexShootUnitUpdate)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

local function StateToggleCommand(unitID, cmdParams, cmdOptions)
	local unitData = IterableMap.Get(wardUnits, unitID)
	local mexData = IterableMap.Get(mexUnits, unitID)
	if unitData or mexData then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_WARD_FIRE)
		
		if (cmdDescID) then
			wardFireCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = wardFireCmdDesc.params})
			if unitData then
				unitData.active = (state == 1)
			end
			if mexData then
				mexData.active = (state == 1)
			end
		end
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_WARD_FIRE] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_WARD_FIRE) then
		return true  -- command was not used
	end
	StateToggleCommand(unitID, cmdParams, cmdOptions)
	return false  -- command was used
end

local function ToggleDebug(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	doDebug = not doDebug
	Spring.Echo("Debug Ward Fire", doDebug)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit adding/removal

local function AddWardUnit(unitID, unitDefID)
	local behaviour = unitAIBehaviour[unitDefID]
	if not (behaviour) then
		return false
	end
	if not behaviour.wardFireTargets then
		behaviour = (behaviour.land or false)
		if not (behaviour and behaviour.wardFireTargets) then
			return false
		end
	end

	local default = behaviour.wardFireDefault
	wardFireCmdDesc.params[1] = (default and 1) or 0
	spInsertUnitCmdDesc(unitID, wardFireCmdDesc)

	local unitData = {
		def = behaviour,
		active = default,
		unitDefID = unitDefID,
	}
	IterableMap.Add(wardUnits, unitID, unitData)
	return true
end

local function AddMexUnit(unitID, unitDefID, teamID, cmdAdded)
	local behaviour = mexShootBehaviour[unitDefID]
	if not (behaviour) then
		return false
	end
	
	if not cmdAdded then
		wardFireCmdDesc.params[1] = 1
		spInsertUnitCmdDesc(unitID, wardFireCmdDesc)
	end
	
	local unitData = {
		def = behaviour,
		active = true,
		unitDefID = unitDefID,
		teamID = teamID,
		allyTeamID = spGetUnitAllyTeam(unitID),
	}
	IterableMap.Add(mexUnits, unitID, unitData)
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- API

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	local cmdAdded = AddWardUnit(unitID, unitDefID)
	cmdAdded = AddMexUnit(unitID, unitDefID, unitTeam, cmdAdded)
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitAIBehaviour[unitDefID] and unitAIBehaviour[unitDefID].wardFireTargets then
		IterableMap.Remove(wardUnits, unitID)
	end
	if mexShootBehaviour[unitDefID] then
		IterableMap.Remove(mexUnits, unitID)
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	gadget:UnitCreated(unitID, unitDefID, teamID)
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	gadget:UnitDestroyed(unitID, unitDefID, teamID)
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_WARD_FIRE)
	
	gadgetHandler:AddChatAction("debugward", ToggleDebug, "")
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end
