local ShieldSphereBase = {
	layer = -34,
	life = 10000,
	size = 350,
	radius = 350,
	colormap1 = {{0.1, 0.1, 1, 0.4}, {1, 0.1, 0.1, 0.4}},
	colormap2 = {{0.2, 0.9, 1, 0.0}, {1, 0.9, 0.2, 0.0}},
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
	
	if ud.customParams.shield_radius or ud.customParams.dyn_shield_radius then
		local radius = tonumber(ud.customParams.shield_radius or ud.customParams.dyn_shield_radius)
		Spring.Echo(ud.name, radius)
		if not searchSizes[radius] then
			local searchType = (radius > 250 and SEARCH_LARGE) or SEARCH_SMALL
			local search = {}
			for i = 1, #searchType do
				search[i] = {SEARCH_MULT*(radius + SEARCH_BASE)*searchType[i][1], SEARCH_MULT*(radius + SEARCH_BASE)*searchType[i][2]}
			end
			searchSizes[radius] = search
		end
		
		local myShield = Spring.Utilities.CopyTable(ShieldSphereBase, true)
		if radius > 250 then
			myShield.shieldSize = "large"
			myShield.drawBack = 0.6
			myShield.drawBackMargin = 3
			myShield.margin = 1.35
			myShield.hitResposeMult = 0.6
			myShield.colormap1[1][4] = 0.22
			myShield.colormap1[2][4] = 0.22
		else
			myShield.shieldSize = "small"
			myShield.drawBack = 0.9
			myShield.drawBackMargin = 1.9
			myShield.margin = 1.2
			myShield.colormap1[1][4] = 0.22
			myShield.colormap1[2][4] = 0.22
			myShield.hitResposeMult = 1
		end
		myShield.size = radius
		myShield.radius = radius
		myShield.pos = {0, tonumber(ud.customParams.shield_emit_height) or 0, 0}
		
		local strengthMult = tonumber(ud.customParams.shield_color_mult)
		if strengthMult then
			myShield.colormap1[1][4] = strengthMult*myShield.colormap1[1][4]
			myShield.colormap1[2][4] = strengthMult*myShield.colormap1[2][4]
		end
		
		shieldUnitDefs[unitDefID] = { 
			fx = {
				{class = 'ShieldSphereColor', options = myShield},
			},
			search = searchSizes[radius],
			shieldCapacity = tonumber(ud.customParams.shield_power or ud.customParams.dyn_shield_power),
		}
	end
end

return shieldUnitDefs
