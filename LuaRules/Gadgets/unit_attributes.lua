
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Attributes",
      desc      = "Handles UnitRulesParam attributes.",
      author    = "CarRepairer & Google Frog",
      date      = "2009-11-27", --last update 2014-2-19
      license   = "GNU GPL, v2 or later",
      layer     = -1,
      enabled   = not (Game.version:find('91.0') == 1), 
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local isNewEngine = Spring.Utilities.IsCurrentVersionNewerThan(96, 300)

local UPDATE_PERIOD = 3 -- see http://springrts.com/mantis/view.php?id=3048

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local floor = math.floor

local spValidUnitID         = Spring.ValidUnitID
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetGameFrame        = Spring.GetGameFrame
local spGetUnitRulesParam  	= Spring.GetUnitRulesParam
local spSetUnitRulesParam   = Spring.SetUnitRulesParam

local spSetUnitBuildSpeed   = Spring.SetUnitBuildSpeed
local spSetUnitWeaponState  = Spring.SetUnitWeaponState
local spGetUnitWeaponState  = Spring.GetUnitWeaponState
local spGiveOrderToUnit     = Spring.GiveOrderToUnit

local spGetUnitMoveTypeData    = Spring.GetUnitMoveTypeData
local spMoveCtrlGetTag         = Spring.MoveCtrl.GetTag
local spSetAirMoveTypeData     = Spring.MoveCtrl.SetAirMoveTypeData
local spSetGunshipMoveTypeData = Spring.MoveCtrl.SetGunshipMoveTypeData
local spSetGroundMoveTypeData  = Spring.MoveCtrl.SetGroundMoveTypeData

local getMovetype = Spring.Utilities.getMovetype

local spSetUnitCOBValue = Spring.SetUnitCOBValue
local COB_MAX_SPEED = COB.MAX_SPEED
local WACKY_CONVERSION_FACTOR_1 = 2184.53
local CMD_WAIT = CMD.WAIT

local workingGroundMoveType = true -- not ((Spring.GetModOptions() and (Spring.GetModOptions().pathfinder == "classic") and true) or false)

local ableToForceOff = {
	[ UnitDefNames['armarad'].id ] = true,
	[ UnitDefNames['spherecloaker'].id ] = true,
	[ UnitDefNames['armjamt'].id ] = true,
	[ UnitDefNames['armsonar'].id ] = true,
	[ UnitDefNames['corrad'].id ] = true,
	[ UnitDefNames['corawac'].id ] = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local origUnitSpeed = {}
local origUnitReload = {}
local origUnitBuildSpeed = {}

local currentEcon = {}
local currentReload = {}
local currentMovement = {}
local currentTurn = {}
local currentAcc = {}

local unitForcedOff = {}
local unitSlowed = {}
local unitShieldDisabled = {}
local unitCannotCloak = {}

if not GG.att_reload then
	GG.att_reload = {}
end

local function updateBuildSpeed(unitID, ud, speedFactor)	

    if ud.buildSpeed == 0 then
        return
    end
        
    local unitDefID = ud.id

    if not origUnitBuildSpeed[unitDefID] then
    
        origUnitBuildSpeed[unitDefID] = {
            buildSpeed = ud.buildSpeed,
        }
    end

    local state = origUnitBuildSpeed[unitDefID]

    spSetUnitBuildSpeed(unitID, 
        state.buildSpeed*speedFactor, -- build
        2*state.buildSpeed*speedFactor, -- repair
        state.buildSpeed*speedFactor, -- reclaim
        0.8*state.buildSpeed*speedFactor) -- rezz
    
end

local function updateEconomy(unitID, ud, factor)	
	local unitDefID = ud.id
	
    if ud.metalMake ~= 0 then
        local metalMake = ud.metalMake
		Spring.SetUnitResourcing(unitID, "cmm", -metalMake*(1-factor))
	elseif ud.customParams.ismex then
		Spring.SetUnitRulesParam(unitID,"mexincomefactor", factor)
    end
	
	if energyMake ~= 0 or energyUpkeep ~= 0 then
		local energyMake = ud.energyMake
		local energyUpkeep = ud.energyUpkeep
		Spring.SetUnitResourcing(unitID, "cme", -energyMake*(1-factor))
		Spring.SetUnitResourcing(unitID, "cue", -energyUpkeep*(1-factor))
	end
end

local function updateReloadSpeed(unitID, ud, speedFactor, gameFrame)
	local unitDefID = ud.id
	
	if not origUnitReload[unitDefID] then
	
		origUnitReload[unitDefID] = {
			weapon = {},
			weaponCount = #ud.weapons,
		}
		local state = origUnitReload[unitDefID]
		
		for i = 1, state.weaponCount do
			local wd = WeaponDefs[ud.weapons[i].weaponDef]
			local reload = wd.reload
			state.weapon[i] = {
				reload = reload,
				burstRate = wd.salvoDelay,
				oldReloadFrames = floor(reload*30),
			}
			if wd.type == "BeamLaser" then
				state.weapon[i].burstRate = false -- beamlasers go screwy if you mess with their burst length
			end
		end
		
	end
	
	local state = origUnitReload[unitDefID]

	for i = 1, state.weaponCount do
		local w = state.weapon[i]
		local reloadState = spGetUnitWeaponState(unitID, i , 'reloadState')
		local reloadTime  = spGetUnitWeaponState(unitID, i , 'reloadTime')
		if speedFactor <= 0 then
			local newReload = 100000 -- set a high reload time so healthbars don't judder. NOTE: math.huge is TOO LARGE
			if reloadState < 0 then -- unit is already reloaded, so set unit to almost reloaded
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = gameFrame+UPDATE_PERIOD+1})
			else
				local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload+UPDATE_PERIOD})
			end
			-- add UPDATE_PERIOD so that the reload time never advances past what it is now
		else
			local newReload = w.reload/speedFactor
			local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
			if w.burstRate then
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload, burstRate = w.burstRate/speedFactor})
			else
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload})
			end
		end
	end
	
