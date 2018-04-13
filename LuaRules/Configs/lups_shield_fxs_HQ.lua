local ShieldSphereBase = {
	layer = -34,
	life = 10000,
	size = 350,
	radius = 350,
	colormap1 = {{0.1, 0.1, 1, 0.22}, {1, 0.1, 0.1, 0.22}},
	colormap2 = {{0.2, 1, 0.7, 0.0}, {0.7, 1, 0.2, 0.0}},
	mix = {0.0, 0.0, 0.0, 0.25},
	repeatEffect = true,
	drawBack = {1.0, 1.0, 1.0, 0.45},
	onActive = true,	
}

local SEARCH_SMALL = {
	{0, 0},
	{1, 0},
	{-1, 0},
	{0, 1},
	{0, -1},
}

local SEARCH_MULT = 1
local SEARCH_BASE = 16
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

		local myShield = Spring.Utilities.CopyTable(ShieldSphereBase, true)
		if radius > 250 then
			myShield.shieldSize = "large"
			myShield.drawBackMargin = 4.5
			myShield.sizeDrift = 0.003;
			myShield.margin = 8
			myShield.uvMul = 1.0
			myShield.hitResposeMult = 0.6			
		else
			if radius > 100 then
				myShield.sizeDrift = 0.004;
				myShield.margin = 6.5
				myShield.uvMul = 0.6
				myShield.shieldSize = "medium"
			else
				myShield.sizeDrift = 0.006;
				myShield.margin = 5.5
				myShield.uvMul = 0.4
				myShield.shieldSize = "small"
			end			
			myShield.drawBackMargin = 1.8
			myShield.hitResposeMult = 1
		end
		myShield.size = radius
		myShield.radius = radius
		myShield.pos = {0, tonumber(ud.customParams.shield_emit_height) or 0, tonumber(ud.customParams.shield_emit_offset) or 0}

		local strengthMult = tonumber(ud.customParams.shield_color_mult)
		if strengthMult then
			myShield.colormap1[1][4] = strengthMult*myShield.colormap1[1][4]
			myShield.colormap1[2][4] = strengthMult*myShield.colormap1[2][4]
		end

		if string.find(ud.name, "chicken_") then
			myShield.sizeDrift = 0.005;
			myShield.colormap1 = {{0.3, 0.9, 0.2, 0.6}, {0.6, 0.4, 0.1, 0.6}}
			--myShield.mix = {0.5, 0.5, 0.5, 0.9}			
			myShield.mix = {0.5, 0.5, 0.5, 0.7}
			myShield.uvMul = 1.0
			myShield.hitResposeMult = 0
			myShield.drawBack = {1.0, 1.0, 1.0, 0.1} --more alpha makes visual polar artifacts
			myShield.texture = "bitmaps/PD/shield.png"
		end

		local fxTable = {
			{class = 'ShieldSphereColorHQ', options = myShield},
		}

		shieldUnitDefs[unitDefID] = {
			fx = fxTable,
			search = searchSizes[radius],
			shieldCapacity = tonumber(ud.customParams.shield_power),
			shieldRadius = radius,
		}
	end
end

return shieldUnitDefs
