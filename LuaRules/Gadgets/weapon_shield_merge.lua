--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Shield Merge",
		desc = "Implements shields as if they had a large shared battery between adjacent shields.",
		author = "GoogleFrog",
		date = "30 July 2016",
		license = "None",
		layer = 100,
		enabled = true
	}
end

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitTeam			= Spring.GetUnitTeam
local spGetTeamInfo			= Spring.GetTeamInfo
local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitIsStunned	= Spring.GetUnitIsStunned

local modOptions = Spring.GetModOptions()
local MERGE_ENABLED = (modOptions.shield_merge == "share")
local PARTIAL_PENETRATE = (modOptions.shield_merge == "penetrate")

local SHIELD_ARMOR = Game.armorTypes.shield

local allyTeamShields = {}
local gameFrame = 0

local shieldDamages = {}
for i = 1, #WeaponDefs do
	shieldDamages[i] = tonumber(WeaponDefs[i].customParams.shield_damage)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Network management

local function ShieldsAreTouching(shield1, shield2)
	local xDiff = shield1.x - shield2.x
	local zDiff = shield1.z - shield2.z
	local yDiff = shield1.y - shield2.y
	local sumRadius = shield1.shieldRadius + shield2.shieldRadius
	return xDiff <= sumRadius and zDiff <= sumRadius and (xDiff*xDiff + yDiff*yDiff + zDiff*zDiff) < sumRadius*sumRadius 
end

local otherID
local otherData
local otherMobile
local function UpdateLink(unitID, unitData)
	if unitID ~= otherID and (otherMobile or unitData.mobile) then
		local currentlyNeighbors = (otherData.neighbors.InMap(unitID) or unitData.neighbors.InMap(otherID))
		local touching = ShieldsAreTouching(unitData, otherData)
		if currentlyNeighbors and not touching then
			--Spring.Utilities.UnitEcho(unitID, "-")
			--Spring.Utilities.UnitEcho(otherID, "-")
			otherData.neighbors.Remove(unitID)
			unitData.neighbors.Remove(otherID)
		elseif touching and not currentlyNeighbors then
			--Spring.Utilities.UnitEcho(unitID, "+")
			--Spring.Utilities.UnitEcho(otherID, "+")
			otherData.neighbors.Add(unitID)
			unitData.neighbors.Add(otherID)
		end
	end
end

local function AdjustLinks(unitID, shieldUnits)
	otherID = unitID
	otherData = shieldUnits.Get(unitID)
	if otherData then
		if otherData.mobilesAdded then
			otherMobile = otherData.mobile
		else
			otherData.mobilesAdded = true
			otherMobile = true
		end
		shieldUnits.Apply(UpdateLink)
	end
end

local function PossiblyUpdateLinks(unitID, allyTeamID)
	local shieldUnits = allyTeamShields[allyTeamID]
	local unitData = shieldUnits.Get(unitID)
	if not unitData then
		return
	end
	if unitData.nextUpdateTime < gameFrame then
		unitData.nextUpdateTime = gameFrame + 15
		AdjustLinks(unitID, shieldUnits)
	end
end

local function RemoveNeighbor(unitID, _, _, thisShieldTeam, toRemoveID)
	if thisShieldTeam.InMap(unitID) then
		thisShieldTeam.Get(unitID).neighbors.Remove(toRemoveID)
	end
end

local function RemoveUnitFromNeighbors(thisShieldTeam, unitID, neighbors)
	neighbors.Apply(RemoveNeighbor, thisShieldTeam, unitID)
end

local function UpdatePosition(unitID, unitData)
	if unitData.mobile then
		local ux,uy,uz = spGetUnitPosition(unitID)
		unitData.x = ux
		unitData.y = uy
		unitData.z = uz
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit tracking

