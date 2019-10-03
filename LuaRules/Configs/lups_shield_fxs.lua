local ShieldSphereBase = {
	layer = -34,
	life = 10000,
	size = 350,
	radius = 350,
	colormap1 = {{0.1, 0.1, 1, 0.22}, {1, 0.1, 0.1, 0.22}},
	colormap2 = {{0.2, 1, 0.7, 0.0}, {0.7, 1, 0.2, 0.0}},
--	drawBack = 0.7,
	mix = {0.0, 0.0, 0.0, 0.25},
	drawBackHQ = {1.0, 1.0, 1.0, 0.45},
	repeatEffect = true,
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

		----==== myShield ====----

		local myShield = Spring.Utilities.CopyTable(ShieldSphereBase, true)
		if radius > 250 then
			if radius > 400 then
				myShield.shieldSize = "huge"
				--==  HQ  ==--
				myShield.sizeDrift = 0.0;
				myShield.marginHQ = 2.8
				myShield.uvMul = 1.0
				--== /HQ  ==--
				myShield.hitResposeMult = 0.5
			else
				myShield.shieldSize = "large"
				--==  HQ  ==--
				myShield.sizeDrift = 0.008;
				myShield.marginHQ = 2.8
				myShield.uvMul = 1.0
				--== /HQ  ==--
				myShield.hitResposeMult = 0.6
			end
			myShield.drawBack = 0.55
			myShield.drawBackCol = 0.3
			myShield.drawBackMargin = 4.5
			myShield.margin = 4
		else
			myShield.shieldSize = "small"
			if radius > 100 then
				myShield.shieldSize = "medium"
				--==  HQ  ==--
				myShield.sizeDrift = 0.01;
				myShield.marginHQ = 3.5
				myShield.uvMul = 0.55
				--== /HQ  ==--
			else
				myShield.shieldSize = "small"
				--==  HQ  ==--
				myShield.sizeDrift = 0.014;
				myShield.marginHQ = 3
				myShield.uvMul = 0.3
				--== /HQ  ==--
			end
			myShield.drawBack = 0.75
			myShield.drawBackCol = 0.4
			myShield.drawBackMargin = 1.8
			myShield.margin = 1.8
			myShield.hitResposeMult = 1
		end
		myShield.rechargeDelay = tonumber(ud.customParams.shield_recharge_delay) or 0

		myShield.size = radius
		myShield.radius = radius
		myShield.pos = {0, tonumber(ud.customParams.shield_emit_height) or 0, tonumber(ud.customParams.shield_emit_offset) or 0}

		local strengthMult = tonumber(ud.customParams.shield_color_mult)
		if strengthMult then
			myShield.colormap1[1][4] = strengthMult*myShield.colormap1[1][4]
			myShield.colormap1[2][4] = strengthMult*myShield.colormap1[2][4]
		end
		
		-- Very powerful non-chicken shields get a different look
		local shieldPower = tonumber(ud.customParams.shield_power)
		local decayFactor = 0.1
		if shieldPower > 10000 then
			myShield.texture = "bitmaps/PD/shieldblank.png"
			myShield.colormap1 = {{0.4, 0.4, 1.3, 0.8}, {0.5, 0.1, 0.1, 0.3}}
			myShield.colormap2 = {{0.0, 0.2, 0.2, 0.03}, {0.0, 0.2, 0.0, 0.02}}
			myShield.hitResposeMult = 0.15
			myShield.faintShield = true
			decayFactor = 0.1
		else
			myShield.faintShield = false
		end

		local isChicken = false
		if string.find(ud.name, "chicken_") then
			isChicken = true
			myShield.colormap1 = {{0.3, 0.9, 0.2, 0.6}, {0.6, 0.4, 0.1, 0.6}}
			myShield.hitResposeMult = 0.5
			--myShield.texture = "bitmaps/GPL/bubbleShield.png"
			myShield.texture = "bitmaps/PD/shield.png"
			--==  HQ  ==--
			myShield.sizeDrift = 0.03;
			myShield.drawBackHQ = {1.0, 1.0, 1.0, 0.1} --more alpha makes visual polar artifacts
			--myShield.mix = {0.5, 0.5, 0.5, 0.9}
			myShield.mix = {0.5, 0.5, 0.5, 0.7}
			myShield.uvMul = 1.0
			--== /HQ  ==--
		end

		local mainClass
		if (GG.Lups.Config.quality or 2) >= 3 then
			mainClass = "ShieldSphereColorHQ"
		else
			if isChicken then
				myShield.colormap1 = {{0.3, 0.9, 0.2, 1.5}, {0.6, 0.4, 0.1, 1.5}} -- Note that alpha is multiplied by 0.26
				myShield.texture = "bitmaps/GPL/bubbleShield.png"
				mainClass = "ShieldSphereColorFallback"
			else
				mainClass = "ShieldSphereColor"
			end
		end

		local fxTable = {
			{class = mainClass, options = myShield},
		}

		shieldUnitDefs[unitDefID] = {
			fx = fxTable,
			search = searchSizes[radius],
			shieldCapacity = tonumber(ud.customParams.shield_power),
			damageMultShieldCapacity = tonumber(ud.customParams.shield_power_gfx_override or ud.customParams.shield_power),
			decayFactor = decayFactor,
			shieldPos = myShield.pos,
			shieldRadius = radius,
		}
	end
end

return shieldUnitDefs
