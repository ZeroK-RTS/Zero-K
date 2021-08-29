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

local cmdDescs = {
	[CMD_FIRE_AT_SHIELD] = {
		id      = CMD_FIRE_AT_SHIELD,
		type    = CMDTYPE.ICON_MODE,
		name    = 'Fire at Shield',
		action  = 'fireatshields',
		tooltip = 'Toggles firing at shields',
		params  = {0, 'Off', 'On'}
	},
	[CMD_FIRE_TOWARDS_ENEMY] = {
		id      = CMD_FIRE_TOWARDS_ENEMY,
		type    = CMDTYPE.ICON_MODE,
		name    = 'Fire Towards Enemies',
		action  = 'firetowards',
		tooltip = 'Toggles firing towards enemies out of range.',
		params  = {0, 'Off', 'On'}
	}
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
	
	local enemyID = spGetUnitNearestEnemy(unitID, (behaviour.wardFireUnboundedRange and 1000000000) or behaviour.searchRange, true)
	local enemyUnitDefID = enemyID and spGetUnitDefID(enemyID)
	
	if doDebug then
		Spring.Echo("enemyID", enemyID, "enemyUnitDefID", enemyUnitDefID, "def", enemyUnitDefID and (behaviour.wardFireEverything or behaviour.wardFireTargets[enemyUnitDefID]))
	end
	
	if not (enemyUnitDefID and (behaviour.wardFireEverything or behaviour.wardFireTargets[enemyUnitDefID])) then
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
	local targetLeeway = (not behaviour.wardFireUnboundedRange) and (behaviour.wardFireRangeOverride or behaviour.wardFireTargets[enemyUnitDefID])
	
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
	if behaviour.wardFireTravelVectorAvoid and predProj > 0 then
		local mvx, mvy, mvz, mySpeed = spGetUnitVelocity(unitID)
		if (not behaviour.wardFireVectorAvoidSpeed) or mySpeed > behaviour.wardFireVectorAvoidSpeed then
			local dot = (ex*mvx + ey*mvy + ez*mvz)/(mySpeed * eDist)
			if doDebug then
				Spring.Echo("dot", dot)
			end
			if dot > behaviour.wardFireTravelVectorAvoid then
				return
			end
		end
	end
	
	if predProj > 0 then
		predictedDist = predictedDist*predProj
	else
		-- In this case the enemy is predicted to go past me so should enter range
		return
	end
	
	local effectiveRange = (GetEffectiveWeaponRange(unitData.unitDefID, -dy, behaviour.weaponNum) or 0)
	if effectiveRange then
		local wardFireRange = (effectiveRange - behaviour.wardFireLeeway)

		if doDebug then
			Spring.Echo("targetLeeway", effectiveRange + (targetLeeway or 0), effectiveRange, predictedDist)
		end
		
		if (not targetLeeway) or (effectiveRange + targetLeeway > predictedDist and effectiveRange + behaviour.wardFireLeeway + behaviour.wardFireEnableLeeway < predictedDist) then
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

local function StateToggleCommand(unitID, cmdParams, cmdOptions, cmdID)
	local unitData = IterableMap.Get(wardUnits, unitID)
	local mexData = IterableMap.Get(mexUnits, unitID)
	if (unitData or mexData) and unitData.def.wardFireCmdID == cmdID then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, cmdID)
		
		if (cmdDescID) then
			cmdDescs[cmdID].params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = cmdDescs[cmdID].params})
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
	return {[CMD_FIRE_AT_SHIELD] = true, [CMD_FIRE_TOWARDS_ENEMY] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if not (cmdID == CMD_FIRE_AT_SHIELD or cmdID == CMD_FIRE_TOWARDS_ENEMY) then
		return true  -- command was not used
	end
	StateToggleCommand(unitID, cmdParams, cmdOptions, cmdID)
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
	if not behaviour.hasWardFire then
		behaviour = (behaviour.land or false)
		if not (behaviour and behaviour.hasWardFire) then
			return false
		end
	end

	local default = behaviour.wardFireDefault
	local wardFireCmdDesc = cmdDescs[behaviour.wardFireCmdID]
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
		local cmdID = behaviour.wardFireCmdID or CMD_FIRE_AT_SHIELD
		local wardFireCmdDesc = cmdDescs[cmdID]
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
	if unitAIBehaviour[unitDefID] and unitAIBehaviour[unitDefID].hasWardFire then
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
	gadgetHandler:RegisterCMDID(CMD_FIRE_AT_SHIELD)
	gadgetHandler:RegisterCMDID(CMD_FIRE_TOWARDS_ENEMY)
	
	gadgetHandler:AddChatAction("debugward", ToggleDebug, "")
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end
