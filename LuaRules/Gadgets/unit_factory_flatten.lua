if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name    = "Factory exit flatten",
		author  = "GoogleFrog (effectively)",
		date    = "2017-10-01",
		license = "GNU GPL, v2 or later",
		layer   = 1, -- after mission_galaxy_campaign_battle_handler (it levels ground for facs and would overwrite ours)
		enabled = true,
	}
end

include("LuaRules/Configs/start_setup.lua")

local function FlattenFunc(left, top, right, bottom, height)
	-- top and bottom
	for x = left, right, 8 do
		Spring.SetHeightMap(x, top - 8, height, 0.5)
		Spring.SetHeightMap(x, bottom + 8, height, 0.5)
	end

	-- left and right
	for z = top, bottom, 8 do
		Spring.SetHeightMap(left - 8, z, height, 0.5)
		Spring.SetHeightMap(right + 8, z, height, 0.5)
	end

	-- corners
	Spring.SetHeightMap(left - 8, top - 8, height, 0.5)
	Spring.SetHeightMap(left - 8, bottom + 8, height, 0.5)
	Spring.SetHeightMap(right + 8, top - 8, height, 0.5)
	Spring.SetHeightMap(right + 8, bottom + 8, height, 0.5)
end

local function FlattenRectangle(left, top, right, bottom, height)
	Spring.LevelHeightMap(left, top, right, bottom, height)
	Spring.SetHeightMapFunc(FlattenFunc, left, top, right, bottom, height)
end

function FlattenFactory(unitID, unitDefID)
	local ud = UnitDefs[unitDefID]
	local sX = ud.xsize*4
	local sZ = ud.zsize*4
	local facing = Spring.GetUnitBuildFacing(unitID)
	if facing == 1 or facing == 3 then
		sX, sZ = sZ, sX
	end

	local x,y,z = Spring.GetUnitPosition(unitID)
	local height
	if facing == 0 then -- South
		height = Spring.GetGroundHeight(x, z + 0.8*sZ)
	elseif facing == 1 then -- East
		height = Spring.GetGroundHeight(x + 0.8*sX, z)
	elseif facing == 2 then -- North
		height = Spring.GetGroundHeight(x, z - 0.8*sZ)
	else -- West
		height = Spring.GetGroundHeight(x - 0.8*sX, z)
	end

	if height > 0 or (not ud.floatOnWater) then
		FlattenRectangle(x - sX, z - sZ, x + sX, z + sZ, height)
		if GG.Terraform then
			GG.Terraform.SetStructureHeight(unitID, height)
		end
	end
end

local function UnitFinished(_, unitID, unitDefID)
	if not (unitID and unitDefID and ploppableDefs[unitDefID]) then
		return
	end

	FlattenFactory(unitID, unitDefID)
end

-- stuff below only relevant before game start: terraform los hax prevention for mission units spawned pregame

local pregame_facs = {}
function gadget:UnitFinished(unitID, unitDefID)
	if not ploppableDefs[unitDefID] then
		return
	end

	pregame_facs[unitID] = unitDefID
end

function gadget:GameFrame(n)
	for unitID, unitDefID in pairs (pregame_facs) do
		FlattenFactory (unitID, unitDefID)
	end
	pregame_facs = nil

	gadget.UnitFinished = UnitFinished
	gadgetHandler:UpdateCallIn("UnitFinished")
	gadgetHandler:RemoveCallIn("GameFrame")
end
