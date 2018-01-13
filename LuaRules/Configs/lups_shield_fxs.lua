local ShieldSphereBase = {
	layer = -34,
	life = 10000,
	size = 350,
	uvMul = 1,
	opacExp = 0.8,
	radius = 350,
	colormap1 = {{0.1, 0.1, 1, 0.4}, {1, 0.1, 0.1, 0.4}},
	colormap2 = {{0.2, 1, 0.7, 0.0}, {0.7, 1, 0.2, 0.0}},
	repeatEffect = true,
	drawBack = 0.7,
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
			myShield.drawBack = 0.55
			myShield.drawBackCol = 0.3
			myShield.drawBackMargin = 4.5
			myShield.margin = 4
			myShield.hitResposeMult = 0.6
			myShield.colormap1[1][4] = 0.22
			myShield.colormap1[2][4] = 0.22
		else
			myShield.shieldSize = "small"
			if radius > 100 then
				myShield.opacExp = 1.5
				myShield.uvMul = 0.75
				myShield.shieldSize = "medium"
			else
				myShield.opacExp = 2.0
				myShield.uvMul = 0.5
				myShield.shieldSize = "small"
			end
			myShield.drawBack = 0.75
			myShield.drawBackCol = 0.4
			myShield.drawBackMargin = 1.8
			myShield.margin = 1.8
			myShield.colormap1[1][4] = 0.22
			myShield.colormap1[2][4] = 0.22
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
		
		local fxTable = {
			{class = 'ShieldSphereColor', options = myShield},
		}
		
		if string.find(ud.name, "chicken_") then
			myShield.colormap1 = {{0.3, 0.9, 0.2, 1.2}, {0.6, 0.4, 0.1, 1.2}} -- Note that alpha is multiplied by 0.26
			myShield.hitResposeMult = 0
			myShield.texture = "bitmaps/GPL/bubbleShield.png"
			fxTable[1].class = "ShieldSphereColorFallback"
		end
		
		shieldUnitDefs[unitDefID] = { 
			fx = fxTable,
			search = searchSizes[radius],
			shieldCapacity = tonumber(ud.customParams.shield_power),
		}
	end
end

return shieldUnitDefs
