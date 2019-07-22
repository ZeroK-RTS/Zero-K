
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
      enabled   = true, 
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UPDATE_PERIOD = 3

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

local ALLY_ACCESS = {allied = true}
local INLOS_ACCESS = {inlos = true}

local getMovetype = Spring.Utilities.getMovetype

local spSetUnitCOBValue = Spring.SetUnitCOBValue
local COB_MAX_SPEED = COB.MAX_SPEED
local WACKY_CONVERSION_FACTOR_1 = 2184.53
local CMD_WAIT = CMD.WAIT

local workingGroundMoveType = true -- not ((Spring.GetModOptions() and (Spring.GetModOptions().pathfinder == "classic") and true) or false)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Sensor Handling

local hasSensorOrJamm = {
	[ UnitDefNames['staticheavyradar'].id ] = true,
	[ UnitDefNames['cloakjammer'].id ] = true,
	[ UnitDefNames['staticjammer'].id ] = true,
	[ UnitDefNames['staticsonar'].id ] = true,
	[ UnitDefNames['staticradar'].id ] = true,
	[ UnitDefNames['planescout'].id ] = true,
	[ UnitDefNames['shipcarrier'].id ] = true,
}

local radarUnitDef = {}
local sonarUnitDef = {}
local jammerUnitDef = {}

for unitDefID,_ in pairs(hasSensorOrJamm) do
	local ud = UnitDefs[unitDefID]
	if ud.radarRadius > 0 then
		radarUnitDef[unitDefID] = ud.radarRadius
	end
	if ud.sonarRadius > 0 then
		sonarUnitDef[unitDefID] = ud.sonarRadius
	end
	if ud.jammerRadius > 0 then
		jammerUnitDef[unitDefID] = ud.jammerRadius
	end
end

local function UpdateSensorAndJamm(unitID, unitDefID, enabled, radarOverride, sonarOverride, jammerOverride, sightOverride)
	if radarUnitDef[unitDefID] or radarOverride then 
		Spring.SetUnitSensorRadius(unitID, "radar", (enabled and (radarOverride or radarUnitDef[unitDefID])) or 0)
	end
	if sonarUnitDef[unitDefID] or sonarOverride then 
		Spring.SetUnitSensorRadius(unitID, "sonar", (enabled and (sonarOverride or sonarUnitDef[unitDefID])) or 0)
	end
	if jammerUnitDef[unitDefID] or jammerOverride then 
		Spring.SetUnitSensorRadius(unitID, "radarJammer", (enabled and (jammerOverride or jammerUnitDef[unitDefID])) or 0)
	end
	if sightOverride then
		Spring.SetUnitSensorRadius(unitID, "los", sightOverride)
		Spring.SetUnitSensorRadius(unitID, "airLos", sightOverride)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Build Speed Handling

local origUnitBuildSpeed = {}

local function UpdateBuildSpeed(unitID, ud, speedFactor)	

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

	spSetUnitRulesParam(unitID, "buildSpeed", state.buildSpeed*speedFactor, INLOS_ACCESS)
	
    spSetUnitBuildSpeed(unitID, 
        state.buildSpeed*speedFactor, -- build
        2*state.buildSpeed*speedFactor, -- repair
        state.buildSpeed*speedFactor, -- reclaim
        0.5*state.buildSpeed*speedFactor) -- rezz
    
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Economy Handling

local function UpdateEconomy(unitID, ud, factor)
	spSetUnitRulesParam(unitID,"resourceGenerationFactor", factor, INLOS_ACCESS)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Reload Time Handling

local origUnitReload = {}
local unitReloadPaused = {}

local function UpdatePausedReload(unitID, unitDefID, gameFrame)
	local state = origUnitReload[unitDefID]
	
	for i = 1, state.weaponCount do
		local w = state.weapon[i]
		local reloadState = spGetUnitWeaponState(unitID, i , 'reloadState')
		if reloadState then
			local reloadTime  = spGetUnitWeaponState(unitID, i , 'reloadTime')
			local newReload = 100000 -- set a high reload time so healthbars don't judder. NOTE: math.huge is TOO LARGE
			if reloadState < 0 then -- unit is already reloaded, so set unit to almost reloaded
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = gameFrame+UPDATE_PERIOD+1})
			else
				local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload+UPDATE_PERIOD})
			end
		end
	end
