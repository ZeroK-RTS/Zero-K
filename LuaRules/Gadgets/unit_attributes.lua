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

local UPDATE_PERIOD = 15

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetUnitDefID        	= Spring.GetUnitDefID
local spGetUnitRulesParam  		= Spring.GetUnitRulesParam

local spSetUnitWeaponState  = Spring.SetUnitWeaponState
local spGetUnitWeaponState  = Spring.GetUnitWeaponState

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

origUnitSpeed = {}
origUnitReload = {}
origUnitBuildPower = {}

if not GG.attUnits then
	GG.attUnits = {}
end

local function updateReloadSpeed( unitID, ud, speedFactor, gameFrame)
	
	if not origUnitReload[unitID] then
	
		origUnitReload[unitID] = {
			weapon = {},
			weaponCount = #ud.weapons-1,
		}
		local state = origUnitReload[unitID]
		
		for i = 0, state.weaponCount do
			local reload = WeaponDefs[ud.weapons[i+1].weaponDef].reload
			state.weapon[i] = {
				reload = reload,
				prevReload = reload,
				burstRate = WeaponDefs[ud.weapons[i+1].weaponDef].salvoDelay,
				oldReloadFrames = math.floor(reload*30),
			}
			if WeaponDefs[ud.weapons[i+1].weaponDef].type == "BeamLaser" then
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
				w.prevReload = newReload
			else
				local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload+UPDATE_PERIOD})
				w.prevReload = newReload
			end
			-- add UPDATE_PERIOD so that the reload time never advances past what it is now
		else
			local newReload = w.reload/speedFactor
			local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
			if w.burstRate then
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload, burstRate = w.burstRate/speedFactor})
				w.prevReload = newReload
			else
				spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload})
				w.prevReload = newReload
			end
		end
	end
	
end


local function updateMovementSpeed( unitID, ud, speedFactor)	
	
	if not origUnitSpeed[unitID] then
	
		origUnitSpeed[unitID] = {
			origSpeed = ud.speed,
			--origReverseSpeed = ud.rspeed,
			origTurnRate = ud.turnRate,
			origMaxAcc = ud.maxAcc,
			origMaxDec = ud.maxDec,
			movetype = -1,
		}
		
		local state = origUnitSpeed[unitID]
		
		if ud.canFly then
			if ud.isFighter or ud.isBomber then
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
	
	if Spring.MoveCtrl.GetTag(unitID) == nil then
		if state.movetype == 0 then
			Spring.MoveCtrl.SetAirMoveTypeData(unitID, {maxSpeed = state.origSpeed*speedFactor})
			Spring.MoveCtrl.SetAirMoveTypeData (unitID, {maxAcc = state.origMaxAcc*(speedFactor > 0.001 and speedFactor or 0.001)})
		elseif state.movetype == 1 then
			Spring.MoveCtrl.SetGunshipMoveTypeData (unitID, {maxSpeed = state.origSpeed*speedFactor})
			--Spring.MoveCtrl.SetGunshipMoveTypeData (unitID, {maxSpeed = state.origReverseSpeed*speedFactor})
			Spring.MoveCtrl.SetGunshipMoveTypeData (unitID, {turnRate = state.origTurnRate*speedFactor})
			Spring.MoveCtrl.SetGunshipMoveTypeData (unitID, {accRate = state.origMaxAcc*(speedFactor > 0.001 and speedFactor or 0.001)})
			Spring.MoveCtrl.SetGunshipMoveTypeData (unitID, {decRate = state.origMaxDec*(speedFactor > 0.01 and speedFactor or 0.01)})
		elseif state.movetype == 2 then
			Spring.MoveCtrl.SetGroundMoveTypeData(unitID, {maxSpeed = state.origSpeed*speedFactor})
			--Spring.MoveCtrl.SetGroundMoveTypeData (unitID, {maxSpeed = state.origReverseSpeed*speedFactor})
			Spring.MoveCtrl.SetGroundMoveTypeData (unitID, {turnRate = state.origTurnRate*speedFactor})
			Spring.MoveCtrl.SetGroundMoveTypeData (unitID, {accRate = state.origMaxAcc*speedFactor})
			Spring.MoveCtrl.SetGroundMoveTypeData (unitID, {decRate = state.origMaxDec*decFactor})
		end
	end
	
end

local function removeUnit(unitID)
	GG.attUnits[unitID] = nil
	origUnitSpeed[unitID] = nil
	origUnitReload[unitID] = nil
end

function GG.UpdateUnitAttributes(unitID, frame)
	if not Spring.ValidUnitID(unitID) then
		removeUnit(unitID)
	end
	
	local udid = spGetUnitDefID(unitID)
	if not udid then 
		return 
	end
		
	frame = frame or Spring.GetGameFrame()
	
	local ud = UnitDefs[udid]
	local changedAtt = false
	
	-- Increased reload from CAPTURE --
	local captureMult = spGetUnitRulesParam(unitID,"captureReloadMult")
	-- SLOW --
	local slowState = spGetUnitRulesParam(unitID,"slowState")
	
	if slowState or captureMult then
		updateReloadSpeed(unitID, ud, (1-(slowState or 0))*(captureMult or 1), frame)
		updateMovementSpeed(unitID,ud,1-(slowState or 0))
		
		if slowState ~= 0 and captureMult ~= 1 then
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

