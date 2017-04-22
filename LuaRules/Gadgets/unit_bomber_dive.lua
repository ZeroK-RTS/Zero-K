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
local bombers = {}

local heightDef     = {}
local hitabilityDef = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
	
local function setFlyLow(unitID, height)
	local wantedHeight = bombers[unitID].config.diveHeight + height
	if wantedHeight > bombers[unitID].config.orgHeight then
		wantedHeight = bombers[unitID].config.orgHeight
	end
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if env then
		Spring.UnitScript.CallAsUnit(unitID, env.BomberDive_FlyLow, wantedHeight)
	end
end

local function setFlyHigh(unitID)
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if env then
		Spring.UnitScript.CallAsUnit(unitID, env.BomberDive_FlyHigh)
	end
end

local function isAttackingMobile(unitID)
	local cQueue = Spring.GetCommandQueue(unitID,1)
	if cQueue and #cQueue == 1 and cQueue[1].id == CMD_ATTACK and cQueue[1].params and cQueue[1].params[1] and (not cQueue[1].params[2]) then
		local targetID = cQueue[1].params[1]
		local unitDefID = Spring.GetUnitDefID(targetID)
		local ud = UnitDefs[unitDefID]
		return ud and ud.speed ~= 0 and targetID
	end
end

local function GetCollisionDistance(unitID, targetID)
	-- Just an approximation to not trust fast moving units.
	local _,_,_,speed = Spring.GetUnitVelocity(targetID)
	
	local distance = Spring.GetUnitSeparation(unitID, targetID, true)
	return distance - speed*60
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

local function GetWantedBomberHeight(unitID, config, underShield)
	local _,_,_, x,y,z = Spring.GetUnitPosition(unitID, true)
	if not x then
		return 30
	end
	
	local stunned = Spring.GetUnitIsStunned(unitID)
	if stunned then
		return config.orgHeight
	end
	
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not heightDef[unitDefID] then
		-- Collision volume is always full size for non-nanoframes.
		local scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ = Spring.GetUnitCollisionVolumeData(unitID)
		heightDef[unitDefID] = scaleY/2 + offsetY
	end
	
	if not hitabilityDef[unitDefID] then
		-- Collision volume is always full size for non-nanoframes.
		local scaleX, scaleY, scaleZ, offsetX, offsetY, offsetZ = Spring.GetUnitCollisionVolumeData(unitID)
		local horSize = math.min(scaleX, scaleZ)/2
		local speedMult = (Spring.GetUnitRulesParam(unitID, "upgradesSpeedMult") or 1)
		local speed = speedMult*UnitDefs[unitDefID].speed/30
		
		if speedMult == 0 then
			hitabilityDef[unitDefID] = 1000
		else
			hitabilityDef[unitDefID] = horSize/speed
			
			if speed > 3 then
				hitabilityDef[unitDefID] = math.max(0, hitabilityDef[unitDefID] + 2 - speed*1.5)
			end
		end
	end
	
	local ground = Spring.GetGroundHeight(x,z)
	local verticalExtent = heightDef[unitDefID] + y - math.max(0, ground)
	
	if underShield then
		return verticalExtent
	end
	
	local speedMult = (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
	if speedMult <= 0 then
		return config.orgHeight
	end
	
	return verticalExtent + config.altPerFlightFrame*hitabilityDef[unitDefID]/speedMult
end

local function temporaryDive(unitID, duration, height, distance)
	local config = bombers[unitID].config
	
	-- No distance given for shield collision, dive as soon as possible.
	if distance then
		-- The maximum horizontal distance required to dive to that height
		local diveDistance = (config.orgHeight - height)*config.diveRate
		if diveDistance < distance then
			return
		end
	end
	
	setFlyLow(unitID, height)
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
		if bombers[unitID] and (bombers[unitID].diveState == 2 or bombers[unitID].diveState == 1) and
				((not Spring.GetUnitRulesParam(unitID, "noammo")) or Spring.GetUnitRulesParam(unitID, "noammo") ~= 1) then
			local mobileID = isAttackingMobile(unitID)
			if mobileID then
				local height = GetWantedBomberHeight(mobileID, bombers[unitID].config)
				local distance = GetCollisionDistance(unitID, mobileID)
				temporaryDive(unitID, 8, height, distance)
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
				local wid = UnitDefs[Spring.GetUnitDefID(shieldCarrierUnitID)].weapons[shieldEmitterWeaponNum].weaponDef
				if WeaponDefs[wid] and WeaponDefs[wid].shieldPower > bombers[proOwnerID].config.diveDamage 
						and ((not Spring.GetUnitRulesParam(proOwnerID, "noammo")) or Spring.GetUnitRulesParam(proOwnerID, "noammo") ~= 1) then
					local mobileID = isAttackingMobile(proOwnerID)
					if mobileID then
						local height = GetWantedBomberHeight(mobileID, bombers[proOwnerID].config, true)
						local distance = GetCollisionDistance(proOwnerID, mobileID)
						temporaryDive(proOwnerID, 8, height, distance)
					else
						temporaryDive(proOwnerID, 150, 30)
					end
				end
			end
		end
		return 0
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
			setFlyLow(unitID, 30)
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
