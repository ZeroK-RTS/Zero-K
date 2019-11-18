--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Bomber Dive",
		desc = "Causes certain bombers to dive under shields",
		author = "Google Frog",
		date = "30 May 2011",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local DEFAULT_COMMAND_STATE = 1

local unitBomberDiveState = {
	id      = CMD_UNIT_BOMBER_DIVE_STATE,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Dive State',
	action  = 'divestate',
	tooltip	= 'Toggles dive controls',
	params 	= {0, 'Never','When Shielded or Mobile','When Attacking Mobile','Constant'}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local CMD_ATTACK = CMD.ATTACK

local spMoveCtrlGetTag = Spring.MoveCtrl.GetTag

local bomberWeaponNamesDefs, bomberWeaponDefs, bomberUnitDefs = include("LuaRules/Configs/bomber_dive_defs.lua")

local UPDATE_FREQUENCY = 15
local SQRT_TWO = math.sqrt(2)
local bombers = {}
local VOL_SPHERE = 3

local heightDef     = {}
local hitabilityDef = {}
local gameFrame = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function setFlyLow(unitID, height, targetID)
	local wantedHeight = bombers[unitID].config.diveHeight + height
	if wantedHeight > bombers[unitID].config.orgHeight then
		wantedHeight = bombers[unitID].config.orgHeight
	end
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if env then
		Spring.UnitScript.CallAsUnit(unitID, env.BomberDive_FlyLow, wantedHeight, targetID)
	end
end

local function BomberHighPitchUpdate(unitID, targetID, attackGroundHeight)
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if env then
		Spring.UnitScript.CallAsUnit(unitID, env.BomberDive_HighPitchUpdate, targetID, attackGroundHeight)
	end
end

local function setFlyHigh(unitID)
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if env then
		Spring.UnitScript.CallAsUnit(unitID, env.BomberDive_FlyHigh)
	end
end

local function GetAttackTarget(unitID)
	local cmdID, _, _, cmdParam_1, cmdParam_2, cmdParam_3 = Spring.GetUnitCurrentCommand(unitID)
	if cmdID and cmdID == CMD_ATTACK and cmdParam_1 and (not cmdParam_2) then
		local targetID = cmdParam_1
		if Spring.ValidUnitID(targetID) then
			local unitDefID = Spring.GetUnitDefID(targetID)
			local ud = UnitDefs[unitDefID]
			return targetID, not ud.isImmobile
		end
	end
	
	if cmdID == CMD_ATTACK and cmdParam_3 then
		return nil, nil, cmdParam_2
	end
	
	local targetType, isUser, targetID = Spring.GetUnitWeaponTarget(unitID, 3)
	if targetType <= 1 and targetID and Spring.ValidUnitID(targetID) then
		local unitDefID = Spring.GetUnitDefID(targetID)
		local ud = UnitDefs[unitDefID]
		return targetID, not ud.isImmobile
	end
end

local function GetCollisionDistance(unitID, targetID)
	-- Just an approximation to not trust fast moving units.
	local _,_,_,speed = Spring.GetUnitVelocity(targetID)
	
	local distance = Spring.GetUnitSeparation(unitID, targetID, true)
	return distance - (speed or 0)*60
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetUnitHeight(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	local isNanoframe = select(3, Spring.GetUnitIsStunned(unitID))
	if (not heightDef[unitDefID]) or isNanoframe then
		-- Collision volume is always full size for non-nanoframes.
		local scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ = Spring.GetUnitCollisionVolumeData(unitID)
		if isNanoframe then
			return scaleY/2 + offsetY
		end
		heightDef[unitDefID] = scaleY/2 + offsetY
	end
	return heightDef[unitDefID]
end

local function GetWantedBomberHeight(unitID, bomberID, config, underShield)
	local _,_,_, x,y,z = Spring.GetUnitPosition(unitID, true)
	if not x then
		return 40
	end
	
	local _, stunned, inbuild = Spring.GetUnitIsStunned(unitID)
	if inbuild then
	end
	
	local speedMult = (inbuild and 0) or (stunned and 0) or (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
	if (speedMult or 1) ~= 1 then
		local health, maxHealth, paraDamage,_, buildProgress = Spring.GetUnitHealth(unitID)
		if buildProgress < 0.9 then
			return config.orgHeight
		end
		-- Only forgo dive on targets with at least 4s of stun time.
		if paraDamage and maxHealth and (maxHealth > 0) and paraDamage/maxHealth > 1.1 then
			speedMult = 0
		elseif speedMult < 1 then
			speedMult = 1
		end
	end
	
	if speedMult <= 0 then
		return config.orgHeight
	end
	
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not heightDef[unitDefID] then
		-- Collision volume is always full size for non-nanoframes.
		local scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ, volType = Spring.GetUnitCollisionVolumeData(unitID)
		if volType == VOL_SPHERE then
			scaleY = scaleY/SQRT_TWO
		end
		heightDef[unitDefID] = scaleY/2 + offsetY
	end
	
	if not hitabilityDef[unitDefID] then
		-- Collision volume is always full size when buildProgress >- 0.9.
		local scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ, volType = Spring.GetUnitCollisionVolumeData(unitID)
		if volType == VOL_SPHERE then
			scaleX = scaleX/SQRT_TWO
			scaleZ = scaleZ/SQRT_TWO
		end
		local horSize = config.sizeSafetyFactor*(math.min(scaleX, scaleZ)/2 - math.sqrt(offsetX^2 + offsetZ^2))
		local ud = UnitDefs[unitDefID]
		local speed = ud.speed/30
		if ud.customParams and ud.customParams.jump_speed then
			local jumpSpeed = tonumber(ud.customParams.jump_speed)
			if jumpSpeed and jumpSpeed/2 > speed then
				speed = jumpSpeed/2
			end
		end
		hitabilityDef[unitDefID] = horSize/speed
		if speed > 3 then
			hitabilityDef[unitDefID] = math.max(0, hitabilityDef[unitDefID] + 2 - speed*1.5)
		end
	end
	
	local ground = Spring.GetGroundHeight(x, z)
	local verticalExtent = heightDef[unitDefID] + y - math.max(0, ground)
	
	local diveHeight = verticalExtent
	if not underShield then
		diveHeight = diveHeight + config.altPerFlightFrame*hitabilityDef[unitDefID]/speedMult
	end
	
	local _,_,_, bx,by,bz = Spring.GetUnitPosition(bomberID, true)
	
	local dx = x - bx
	local dz = z - bz
	local mag = math.sqrt(dx*dx + dz*dz)
	if mag > 1 then
		dx = dx/mag
		dz = dz/mag
		
		local effectiveHeight = Spring.GetGroundHeight(bx, bz)
		for i = 140, 350, 70 do
			local futureHeight = Spring.GetGroundHeight(bx + i*dx, bz + i*dz)
			effectiveHeight = math.max(effectiveHeight, futureHeight)
		end
		
		if effectiveHeight > ground then
			diveHeight = math.max(5, diveHeight - (effectiveHeight - ground))
		elseif mag > 120 and effectiveHeight < ground - 10 then
			diveHeight = diveHeight + (ground - effectiveHeight) - 10
		end
	end
	
	if mag > 120 and ground > by then
		diveHeight = diveHeight + ground - by
	end
	return diveHeight
end

local function temporaryDive(unitID, duration, height, distance, targetID)
	local config = bombers[unitID].config
	
	-- No distance given for shield collision, dive as soon as possible.
	if distance then
		-- The maximum horizontal distance required to dive to that height
		local diveDistance = (config.orgHeight - height)*config.diveDistanceMult
		if diveDistance < distance then
			return
		end
	end
	
	setFlyLow(unitID, height, targetID)
	bombers[unitID].resetTime = UPDATE_FREQUENCY * math.ceil((Spring.GetGameFrame() + duration)/UPDATE_FREQUENCY)
end

function Bomber_Dive_fired(unitID)
	if bombers[unitID].diveState ~= 3 then
		setFlyHigh(unitID)
		bombers[unitID].resetTime = false
	end
end
GG.Bomber_Dive_fired = Bomber_Dive_fired

function Bomber_Dive_fake_fired(unitID)
	if unitID and Spring.ValidUnitID(unitID) then
		local data = bombers[unitID]
		if ((not Spring.GetUnitRulesParam(unitID, "noammo")) or Spring.GetUnitRulesParam(unitID, "noammo") ~= 1) then
			local targetID, mobile, attackGroundHeight = GetAttackTarget(unitID)
			if targetID or attackGroundHeight then
				BomberHighPitchUpdate(unitID, targetID, attackGroundHeight)
			end
			if data and (data.diveState == 2 or data.diveState == 1) and ((not data.underShield) or data.underShield < gameFrame) then
				data.underShield = false
				if targetID and mobile then
					local height = GetWantedBomberHeight(targetID, unitID, bombers[unitID].config)
					local distance = GetCollisionDistance(unitID, targetID)
					temporaryDive(unitID, 8, height, distance, targetID)
				end
			end
		end
	end
end
GG.Bomber_Dive_fake_fired = Bomber_Dive_fake_fired

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile)

	if proID and bomberWeaponNamesDefs[Spring.GetProjectileName(proID)] then
		if proOwnerID and Spring.ValidUnitID(proOwnerID) and bombers[proOwnerID] and bombers[proOwnerID].diveState == 1 then
			if shieldCarrierUnitID and Spring.ValidUnitID(shieldCarrierUnitID) and shieldEmitterWeaponNum then
				--local wid = UnitDefs[Spring.GetUnitDefID(shieldCarrierUnitID)].weapons[shieldEmitterWeaponNum].weaponDef
				--if WeaponDefs[wid] and WeaponDefs[wid].shieldPower > bombers[proOwnerID].config.diveDamage then
					if ((not Spring.GetUnitRulesParam(proOwnerID, "noammo")) or Spring.GetUnitRulesParam(proOwnerID, "noammo") ~= 1) then
						local targetID = GetAttackTarget(proOwnerID)
						bombers[proOwnerID].underShield = gameFrame + 45
						if targetID then
							local height = GetWantedBomberHeight(targetID, proOwnerID, bombers[proOwnerID].config, true)
							local distance = GetCollisionDistance(proOwnerID, targetID)
							temporaryDive(proOwnerID, 45, height, distance, targetID)
						else
							temporaryDive(proOwnerID, 45, 40)
						end
					end
				--end
			end
		end
		Spring.DeleteProjectile(proID)
		return true
	end
end

function gadget:UnitPreDamaged_GetWantedWeaponDef()
	local wantedWeaponList = {}
	for wdid = 1, #WeaponDefs do
		if bomberWeaponDefs[wdid] then
			wantedWeaponList[#wantedWeaponList + 1] = wdid
		end
	end
	return wantedWeaponList
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if weaponID and bomberWeaponDefs[weaponID] then
		return 0
	end
end

function gadget:GameFrame(n)
	gameFrame = n
	if n%UPDATE_FREQUENCY == 0 then
		for unitID, data in pairs(bombers) do
			if data.resetTime == n then
				setFlyHigh(unitID)
				data.resetTime = false
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Command Handling
local function ToggleDiveCommand(unitID, cmdParams, cmdOptions)
	if bombers[unitID] then
		local state = cmdParams[1]
		if cmdOptions.right then
			state = (state - 2)%4
		end
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_UNIT_BOMBER_DIVE_STATE)
		
		if (cmdDescID) then
			unitBomberDiveState.params[1] = state
			Spring.EditUnitCmdDesc(unitID, cmdDescID, { params = unitBomberDiveState.params})
		end
		bombers[unitID].diveState = state
		if state == 3 then
			setFlyLow(unitID, 40)
			bombers[unitID].resetTime = false
		elseif state == 0 then
			setFlyHigh(unitID)
		elseif bombers[unitID].resetTime == false then
			setFlyHigh(unitID)
		end
	end
	
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_UNIT_BOMBER_DIVE_STATE] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_UNIT_BOMBER_DIVE_STATE) then
		return true  -- command was not used
	end
	ToggleDiveCommand(unitID, cmdParams, cmdOptions)
	return false  -- command was used
end


function gadget:UnitCreated(unitID, unitDefID, teamID)

	if not bomberUnitDefs[unitDefID] then
		return
	end
	
	bombers[unitID] = {
		diveState = DEFAULT_COMMAND_STATE, -- 0 = off, 1 = with shield, 2 = when attacking, 3 = always
		config = bomberUnitDefs[unitDefID],
		resetTime = false,
	}
	
	Spring.InsertUnitCmdDesc(unitID, unitBomberDiveState)
	ToggleDiveCommand(unitID, {DEFAULT_COMMAND_STATE}, {})
end

function gadget:UnitDestroyed(unitID)
	if bombers[unitID] then
		bombers[unitID] = nil
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:Initialize()

	_G.bombers = bombers
	-- register command
	gadgetHandler:RegisterCMDID(CMD_UNIT_BOMBER_DIVE_STATE)
	
	GG.GetUnitHeight = GetUnitHeight
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end