end

local function updateMovementSpeed(unitID, ud, speedFactor, turnAccelFactor, maxAccelerationFactor)	
	local unitDefID = ud.id
	if not origUnitSpeed[unitDefID] then
	
		local moveData = spGetUnitMoveTypeData(unitID)
    
		origUnitSpeed[unitDefID] = {
			origSpeed = ud.speed,
			origReverseSpeed = (moveData.name == "ground") and moveData.maxReverseSpeed or ud.speed,
			origTurnRate = ud.turnRate,
			origMaxAcc = ud.maxAcc,
			origMaxDec = ud.maxDec,
			movetype = -1,
		}
		
		local state = origUnitSpeed[unitDefID]
		state.movetype = getMovetype(ud)
	end
	
	local state = origUnitSpeed[unitDefID]
	local decFactor = speedFactor
	local isSlowed = speedFactor < 1
	if isSlowed then
		-- increase brake rate to cause units to slow down to their new max speed correctly.
		decFactor = 1000
	end
	if speedFactor <= 0 then
		speedFactor = 0
		decFactor = 100000 -- a unit with 0 decRate will not deccelerate down to it's 0 maxVelocity
	end
	if turnAccelFactor <= 0 then
		turnAccelFactor = 0
	end
	local turnFactor = turnAccelFactor
	if turnFactor <= 0.001 then
		turnFactor = 0.001
	end
	if maxAccelerationFactor <= 0 then
		maxAccelerationFactor = 0.001
	end
	
	if spMoveCtrlGetTag(unitID) == nil then
		if state.movetype == 0 then
			local attribute = {
				maxSpeed        = state.origSpeed       *speedFactor,
				maxAcc          = state.origMaxAcc      *maxAccelerationFactor, --(speedFactor > 0.001 and speedFactor or 0.001)
			}
			spSetAirMoveTypeData (unitID, attribute)
		elseif state.movetype == 1 then
			local attribute =  {
				maxSpeed        = state.origSpeed       *speedFactor,
				--maxReverseSpeed = state.origReverseSpeed*speedFactor,
				turnRate        = state.origTurnRate    *turnFactor,
				accRate         = state.origMaxAcc      *(speedFactor > 0.001 and speedFactor or 0.001),
				--decRate         = state.origMaxDec      *(speedFactor > 0.01  and speedFactor or 0.01)
			}
			spSetGunshipMoveTypeData (unitID, attribute)
		elseif state.movetype == 2 then
			if workingGroundMoveType then
				local accRate = state.origMaxAcc*speedFactor 
				if isSlowed and accRate > speedFactor then
					-- Clamp acceleration to mitigate prevent brief speedup when executing new order
					-- 1 is here as an arbitary factor, there is no nice conversion which means that 1 is a good value.
					accRate = speedFactor 
				end 
				local attribute =  {
					maxSpeed        = state.origSpeed       *speedFactor,
					maxReverseSpeed = (isSlowed and 0) or state.origReverseSpeed, --disallow reverse while slowed
					turnRate        = state.origTurnRate    *turnFactor,
					accRate         = accRate,
					decRate         = state.origMaxDec      *decFactor
				}
				if isNewEngine then
					attribute.turnAccel = state.origTurnRate*turnAccelFactor
				end
				spSetGroundMoveTypeData (unitID, attribute)
			else
				--Spring.Echo(state.origSpeed*speedFactor*WACKY_CONVERSION_FACTOR_1)
				--Spring.Echo(Spring.GetUnitCOBValue(unitID, COB_MAX_SPEED))
				spSetUnitCOBValue(unitID, COB_MAX_SPEED, math.ceil(state.origSpeed*speedFactor*WACKY_CONVERSION_FACTOR_1))
			end
		end
	end
	
end

local function removeUnit(unitID)
	unitForcedOff[unitID] = nil
	unitSlowed[unitID] = nil
	unitShieldDisabled[unitID] = nil
	unitCannotCloak[unitID] = nil 
	currentEcon[unitID] = nil 
	currentReload[unitID] = nil 
	currentMovement[unitID] = nil 
	currentTurn[unitID] = nil 
	currentAcc[unitID] = nil 
end

