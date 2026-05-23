
if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	return {
		name      = "Unit Death Explosion",
		desc      = "Handles Unit Death Explosion",
		author    = "XNTEABDSC", -- v1 CarReparier & GoogleFrog
		date      = "2025", -- v1 2009-11-27
		license   = "GNU GPL, v2 or later",
		layer     = 1,
		enabled   = true,
	}
end

local spGetUnitRulesParam=Spring.GetUnitRulesParam
local spSpawnProjectile=Spring.SpawnProjectile
local spSetProjectileCollision=Spring.SetProjectileCollision
local Vector = Spring.Utilities.Vector

local explosionDefID = {}
local explosionRadius = {}
local function AddExplosions(unitID, unitDefID, teamID, expMult)
	if expMult <= 1 then -- Unsupported
		return
	end
	local extraExplosions = math.max(1, math.floor(expMult - 0.5))
	local explosionDamageMult = extraExplosions / (expMult - 1)
	if not explosionDefID[unitDefID] then
		local wd = WeaponDefNames[UnitDefs[unitDefID].deathExplosion]
		explosionDefID[unitDefID] = wd.id
		explosionRadius[unitDefID] = wd.damageAreaOfEffect or 0
	end
	local _, _, _, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
	local projectileParams = {
		pos = {ux, uy, uz},
		["end"] = {ux, uy - 1, uz},
		owner = unitID,
		team = teamID,
		ttl = 0,
	}
	local expLevel = 1 + math.log(expMult) / math.log(2)
	local radius = (5 + 15*expLevel)*(50 + math.pow(explosionRadius[unitDefID], 0.8))/100
	for i = 1, extraExplosions do
		local rand = Vector.RandomPointInCircle(radius)
		projectileParams.pos[1] = ux + rand[1]
		projectileParams.pos[3] = uz + rand[2]
		local proID = spSpawnProjectile(explosionDefID[unitDefID], projectileParams)
		-- TODO: Handle explosionDamageMult ~= 1 with SetProjectileDamages
		if proID then
			spSetProjectileCollision(proID)
		end
	end
end


function gadget:UnitDestroyed(unitID, unitDefID, teamID)
    local deathExplodeMult=spGetUnitRulesParam(unitID, "deathExplodeMult")
	if deathExplodeMult and deathExplodeMult ~= 1 then
		if GG.MorphDestroy ~= unitID then
			local _,_,_,_,build  = Spring.GetUnitHealth(unitID)
			if build and build >= 0.8 then
				AddExplosions(unitID, unitDefID, teamID, deathExplodeMult)
			end
		end
	end
end