function gadget:UnitCreated(unitID, unitDefID)
	-- only count finished buildings
	local stunned_or_inbuild, stunned, inbuild = spGetUnitIsStunned(unitID)
	if stunned_or_inbuild ~= nil and inbuild then
		return
	end
	
	local ud = UnitDefs[unitDefID]
	
	local shieldWeaponDefID
	local shieldNum = -1
	if ud.customParams.dynamic_comm then
		if GG.Upgrades_UnitShieldDef then
			shieldWeaponDefID, shieldNum = GG.Upgrades_UnitShieldDef(unitID)
		end
	else
		shieldWeaponDefID = ud.shieldWeaponDef
	end
	
	if shieldWeaponDefID then
		local shieldWep = WeaponDefs[shieldWeaponDefID]
		local allyTeamID = spGetUnitAllyTeam(unitID)
		if not (allyTeamShields[allyTeamID] and allyTeamShields[allyTeamID].InMap(unitID)) then 
			-- not need to redo table if already have table (UnitFinished() will call this function 2nd time)
			allyTeamShields[allyTeamID] = allyTeamShields[allyTeamID] or IterableMap.New()
			
			local ux,uy,uz = spGetUnitPosition(unitID)
			
			local shieldData = {
				shieldRadius = shieldWep.shieldRadius,
				neighbors    = IterableMap.New(),
				allyTeamID   = allyTeamID,
				nextUpdateTime = gameFrame,
				x = ux,
				y = uy,
				z = uz,
				mobile = Spring.Utilities.getMovetype(ud) and true
			}
			allyTeamShields[allyTeamID].Add(unitID, shieldData)
			AdjustLinks(unitID, allyTeamShields[allyTeamID])
		end
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	gadget:UnitCreated(unitID, unitDefID)
end

function gadget:UnitDestroyed(unitID, unitDefID)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	if allyTeamShields[allyTeamID] and allyTeamShields[allyTeamID].InMap(unitID) then
		local unitData = allyTeamShields[allyTeamID].Get(unitID)
		if unitData then
			RemoveUnitFromNeighbors(allyTeamShields[allyTeamID], unitID, unitData.neighbors)
		end
		allyTeamShields[allyTeamID].Remove(unitID)
	end
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeam, false)
	local allyTeamID = spGetUnitAllyTeam(unitID)
	if allyTeamID and allyTeamShields[oldAllyTeam] and allyTeamShields[oldAllyTeam].InMap(unitID) then
		local unitData
		if allyTeamShields[oldAllyTeam] and allyTeamShields[oldAllyTeam].InMap(unitID) then
			unitData = allyTeamShields[oldAllyTeam].Get(unitID)
			
			allyTeamShields[oldAllyTeam].Remove(unitID)
			RemoveUnitFromNeighbors(allyTeamShields[oldAllyTeam], unitID, unitData.neighbors)
			unitData.neighbors = IterableMap.New()
			unitData.allyTeamID = allyTeamID
		end
		if unitData then
			--Note: wont be problem when NIL when nanoframe is captured because is always filled with new value when unit finish
			allyTeamShields[allyTeamID] = allyTeamShields[allyTeamID] or IterableMap.New()
			allyTeamShields[allyTeamID].Add(unitID, unitData)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Hit and update handling

local beamMultiHitException = {
	[UnitDefNames["amphassault"].id] = true,
	[UnitDefNames["striderdetriment"].id] = true,
}
local repeatedHits = {}
local penetrationPower = {}

function gadget:GameFrame(n)
	repeatedHits = {} -- Feel sorry for GC
	if not MERGE_ENABLED then
		return
	end
	gameFrame = n
	if n%13 == 7 then
		for allyTeamID, unitList in pairs(allyTeamShields) do
			unitList.ApplyNoArg(UpdatePosition)
		end
	end
end

-- Evil
local totalCharge = 0
local shieldCharges = nil
local chargeProportion = 1
local function SumCharge(unitID, _, index)
	shieldCharges[index] = select(2, Spring.GetUnitShieldState(unitID)) or 0
	totalCharge = totalCharge + shieldCharges[index]
end

-- Double evil
local function SetCharge(unitID, _, index)
	Spring.SetUnitShieldState(unitID, -1, true, shieldCharges[index]*chargeProportion)
end