end

local function UpdateReloadSpeed(unitID, ud, speedFactor, gameFrame)
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
			if not unitReloadPaused[unitID] then
				local newReload = 100000 -- set a high reload time so healthbars don't judder. NOTE: math.huge is TOO LARGE
				unitReloadPaused[unitID] = unitDefID
				spSetUnitRulesParam(unitID, "reloadPaused", 1, INLOS_ACCESS)
				if reloadState < gameFrame then -- unit is already reloaded, so set unit to almost reloaded
					spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = gameFrame+UPDATE_PERIOD+1})
				else
					local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
					spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload+UPDATE_PERIOD})
				end
				-- add UPDATE_PERIOD so that the reload time never advances past what it is now
			end
		else
			if unitReloadPaused[unitID] then
				unitReloadPaused[unitID] = nil
				spSetUnitRulesParam(unitID, "reloadPaused", 0, INLOS_ACCESS)
			end
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Movement Speed Handling

local origUnitSpeed = {}

local function UpdateMovementSpeed(unitID, ud, speedFactor, turnAccelFactor, maxAccelerationFactor)	
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
	local decFactor = maxAccelerationFactor
	local isSlowed = speedFactor < 1
	if isSlowed then
		-- increase brake rate to cause units to slow down to their new max speed correctly.
		decFactor = 1000
	end
	if speedFactor <= 0 then
		speedFactor = 0
		
		-- Set the units velocity to zero if it is attached to the ground.
		local x, y, z = Spring.GetUnitPosition(unitID)
		if x then
			local h = Spring.GetGroundHeight(x, z)
			if h and h >= y then
				Spring.SetUnitVelocity(unitID, 0,0,0)
				
				-- Perhaps attributes should do this:
				--local env = Spring.UnitScript.GetScriptEnv(unitID)
				--if env and env.script.StopMoving then
				--	Spring.UnitScript.CallAsUnit(unitID,env.script.StopMoving, hx, hy, hz)
				--end
			end
		end
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
			spSetAirMoveTypeData (unitID, attribute)
		elseif state.movetype == 1 then
			local attribute =  {
				maxSpeed        = state.origSpeed       *speedFactor,
				--maxReverseSpeed = state.origReverseSpeed*speedFactor,
				turnRate        = state.origTurnRate    *turnFactor,
				accRate         = state.origMaxAcc      *maxAccelerationFactor,
				decRate         = state.origMaxDec      *maxAccelerationFactor
			}
			spSetGunshipMoveTypeData (unitID, attribute)
			GG.ForceUpdateWantedMaxSpeed(unitID, unitDefID)
		elseif state.movetype == 2 then
			if workingGroundMoveType then
				local accRate = state.origMaxAcc*maxAccelerationFactor 
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
					decRate         = state.origMaxDec      *decFactor,
					turnAccel       = state.origTurnRate    *turnAccelFactor*1.2,
				}
				spSetGroundMoveTypeData (unitID, attribute)
				GG.ForceUpdateWantedMaxSpeed(unitID, unitDefID)
			else
				--Spring.Echo(state.origSpeed*speedFactor*WACKY_CONVERSION_FACTOR_1)
				--Spring.Echo(Spring.GetUnitCOBValue(unitID, COB_MAX_SPEED))
				spSetUnitCOBValue(unitID, COB_MAX_SPEED, math.ceil(state.origSpeed*speedFactor*WACKY_CONVERSION_FACTOR_1))
			end
		end
	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- UnitRulesParam Handling

local currentEcon = {}
local currentBuildpower = {}
local currentReload = {}
local currentMovement = {}
local currentTurn = {}
local currentAcc = {}

local unitSlowed = {}
local unitAbilityDisabled = {}

