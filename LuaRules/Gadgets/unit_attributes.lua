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
				burstRate = WeaponDefs[ud.weapons[i+1].weaponDef].salvoDelay,
				oldReloadFrames = math.floor(reload*30),
			}
		end
		
	end
	
	local state = origUnitReload[unitID]
	
	for i = 0, state.weaponCount do
		local w = state.weapon[i]
		local reloadState = spGetUnitWeaponState(unitID, i , 'reloadState')
		local reloadTime = spGetUnitWeaponState(unitID, i , 'reloadTime')
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
			spSetUnitWeaponState(unitID, i, {reloadTime = newReload, reloadState = nextReload, burstRate = w.burstRate/speedFactor})
		end
	end
	
end


local function updateMovementSpeed( unitID, ud, speedFactor)	
	
	if not origUnitSpeed[unitID] then
	
		origUnitSpeed[unitID] = {
			origSpeed = ud.speed,
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
	if speedFactor < 0 then
		speedFactor = 0
		decFactor = 100000 -- a unit with 0 decRate will not deccelerate down to it's 0 maxVelocity
	end
	
	if Spring.MoveCtrl.GetTag(unitID) == nil then
		if state.movetype == 0 then
			Spring.MoveCtrl.SetAirMoveTypeData(unitID, {maxSpeed = state.origSpeed*speedFactor})
			Spring.MoveCtrl.SetAirMoveTypeData (unitID, {maxAcc = state.origMaxAcc*decFactor})
		elseif state.movetype == 1 then
			Spring.MoveCtrl.SetGunshipMoveTypeData (unitID, {maxSpeed = state.origSpeed*speedFactor})
			Spring.MoveCtrl.SetGunshipMoveTypeData (unitID, {turnRate = state.origTurnRate*speedFactor})
			Spring.MoveCtrl.SetGunshipMoveTypeData (unitID, {accRate = state.origMaxAcc*speedFactor})
			Spring.MoveCtrl.SetGunshipMoveTypeData (unitID, {decRate = state.origMaxDec*decFactor})
		elseif state.movetype == 2 then
			Spring.MoveCtrl.SetGroundMoveTypeData(unitID, {maxSpeed = state.origSpeed*speedFactor})
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

function gadget:GameFrame(f)
	
	if f % UPDATE_PERIOD == 1 then
		for unitID, teamID in pairs(GG.attUnits) do
		
			if not Spring.ValidUnitID(unitID) then
				removeUnit(unitID)
			end
		
			local udid = spGetUnitDefID(unitID)
			if not udid then 
				return 
			end
				
			local ud = UnitDefs[udid]
			local changedAtt = false
			
			-- SLOW --
			local slowState = spGetUnitRulesParam(unitID,"slowState")
			if slowState then
				updateReloadSpeed(unitID, ud, 1-slowState, f)
				updateMovementSpeed(unitID,ud,1-slowState)
				
				if slowState ~= 0 then
					changedAtt = true
				end
			end
			--end slow
			
			-- remove the attributes if nothing is being changed
			if not changedAtt then
				removeUnit(unitID)
			end
			
		end
	end
	
end

