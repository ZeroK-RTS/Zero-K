local ShieldSphereBase = {
	layer = -34,
	life = 10000,
	size = 350,
	radius = 350,
	colormap1 = {{0.1, 0.1, 1, 0.2}, {1, 0.1, 0.1, 0.2}},
	colormap2 = {{0.2, 0.2, 1, 0.0}, {1, 0.2, 0.2, 0.0}},
	repeatEffect = true,
	drawBack = 0.7,
}

local SEARCH_SMALL = {
	{0, 0},
	{1, 0},
	{-1, 0},
	{0, 1},
	{0, -1},
}

local SEARCH_MULT = 1.05
local SEARCH_BASE = 20
local DIAG = 1/math.sqrt(2)

local SEARCH_LARGE = {
	{0, 0},
	{1, 0},
	{-1, 0},
	{0, 1},
	{0, -1},
	{DIAG, DIAG},
	{-DIAG, DIAG},
	{DIAG, -DIAG},
	{-DIAG, -DIAG},
}
local searchSizes = {}

local shieldUnitDefs = {}
for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.customParams.shield_radius then
		local radius = tonumber(ud.customParams.shield_radius)

		if not searchSizes[radius] then
			local searchType = (radius > 250 and SEARCH_LARGE) or SEARCH_SMALL
			local search = {}
			for i = 1, #searchType do
				search[i] = {SEARCH_MULT*(radius + SEARCH_BASE)*searchType[i][1], SEARCH_MULT*(radius + SEARCH_BASE)*searchType[i][2]}
			end
			searchSizes[radius] = search
		end
		
		local myShield = Spring.Utilities.CopyTable(ShieldSphereBase)
		myShield.shieldSize = (radius > 250 and "large") or "small"
		myShield.drawBack = (radius > 250 and 0.5) or 0.9
		myShield.size = radius
		myShield.radius = radius
		myShield.pos = {0, tonumber(ud.customParams.shield_emit_height) or 0, 0}
		
		local strengthMult = tonumber(ud.customParams.shield_color_mult)
		if strengthMult then
			myShield.colormap1[1] = Spring.Utilities.CopyTable(ShieldSphereBase.colormap1[1])
			myShield.colormap1[1][4] = strengthMult*myShield.colormap1[1][4]
			myShield.colormap1[2] = Spring.Utilities.CopyTable(ShieldSphereBase.colormap1[1])
			myShield.colormap1[2][4] = strengthMult*myShield.colormap1[2][4]
			myShield.colormap2[1] = Spring.Utilities.CopyTable(ShieldSphereBase.colormap2[1])
			myShield.colormap2[1][4] = strengthMult*myShield.colormap2[1][4]
			myShield.colormap2[2] = Spring.Utilities.CopyTable(ShieldSphereBase.colormap2[1])
			myShield.colormap2[2][4] = strengthMult*myShield.colormap2[2][4]
		end
		
		shieldUnitDefs[unitDefID] = { 
			fx = {
				{class = 'ShieldSphereColor', options = myShield},
			},
			search = searchSizes[radius],
			shieldCapacity = tonumber(ud.customParams.shield_power),
		}
	end
end

return shieldUnitDefs