local function removeUnit(unitID)
	unitSlowed[unitID] = nil
	unitAbilityDisabled[unitID] = nil
	unitReloadPaused[unitID] = nil
	
	currentEcon[unitID] = nil
	currentBuildpower[unitID] = nil
	currentReload[unitID] = nil 
	currentMovement[unitID] = nil 
	currentTurn[unitID] = nil 
	currentAcc[unitID] = nil
end

function UpdateUnitAttributes(unitID, frame)
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
	
	local disarmed = spGetUnitRulesParam(unitID,"disarmed") or 0
	local completeDisable = (spGetUnitRulesParam(unitID,"morphDisable") or 0)
	if spGetUnitRulesParam(unitID,"planetwarsDisable") == 1 then
		completeDisable = 1
	end
	local crashing = spGetUnitRulesParam(unitID,"crashing") or 0
	
	-- Unit speed change (like sprint) --
	local upgradesSpeedMult   = spGetUnitRulesParam(unitID, "upgradesSpeedMult")
	local selfMoveSpeedChange = spGetUnitRulesParam(unitID, "selfMoveSpeedChange")
	local selfTurnSpeedChange = spGetUnitRulesParam(unitID, "selfTurnSpeedChange")
	local selfIncomeChange = spGetUnitRulesParam(unitID, "selfIncomeChange")
	local selfMaxAccelerationChange = spGetUnitRulesParam(unitID, "selfMaxAccelerationChange") --only exist in airplane??
	
	-- SLOW --
	local slowState = spGetUnitRulesParam(unitID,"slowState")
	if slowState and slowState > 0.5 then
		slowState = 0.5 -- Maximum slow
	end
	local zombieSpeedMult = spGetUnitRulesParam(unitID,"zombieSpeedMult")
	local buildpowerMult = spGetUnitRulesParam(unitID, "buildpower_mult")
	
	-- Disable
	local fullDisable = spGetUnitRulesParam(unitID, "fulldisable") == 1
	
	if selfReloadSpeedChange or selfMoveSpeedChange or slowState or zombieSpeedMult or buildpowerMult or
			selfTurnSpeedChange or selfIncomeChange or disarmed or completeDisable or selfAccelerationChange then
		
		local baseSpeedMult   = (1 - (slowState or 0))*(zombieSpeedMult or 1)
		
		local econMult   = (baseSpeedMult)*(1 - disarmed)*(1 - completeDisable)*(selfIncomeChange or 1)
		local buildMult  = (baseSpeedMult)*(1 - disarmed)*(1 - completeDisable)*(selfIncomeChange or 1)*(buildpowerMult or 1)
		local moveMult   = (baseSpeedMult)*(selfMoveSpeedChange or 1)*(1 - completeDisable)*(upgradesSpeedMult or 1)
		local turnMult   = (baseSpeedMult)*(selfMoveSpeedChange or 1)*(selfTurnSpeedChange or 1)*(1 - completeDisable)
		local reloadMult = (baseSpeedMult)*(selfReloadSpeedChange or 1)*(1 - disarmed)*(1 - completeDisable)
		local maxAccMult = (baseSpeedMult)*(selfMaxAccelerationChange or 1)*(upgradesSpeedMult or 1)

		if fullDisable then
			buildMult = 0
			moveMult = 0
			turnMult = 0
			reloadMult = 0
			maxAccMult = 0
		end
		
		-- Let other gadgets and widgets get the total effect without 
		-- duplicating the pevious calculations.
		spSetUnitRulesParam(unitID, "baseSpeedMult", baseSpeedMult, INLOS_ACCESS) -- Guaranteed not to be 0
		spSetUnitRulesParam(unitID, "totalReloadSpeedChange", reloadMult, INLOS_ACCESS)
		spSetUnitRulesParam(unitID, "totalEconomyChange", econMult, INLOS_ACCESS)
		spSetUnitRulesParam(unitID, "totalBuildPowerChange", buildMult, INLOS_ACCESS)
		spSetUnitRulesParam(unitID, "totalMoveSpeedChange", moveMult, INLOS_ACCESS)
		
		unitSlowed[unitID] = moveMult < 1
		if reloadMult ~= currentReload[unitID] then
			UpdateReloadSpeed(unitID, ud, reloadMult, frame)
			currentReload[unitID] = reloadMult
		end
		
		if currentMovement[unitID] ~= moveMult or currentTurn[unitID] ~= turnMult or currentAcc[unitID] ~= maxAccMult then
			UpdateMovementSpeed(unitID, ud, moveMult, turnMult, maxAccMult*moveMult)
			currentMovement[unitID] = moveMult
			currentTurn[unitID] = turnMult
			currentAcc[unitID] = maxAccMult
		end
		
		if buildMult ~= currentBuildpower[unitID] then
			UpdateBuildSpeed(unitID, ud, buildMult)
			currentBuildpower[unitID] = buildMult
		end
		
		if econMult ~= currentEcon[unitID] then
			UpdateEconomy(unitID, ud, econMult)
			currentEcon[unitID] = econMult
		end
		if econMult ~= 1 or moveMult ~= 1 or reloadMult ~= 1 or turnMult ~= 1 or maxAccMult ~= 1 then
			changedAtt = true
		end
	else
		unitSlowed[unitID] = nil
	end
	
	local forcedOff = spGetUnitRulesParam(unitID, "forcedOff")
	local abilityDisabled = (forcedOff == 1 or disarmed == 1 or completeDisable == 1 or crashing == 1)
	local setNewState
	
	if abilityDisabled ~= unitAbilityDisabled[unitID] then
		spSetUnitRulesParam(unitID, "att_abilityDisabled", abilityDisabled and 1 or 0)
		unitAbilityDisabled[unitID] = abilityDisabled
		setNewState = true
	end
	
	if ud.shieldWeaponDef and spGetUnitRulesParam(unitID, "comm_shield_max") ~= 0 and setNewState then
		if abilityDisabled then
			Spring.SetUnitShieldState(unitID, spGetUnitRulesParam(unitID, "comm_shield_num") or -1, false)
		else
			Spring.SetUnitShieldState(unitID, spGetUnitRulesParam(unitID, "comm_shield_num") or -1, true)
		end
	end
	
	local radarOverride = spGetUnitRulesParam(unitID, "radarRangeOverride")
	local sonarOverride = spGetUnitRulesParam(unitID, "sonarRangeOverride")
	local jammerOverride = spGetUnitRulesParam(unitID, "jammingRangeOverride")
	local sightOverride = spGetUnitRulesParam(unitID, "sightRangeOverride")
	
	if setNewState or radarOverride or sonarOverride or jammerOverride or sightOverride then
		changedAtt = true
		abilityDisabled = abilityDisabled and not ud.isFirePlatform -- Can't have surfboard losing sensors
		UpdateSensorAndJamm(unitID, udid, not abilityDisabled, radarOverride, sonarOverride, jammerOverride, sightOverride)
	end

	local cloakBlocked = (spGetUnitRulesParam(unitID,"on_fire") == 1) or (disarmed == 1) or (completeDisable == 1)
	if cloakBlocked then
		GG.PokeDecloakUnit(unitID, 1)
	end

	-- remove the attributes if nothing is being changed
	if not changedAtt then
		removeUnit(unitID)
	end
end

function gadget:Initialize()
	GG.UpdateUnitAttributes = UpdateUnitAttributes
end

function gadget:GameFrame(f)
	if f % UPDATE_PERIOD == 1 then
		for unitID, unitDefID in pairs(unitReloadPaused) do
			UpdatePausedReload(unitID, unitDefID, f)
		end
	end
end

function gadget:UnitDestroyed(unitID)
	removeUnit(unitID)
end

function gadget:AllowCommand_GetWantedCommand()
	return true --{[CMD.ONOFF] = true, [70] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == 70 and unitSlowed[unitID]) then
		return false
	else 
		return true
	end
end

-- All information required for load is stored in unitRulesParams.
function gadget:Load(zip)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		UpdateUnitAttributes(unitID)
	end
end