function GG.UpdateUnitAttributes(unitID, frame)
	if not spValidUnitID(unitID) then
		removeUnit(unitID)
		return
	end
	
	local udid = spGetUnitDefID(unitID)
	if not udid then 
		return 
	end
		
	frame = frame or spGetGameFrame()
	
	local ud = UnitDefs[udid]
	local changedAtt = false
	
	-- Increased reload from CAPTURE --
	local selfReloadSpeedChange = spGetUnitRulesParam(unitID,"selfReloadSpeedChange")
	
	local disarmed = spGetUnitRulesParam(unitID,"disarmed")
	
	-- Unit speed change (like sprint) --
	local selfMoveSpeedChange = spGetUnitRulesParam(unitID, "selfMoveSpeedChange")
	local selfTurnSpeedChange = spGetUnitRulesParam(unitID, "selfTurnSpeedChange")
	local selfMaxAccelerationChange = spGetUnitRulesParam(unitID, "selfMaxAccelerationChange") --only exist in airplane??
	
	-- SLOW --
	local slowState = spGetUnitRulesParam(unitID,"slowState")
	
	if selfReloadSpeedChange or selfMoveSpeedChange or slowState or selfTurnSpeedChange or disarmed or selfAccelerationChange then
		local slowMult   = 1-(slowState or 0)
		local econMult  = (slowMult)*(1 - (disarmed or 0))
		local moveMult   = (slowMult)*(selfMoveSpeedChange or 1)
		local turnMult   = (slowMult)*(selfMoveSpeedChange or 1)*(selfTurnSpeedChange or 1)
		local reloadMult = (slowMult)*(selfReloadSpeedChange or 1)*(1 - (disarmed or 0))
		local maxAccMult = (slowMult)*(selfMaxAccelerationChange or 1)

		-- Let other gadgets and widgets get the total effect without 
		-- duplicating the pevious calculations.
		spSetUnitRulesParam(unitID, "totalReloadSpeedChange", reloadMult)
		
		GG.att_reload[unitID] = reloadMult
		unitSlowed[unitID] = moveMult < 1
		if reloadMult ~= currentReload[unitID] then
			updateReloadSpeed(unitID, ud, reloadMult, frame)
			currentReload[unitID] = reloadMult
		end
		
		if currentMovement[unitID] ~= moveMult or currentTurn[unitID] ~= turnMult or currentAcc[unitID] ~= maxAccMult then
			updateMovementSpeed(unitID,ud, moveMult, turnMult,maxAccMult)
			currentMovement[unitID] = moveMult
			currentTurn[unitID] = turnMult
			currentAcc[unitID] = maxAccMult
		end
		
		if econMult ~= currentEcon[unitID] then
			updateBuildSpeed(unitID, ud, econMult)
			updateEconomy(unitID, ud, econMult)
			currentEcon[unitID] = econMult
		end
		if econMult ~= 1 or moveMult ~= 1 or reloadMult ~= 1 or turnMult ~= 1 or maxAccMult ~= 1 then
			changedAtt = true
		end
	else
		unitSlowed[unitID] = nil
	end
		
	local forcedOff = spGetUnitRulesParam(unitID,"forcedOff")
	
	if ud.shieldWeaponDef then
		if (forcedOff and forcedOff == 1) or (disarmed and disarmed == 1) then
			Spring.SetUnitShieldState(unitID, -1, false)
			unitShieldDisabled[unitID] = true
		elseif unitShieldDisabled[unitID] then
			Spring.SetUnitShieldState(unitID, -1, true)
			unitShieldDisabled[unitID] = nil
		end
	end
	
	if ableToForceOff[udid] then
		if (forcedOff and forcedOff == 1) or (disarmed and disarmed == 1) then
			changedAtt = true
			if not unitForcedOff[unitID] then
				local active = Spring.GetUnitStates(unitID).active
				if active then	-- only disable "active" unit
					Spring.GiveOrderToUnit(unitID, CMD.ONOFF, { 0 }, { })
				end
				unitForcedOff[unitID] = (active and 1) or 0
			end
		elseif unitForcedOff[unitID] then
			local oldVal = unitForcedOff[unitID]
			unitForcedOff[unitID] = nil
			Spring.GiveOrderToUnit(unitID, CMD.ONOFF, { oldVal }, { })
		end
	end
	
	local cloakBlocked = (spGetUnitRulesParam(unitID,"on_fire") == 1) or (disarmed == 1)
	if cloakBlocked then
		changedAtt = true
		if not unitCannotCloak[unitID] then
			Spring.SetUnitCloak(unitID, false, 10000)
			unitCannotCloak[unitID] = true
		end
	elseif unitCannotCloak[unitID] then
		Spring.SetUnitCloak(unitID, false, false)
		unitCannotCloak[unitID] = nil
	end

	-- remove the attributes if nothing is being changed
	if not changedAtt then
		removeUnit(unitID)
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return true --{[CMD.ONOFF] = true, [70] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD.ONOFF and unitForcedOff[unitID] ~= nil) or (cmdID == 70 and unitSlowed[unitID]) then
		return false
	else 
		return true
	end
end

