
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
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local terraformOnUnitDestroyed = VFS.Include("LuaRules/Configs/unit_terraform_defs.lua", nil, VFS.GAME)

local floor                 = math.floor
local max                   = math.max
local min                   = math.min

local spGetUnitPosition     = Spring.GetUnitPosition
local spGetGroundHeight     = Spring.GetGroundHeight
local spSetHeightMapFunc    = Spring.SetHeightMapFunc
local spAddHeightMap        = Spring.AddHeightMap
local spGetUnitHealth       = Spring.GetUnitHealth

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

function gadget:UnitDestroyed(unitID, unitDefID)
	local config = terraformOnUnitDestroyed[unitDefID]
	if config then
		DoUnitDestroyedTerraform(unitID, config)
	end
end
