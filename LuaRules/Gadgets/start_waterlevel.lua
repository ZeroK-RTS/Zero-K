if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Water level modoption",
	layer   = 1, -- after terraform whence GG.Terraform_RaiseWater comes
	enabled = true,
} end

local DRY_WATERLEVEL = -1000
local FLOODED_AREA = 0.5 -- (0; 1]

local FLOOD_OFFSET = -6 -- often the median of map height will be some large flat area. Setting waterlevel very close to any flat plane will result in major clipping ugliness (since bumpmapped water (the default) ebbs and flows) so it needs to be a few elmos off (but not too much so as not to skew the ratio). At -6 everything (both ships and ground) can path so it's a decent choice.

function gadget:Initialize()
	local waterlevel = Spring.GetModOptions().waterlevel or 0

	local preset = Spring.GetModOptions().waterpreset or "manual"
	if preset == "dry" then
		local lowest, highest = Spring.GetGroundExtremes ()
		waterlevel = math.min (0, lowest + DRY_WATERLEVEL)
	elseif preset == "flooded" then
		local heights = {}
		local heightsCount = 0

		local spGetGroundHeight = Spring.GetGroundHeight
		for i = 0, Game.mapSizeX-1, Game.squareSize do
			for j = 0, Game.mapSizeZ-1, Game.squareSize do
				heightsCount = heightsCount + 1
				heights [heightsCount] = spGetGroundHeight (i, j)
			end
		end

		table.sort (heights)
		waterlevel = heights [math.ceil (heightsCount * FLOODED_AREA)] - FLOOD_OFFSET
	end

	if waterlevel ~= 0 then
		GG.Terraform_RaiseWater(waterlevel)
	end
end