local function DrainShieldAndCheckProjectilePenetrate(unitID, damage, realDamage, proID)
	local _, charge = Spring.GetUnitShieldState(unitID)
	local origDamage = damage
	
	if PARTIAL_PENETRATE and penetrationPower[proID] then
		damage = penetrationPower[proID]
		penetrationPower[proID] = nil
	end
	
	if charge and damage < charge then
		Spring.SetUnitShieldState(unitID, -1, true, charge - damage + realDamage)
		return false
	elseif MERGE_ENABLED then
		damage = damage - charge
		local allyTeamID = Spring.GetUnitAllyTeam(unitID)
		PossiblyUpdateLinks(unitID, allyTeamID)
		local shieldData = allyTeamShields[allyTeamID].Get(unitID)
		
		if shieldData then
			totalCharge = 0
			shieldCharges = {}
			shieldData.neighbors.ApplyNoArg(SumCharge)

			if damage < totalCharge then
				Spring.SetUnitShieldState(unitID, -1, true, realDamage)
				chargeProportion = 1 - damage/totalCharge
				shieldData.neighbors.ApplyNoArg(SetCharge)
				shieldCharges = nil
				return false
			end
		end
		shieldCharges = nil
	elseif PARTIAL_PENETRATE and proID then
		local remainingPower = damage - charge
		penetrationPower[proID] = remainingPower
		Spring.SetUnitShieldState(unitID, -1, true, 0)
		if Spring.GetProjectileDefID(proID) then -- some projectile IDs are not integers.
			local gravity = Spring.GetProjectileGravity(proID)
			local vx, vy, vz = Spring.GetProjectileVelocity(proID)
			local mult = 0.75 + 0.25*remainingPower/origDamage
			Spring.SetProjectileGravity(proID, gravity*mult^2)
			Spring.SetProjectileVelocity(proID, vx*mult, vy*mult, vz*mult)
		end
	end
	return true
end

function gadget:ShieldPreDamaged(proID, proOwnerID, shieldEmitterWeaponNum, shieldCarrierUnitID, bounceProjectile, beamEmitter, beamCarrierID)
	local weaponDefID
	local hackyProID
	
	if (not Spring.ValidUnitID(shieldCarrierUnitID)) or Spring.GetUnitIsDead(shieldCarrierUnitID) then
		return false
	end	
	
	if proID == -1 then
		local unitDefID = Spring.GetUnitDefID(beamCarrierID)
		-- Beam weapons hit shields four times per frame.
		-- No idea why.
		if not beamMultiHitException[unitDefID] then
			hackyProID = beamCarrierID + beamEmitter/64
			repeatedHits[shieldCarrierUnitID] = repeatedHits[shieldCarrierUnitID] or {}
			if repeatedHits[shieldCarrierUnitID][hackyProID] ~= nil then
				return repeatedHits[shieldCarrierUnitID][hackyProID]
			end
		end
		-- Beam weapon
		local ud = beamCarrierID and UnitDefs[unitDefID]
		if not ud then
			return true
		end
		weaponDefID = ud.weapons[beamEmitter].weaponDef 
	else
		-- Projectile
		weaponDefID = Spring.GetProjectileDefID(proID)
	end
	
	if not weaponDefID then
		return true
	end

	local wd = WeaponDefs[weaponDefID]
	local damage = shieldDamages[weaponDefID]
	
	local projectilePasses = DrainShieldAndCheckProjectilePenetrate(shieldCarrierUnitID, damage, wd.damages[SHIELD_ARMOR], hackyProID or proID)
	
	if hackyProID then
		repeatedHits[shieldCarrierUnitID][hackyProID] = projectilePasses
	end
	return projectilePasses
end

local function RegenerateData()
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = spGetUnitTeam(unitID)
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

function gadget:Load()
	if MERGE_ENABLED then
		RegenerateData()
	end
end

function gadget:Initialize()
	GG.DrainShieldAndCheckProjectilePenetrate = DrainShieldAndCheckProjectilePenetrate
	
	if MERGE_ENABLED then
		RegenerateData()
	else
		gadgetHandler:RemoveCallIn("UnitCreated")
		gadgetHandler:RemoveCallIn("UnitFinished")
		gadgetHandler:RemoveCallIn("UnitDestroyed")
		gadgetHandler:RemoveCallIn("UnitGiven")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
