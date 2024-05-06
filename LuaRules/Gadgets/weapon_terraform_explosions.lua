
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Terraformer Explosions",
		desc      = "Handles death and explosion terraform effects",
		author    = "GoogleFrog",
		date      = "6 April 2024",
		license   = "GNU GPL, v2 or later",
		layer     = 1,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local spGetUnitPosition     = Spring.GetUnitPosition
local spGetGroundHeight     = Spring.GetGroundHeight
local spSetHeightMapFunc    = Spring.SetHeightMapFunc
local spAddHeightMap        = Spring.AddHeightMap
local spGetUnitHealth       = Spring.GetUnitHealth

local floor                 = math.floor
local max                   = math.max
local min                   = math.min

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local terraformOnUnitDestroyed = VFS.Include("LuaRules/Configs/unit_terraform_defs.lua", nil, VFS.GAME)

local wantedList = {}
local SeismicWeapon = {}
local DEFAULT_SMOOTH = 0.5
local HEIGHT_FUDGE_FACTOR = 10
local HEIGHT_RAD_MULT = 0.8

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Weapon Terraform

local projectileDefs = {
	[WeaponDefNames["striderdozer_terra_spray"].id] = {
		fallShort = 1,
	},
}

for i = 1, #WeaponDefs do
	local wd = WeaponDefs[i]
	if wd.customParams and wd.customParams.smoothradius or wd.customParams.smoothmult then
		wantedList[#wantedList + 1] = wd.id
		Script.SetWatchExplosion(wd.id, true)
		SeismicWeapon[wd.id] = {
			smooth = wd.customParams.smoothmult or DEFAULT_SMOOTH,
			smoothradius = wd.customParams.smoothradius or wd.craterAreaOfEffect*0.5,
			gatherradius = wd.customParams.gatherradius or wd.craterAreaOfEffect*0.75,
			quickgather = wd.customParams.quickgather,
			detachmentradius = wd.customParams.detachmentradius,
			smoothheightoffset = wd.customParams.smoothheightoffset,
			movestructures = wd.customParams.movestructures,
			smoothexponent = wd.customParams.smoothexponent,
		}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local VALUE = 3
local NUMERATOR = (2 + math.exp(VALUE) + math.exp(-1*VALUE))/(math.exp(VALUE) - math.exp(-1*VALUE))
local OFFSET = NUMERATOR/(1 + math.exp(VALUE))
local function FalloffFunc(disSQ, smoothradiusSQ, smoothExponent)
	return NUMERATOR/(1 + math.exp(2*VALUE*(disSQ/smoothradiusSQ)^smoothExponent - VALUE)) - OFFSET
end

local function DoSmooth(def, x, y, z)
	local height = spGetGroundHeight(x,z)
	
	local smoothradius = def.smoothradius
	local gatherradius = def.gatherradius
	local detachmentradius = def.detachmentradius
	local maxSmooth = def.smooth
	local smoothheightoffset = def.smoothheightoffset
	
	if y > height + HEIGHT_FUDGE_FACTOR then
		local factor = 1 - ((y - height - HEIGHT_FUDGE_FACTOR)/smoothradius*HEIGHT_RAD_MULT)^2
		if factor > 0 then
			smoothradius = smoothradius*factor
			gatherradius = gatherradius*factor
			maxSmooth = maxSmooth*factor
		else
			return
		end
	end
	
	local smoothradiusSQ = smoothradius^2
	local gatherradiusSQ = gatherradius^2
	
	smoothradius = smoothradius + (8 - smoothradius%8)
	gatherradius = gatherradius + (8 - gatherradius%8)
	
	local sx = floor((x+4)/8)*8
	local sz = floor((z+4)/8)*8
	
	local groundPoints = 0
	local groundHeight = 0
	
	local increment = (def.quickgather and 16) or 8
	for i = sx - gatherradius, sx + gatherradius, increment do
		for j = sz - gatherradius, sz + gatherradius, increment do
			local disSQ = (i - x)^2 + (j - z)^2
			if disSQ <= gatherradiusSQ then
				groundPoints = groundPoints + 1
				groundHeight = groundHeight + spGetGroundHeight(i,j)
			end
		end
	end
	
	if groundPoints > 0 then
		groundHeight = groundHeight/groundPoints - (smoothheightoffset or 0)
		spSetHeightMapFunc(
			GG.Terraform.DoSmoothDirectly,
			x, z, sx, sz, smoothradius, origHeight, groundHeight,
			maxSmooth, smoothradiusSQ, FalloffFunc,
			def.smoothexponent, def.movestructures
		)
	end
	
	if detachmentradius then
		local GRAVITY = Game.gravity
		local units = Spring.GetUnitsInCylinder(sx,sz,detachmentradius)
		for i = 1, #units do
			local hitUnitID = units[i]
			GG.DetatchFromGround(hitUnitID, 1, 0.25, 0.002*GRAVITY)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DoUnitDestroyedTerraform(unitID, config)
	local  _,_,_,_,buildProgress = spGetUnitHealth(unitID)
	if buildProgress == 1 then
		local posX, posY, posZ = config.posX, config.posY, config.posZ

		local ux, uy, uz = spGetUnitPosition(unitID)
		ux = floor((ux+8)/16)*16
		uz = floor((uz+8)/16)*16
		
		local shrakaCliff = config.shrakaPyramidDiff
		
		local heightCache = {}
		local function Height(x, z)
			if heightCache[x] and heightCache[x][z] then
				return heightCache[x][z]
			end
			heightCache[x] = heightCache[x] or {}
			heightCache[x][z] = spGetGroundHeight(x, z)
			return heightCache[x][z]
		end
		
		spSetHeightMapFunc(
			function()
				local maxDiff, x, z, toAdd
				for i = 1, #posX, 1 do
					x, z = posX[i] + ux, posZ[i] + uz
					toAdd = posY[i]
					if shrakaCliff then
						if toAdd > 0 then
							maxDiff = Height(x, z) - min(Height(x - 8, z), Height(x + 8, z), Height(x, z - 8), Height(x, z + 8))
							maxDiff = shrakaCliff - maxDiff
							if toAdd > maxDiff then
								if maxDiff > 0 then
									toAdd = maxDiff
								else
									toAdd = false
								end
							end
						else
							maxDiff = max(Height(x - 8, z), Height(x + 8, z), Height(x, z - 8), Height(x, z + 8)) - Height(x, z)
							maxDiff = maxDiff - shrakaCliff
							if toAdd < maxDiff then
								if maxDiff < 0 then
									toAdd = maxDiff
								else
									toAdd = false
								end
							end
						end
					end
					if toAdd and GG.Terraform.IsPositionTerraformable(x, z) then
						spAddHeightMap(x, z, toAdd)
					end
				end
			end
		)
		
		local units = Spring.GetUnitsInCylinder(ux, uz, config.impulseRadius)
		for i = 1, #units do
			local hitUnitID = units[i]
			if hitUnitID ~= unitID then
				GG.AddGadgetImpulseRaw(hitUnitID, 0, config.impulseY, 0, true, true)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function DoFallShort(proID, def, proOwnerID)
	local vx, vy, vz, speed = Spring.GetProjectileVelocity(proID)
	local factor = math.sqrt(math.random())
	Spring.SetProjectileVelocity(proID, factor*vx, factor*vy, factor*vz)
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if not projectileDefs[weaponID] then
		return
	end
	if projectileDefs[weaponID].fallShort then
		DoFallShort(proID, projectileDefs[weaponID], proOwnerID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Explosion_GetWantedWeaponDef()
	return wantedList
end

function gadget:Explosion(weaponID, x, y, z, owner)
	if SeismicWeapon[weaponID] then
		local def = SeismicWeapon[weaponID]
		DoSmooth(def, x, y, z)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	local config = terraformOnUnitDestroyed[unitDefID]
	if config then
		DoUnitDestroyedTerraform(unitID, config)
	end
end

function gadget:Initialize()
	GG.Terraform.DoSmooth = DoSmooth
	for id, _ in pairs(projectileDefs) do
		Script.SetWatchProjectile(id, true)
	end
end
