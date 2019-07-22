-- $Id: unit_terraform.lua 3299 2008-11-25 07:25:57Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name     = "Nano Frame Death Handeling",
		desc     = "Makes nanoframes explode if above X% completion and makes dying nanoframes leave wrecks.",
		author	 = "Google Frog",
		date     = "Mar 29, 2009",
		license	 = "GNU GPL, v2 or later",
		layer    = -10,
		enabled  = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
	return false	--	no unsynced code
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Speedups

local spSetUnitHealth = Spring.SetUnitHealth
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitPosition	= Spring.GetUnitPosition
local spGetUnitBuildFacing	= Spring.GetUnitBuildFacing
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit
local spGetUnitSelfDTime = Spring.GetUnitSelfDTime


local spSetFeatureResurrect = Spring.SetFeatureResurrect
local spSetFeatureHealth = Spring.SetFeatureHealth
local spSetFeatureReclaim = Spring.SetFeatureReclaim
local spGetGroundHeight = Spring.GetGroundHeight
local spCreateFeature = Spring.CreateFeature

local spValidUnitID = Spring.ValidUnitID

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local unitFromFactory = {}
local isAFactory = {}

function gadget:UnitCreated(unitID,unitDefID,_,builderID)
	local ud = UnitDefs[unitDefID]
	if ud and ud.isFactory then
		isAFactory[unitID] = true
	end
	if builderID and isAFactory[builderID] then
		unitFromFactory[unitID] = true
	end
end

local function ScrapUnit(unitID, unitDefID, team, progress, face)
	if (unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].wreckName and FeatureDefNames[UnitDefs[unitDefID].wreckName]) then
		local wreck = FeatureDefNames[UnitDefs[unitDefID].wreckName].id
		if (wreck and FeatureDefs[wreck]) then		 
			local nextWreck = FeatureDefs[wreck].deathFeatureID
			if nextWreck and FeatureDefs[nextWreck] then
				wreck = FeatureDefs[wreck].deathFeatureID
				if progress < 0.5 then
					nextWreck = FeatureDefs[wreck].deathFeatureID
					if nextWreck and FeatureDefs[nextWreck] then
						wreck = FeatureDefs[wreck].deathFeatureID
						progress = progress * 2
					end
				end
			end
			local x, _, z = spGetUnitPosition(unitID)
			local y = spGetGroundHeight(x, z)
			if (progress == 0) then
				progress = 0.001
			end
			local allyTeam = select(6, Spring.GetTeamInfo(team, false))
			local featureID = spCreateFeature(wreck, x, y, z, face, allyTeam)
			if featureID then
				Spring.TransferFeature(featureID, team)

				local currentMetal = progress * FeatureDefs[wreck].metal
				if Spring.SetFeatureResources then -- 103.0 non-dev version compat
					Spring.SetFeatureResources(featureID, currentMetal, 0, currentMetal, progress)
				else
					Spring.SetFeatureReclaim(featureID, progress)
				end

				spSetFeatureHealth(featureID, progress * FeatureDefs[wreck].maxHealth)
			else
				Spring.Echo("No featureID", wreck)
			end
		end
	end
end

local spawnProjPos = {1, 2, 3}
local spawnProjTable = {ttl = 1, pos = spawnProjPos}
function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)

	local health, _,_,_,progress = spGetUnitHealth(unitID)

	if (progress == 1) or (health > 0 and unitFromFactory[unitID]) or GG.wasMorphedTo[unitID] then
		isAFactory[unitID] = nil
		unitFromFactory[unitID] = nil
		return
	end

	local ud = UnitDefs[unitDefID]
	local face = (spGetUnitBuildFacing(unitID) or 1)
	local noWreck = Spring.GetUnitRulesParam(unitID, "noWreck") == 1	-- set by api_saveload to clear stuff from factories
	
	if (progress > 0.8 and not noWreck) then
		local explodeAs = ud.deathExplosion
		if explodeAs then
			local wd = WeaponDefNames[explodeAs]
			if wd then
				local _,_,_,x,y,z = spGetUnitPosition(unitID, true)
				spawnProjPos[1] = x
				spawnProjPos[2] = y
				spawnProjPos[3] = z
				local projId = Spring.SpawnProjectile(wd.id, spawnProjTable)
				--Spring.SetProjectileCollision(projId) <- in case ttl = 1 does not work
			end
		end
	end
	
	if (progress > 0.05 and not noWreck) then
		ScrapUnit(unitID, unitDefID, unitTeam, progress, face)
	end
	
	isAFactory[unitID] = nil
	unitFromFactory[unitID] = nil
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local team = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, team)
	end
	
	GG.wasMorphedTo = GG.wasMorphedTo or {}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
