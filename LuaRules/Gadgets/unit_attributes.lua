--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Attributes",
      desc      = "Handles UnitRulesParam attributes.",
      author    = "CarRepairer & Google Frog",
      date      = "2009-11-27",
      license   = "GNU GPL, v2 or later",
      layer     = -1,
      enabled   = true, 
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if not gadgetHandler:IsSyncedCode() then
	return
end

local UPDATE_PERIOD = 3 -- see http://springrts.com/mantis/view.php?id=3048

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local floor = math.floor

local spValidUnitID         = Spring.ValidUnitID
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetGameFrame        = Spring.GetGameFrame
local spGetUnitRulesParam  	= Spring.GetUnitRulesParam

local spSetUnitBuildSpeed   = Spring.SetUnitBuildSpeed
local spSetUnitWeaponState  = Spring.SetUnitWeaponState
local spGetUnitWeaponState  = Spring.GetUnitWeaponState

local spGetUnitMoveTypeData    = Spring.GetUnitMoveTypeData
local spMoveCtrlGetTag         = Spring.MoveCtrl.GetTag
local spSetAirMoveTypeData     = Spring.MoveCtrl.SetAirMoveTypeData
local spSetGunshipMoveTypeData = Spring.MoveCtrl.SetGunshipMoveTypeData
local spSetGroundMoveTypeData  = Spring.MoveCtrl.SetGroundMoveTypeData

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local origUnitSpeed = {}
local origUnitReload = {}
local origUnitBuildSpeed = {}

if not GG.attUnits then
	GG.attUnits = {}
end

if not GG.att_reload then
	GG.att_reload = {}
end


local function updateBuildSpeed(unitID, ud, speedFactor)	

    if ud.buildSpeed == 0 then
        return
    end
        
    if not origUnitBuildSpeed[unitID] then
    
        origUnitBuildSpeed[unitID] = {
            buildSpeed = ud.buildSpeed,
        }
    end

    local state = origUnitBuildSpeed[unitID]

    spSetUnitBuildSpeed(unitID, 
        state.buildSpeed*speedFactor, -- build
        state.buildSpeed*speedFactor, -- repair
        state.buildSpeed*speedFactor, -- reclaim
        state.buildSpeed*speedFactor) -- rezz
    
end

local function updateReloadSpeed(unitID, ud, speedFactor, gameFrame)
	
	if not origUnitReload[unitID] then
	
		origUnitReload[unitID] = {
			weapon = {},
			weaponCount = #ud.weapons-1,
		}
		local state = origUnitReload[unitID]
		
		for i = 0, state.weaponCount do
			local wd = WeaponDefs[ud.weapons[i+1].weaponDef]
			local reload = wd.reload
			state.weapon[i] = {
				reload = reload,
				prevReload = reload,
				burstRate = wd.salvoDelay,
				oldReloadFrames = floor(reload*30),
			}
			if wd.type == "BeamLaser" then
				state.weapon[i].burstRate = false -- beamlasers go screwy if you mess with their burst length
			end
		end
		
	end
	
	local state = origUnitReload[unitID]
	
	for i = 0, state.weaponCount do
		local w = state.weapon[i]
		local reloadState = spGetUnitWeaponState(unitID, i , 'reloadState')
		local reloadTime = w.prevReload -- spGetUnitWeaponState(unitID, i , 'reloadTime') -- GetUnitWeaponState for reloadTime does not work
		if speedFactor <= 0 then
			local newReload = 100000 -- set a high reload time so healthbars don't judder. NOTE: math.huge is TOO LARGE
			if reloadState < 0 then -- unit is already reloaded, so set unit to almost reloaded
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = gameFrame+UPDATE_PERIOD+1})
			else
				local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload+UPDATE_PERIOD})
			end
			w.prevReload = newReload
			-- add UPDATE_PERIOD so that the reload time never advances past what it is now
		else
			local newReload = w.reload/speedFactor
			local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
			if w.burstRate then
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload, burstRate = w.burstRate/speedFactor})
			else
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload})
			end
			w.prevReload = newReload
		end
	end
	
