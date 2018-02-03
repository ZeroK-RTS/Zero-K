if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Water level modoption",
	layer   = 1, -- after terraform whence GG.Terraform_RaiseWater comes
	enabled = true,
} end

local DRY_WATERLEVEL = -50
local FLOODED_AREA = 0.5 -- (0; 1]

local FLOOD_OFFSET = -72 -- often the median of map height will be some large flat area. Setting waterlevel very close to any flat plane will result in major clipping ugliness. This ofset is intended to make most of the map covered by a decent depth of sea.

function gadget:Initialize() -- GamePreload causes issues with widgets.
	if Spring.GetGameFrame () > 1 then
		return
	end

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

	Spring.SetGameRulesParam("waterlevel", waterlevel)
	if waterlevel ~= 0 then
		GG.Terraform_RaiseWater(waterlevel)
	end
end
