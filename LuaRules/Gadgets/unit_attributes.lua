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

if not GG.attUnits then
	GG.attUnits = {}
end

local function updateReloadSpeed( unitID, ud, speedFactor)
	
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
				oldReloadFrames = math.floor(reload*30),
			}
		end
		
	end
	
	local state = origUnitReload[unitID]
	
	for i = 0, state.weaponCount do
		local w = state.weapon[i]
		local newReload = w.reload * (1+speedFactor*2) 
		spSetUnitWeaponState(unitID, i, {reloadTime = newReload})
		
		local newReloadFrames = math.floor(newReload*30)
		local reloadChange = newReloadFrames - w.oldReloadFrames
		w.oldReloadFrames = newReloadFrames
		
		local reloadState = spGetUnitWeaponState(unitID, i , 'reloadState')
		spSetUnitWeaponState(unitID, i, {reloadState = reloadState+reloadChange})
	end
	
end


local function updateMovementSpeed( unitID, ud, speedFactor)	
	
	if not origUnitSpeed[unitID] then
	
		origUnitSpeed[unitID] = {
			origSpeed = ud.speed,
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
	
	if Spring.MoveCtrl.GetTag(unitID) == nil then
		if state.movetype == 0 then
			Spring.MoveCtrl.SetAirMoveTypeData(unitID, {maxSpeed = state.origSpeed*(1-speedFactor)})
		elseif state.movetype == 1 then
			Spring.MoveCtrl.SetGunshipMoveTypeData (unitID, {maxSpeed = state.origSpeed*(1-speedFactor)})
		elseif state.movetype == 2 then
			Spring.MoveCtrl.SetGroundMoveTypeData(unitID, {maxSpeed = state.origSpeed*(1-speedFactor)})
		end
	end
	
end

local function removeUnit(unitID)
	GG.attUnits[unitID] = nil
	origUnitSpeed[unitID] = nil
	origUnitReload[unitID] = nil
end

function gadget:GameFrame(f)
	
	if f % 16 == 1 then
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
				updateReloadSpeed(unitID,ud,slowState)
				updateMovementSpeed(unitID,ud,slowState)
				
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

