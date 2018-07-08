--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Grass Cutter",
		desc      = "Cuts grass.",
		author    = "GoogleFrog",
		date      = "12 November 2017",
		license   = "Public Domain",
		layer     = 0,
		enabled   = false
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, teamID)
	local ud = UnitDefs[unitDefID]
	
	if not ud.isImmobile or ud.customParams.mobilebuilding then
		return
	end
	
	local ux, _, uz = Spring.GetUnitPosition(unitID)
	if not ux then
		return
	end
	
	local face = Spring.GetUnitBuildFacing(unitID)
	local xsize = ud.xsize*4
	local zsize = ud.zsize*4
	
	if face%2 == 1 then
		xsize, zsize = zsize, xsize
	end
	
	local minx = ux - xsize
	local minz = uz - zsize
	local maxx = ux + xsize
	local maxz = uz + zsize
	
	for x = minx, maxx, 16 do
		for z = minz, maxz, 16 do
			Spring.RemoveGrass(x, z)
		end
	end
end