end

local function updateMovementSpeed(unitID, ud, speedFactor)	
	
	if not origUnitSpeed[unitID] then
	
  	local moveData = spGetUnitMoveTypeData(unitID)
    
		origUnitSpeed[unitID] = {
			origSpeed = ud.speed,
			origReverseSpeed = (moveData.name == "ground") and moveData.maxReverseSpeed or ud.speed
			origTurnRate = ud.turnRate,
			origMaxAcc = ud.maxAcc,
			origMaxDec = ud.maxDec,
			movetype = -1,
		}
		
		local state = origUnitSpeed[unitID]
		
		if ud.canFly then
			if (ud.isFighter or ud.isBomber) then
				state.movetype = 0
			else
				state.movetype = 1
			end
		elseif not (ud.isBuilding or ud.isFactory or ud.speed == 0) then
			state.movetype = 2
		end
		
	end
	
	local state = origUnitSpeed[unitID]
	local decFactor = speedFactor
	if speedFactor <= 0 then
		speedFactor = 0
		decFactor = 100000 -- a unit with 0 decRate will not deccelerate down to it's 0 maxVelocity
	end
	
	if spMoveCtrlGetTag(unitID) == nil then
		if state.movetype == 0 then
			spSetAirMoveTypeData (unitID, {
				maxSpeed        = state.origSpeed       *speedFactor,
				maxAcc          = state.origMaxAcc      *(speedFactor > 0.001 and speedFactor or 0.001)
			})
		elseif state.movetype == 1 then
			spSetGunshipMoveTypeData (unitID, {
				maxSpeed        = state.origSpeed       *speedFactor,
				--maxReverseSpeed = state.origReverseSpeed*speedFactor,
				turnRate        = state.origTurnRate    *speedFactor,
				accRate         = state.origMaxAcc      *(speedFactor > 0.001 and speedFactor or 0.001),
				--decRate         = state.origMaxDec      *(speedFactor > 0.01  and speedFactor or 0.01)
			})
		elseif state.movetype == 2 then
			spSetGroundMoveTypeData (unitID, {
				maxSpeed        = state.origSpeed       *speedFactor,
				maxReverseSpeed = state.origReverseSpeed*speedFactor,
				turnRate        = state.origTurnRate    *speedFactor,
				accRate         = state.origMaxAcc      *speedFactor,
				decRate         = state.origMaxDec      *decFactor
			})
		end
	end
	
end

local function removeUnit(unitID)
	GG.attUnits[unitID] = nil
	origUnitSpeed[unitID] = nil
	origUnitReload[unitID] = nil
end

function GG.UpdateUnitAttributes(unitID, frame)
	if not spValidUnitID(unitID) then
		removeUnit(unitID)
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
	
	-- Unit speed change (like sprint) --
	local selfMoveSpeedChange = spGetUnitRulesParam(unitID, "selfMoveSpeedChange")
	
	-- SLOW --
	local slowState = spGetUnitRulesParam(unitID,"slowState")
	
	if selfReloadSpeedChange or selfMoveSpeedChange or slowState then
		local slowMult   = 1-(slowState or 0)
		local buildMult  = (slowMult)
		local moveMult   = (slowMult)*(selfMoveSpeedChange or 1)
		local reloadMult = (slowMult)*(selfReloadSpeedChange or 1)
	
		GG.att_reload[unitID] = reloadMult
	
		updateReloadSpeed(unitID, ud, reloadMult, frame)
		updateMovementSpeed(unitID,ud, moveMult)
		updateBuildSpeed(unitID, ud, buildMult)
		if buildMult ~= 1 or moveMult ~= 1 or reloadMult ~= 1 then
			changedAtt = true
		end
	end

	-- remove the attributes if nothing is being changed
	if not changedAtt then
		removeUnit(unitID)
	end
end

function gadget:GameFrame(f)
	
	if f % UPDATE_PERIOD == 1 then
		for unitID, teamID in pairs(GG.attUnits) do
			GG.UpdateUnitAttributes(unitID, f)
		end
	end
	
end

