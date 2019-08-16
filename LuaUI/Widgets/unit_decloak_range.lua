function widget:GetInfo()
	return {
		name      = "Decloak Range",
		desc      = "Display decloak range around cloaked units. v2",
		author    = "banana_Ai, dahn, GoogleFrog (rewrite), ashdnazg (effectively)",
		date      = "15 Jul 2016",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true,
	}
end

VFS.Include("LuaRules/Utilities/glVolumes.lua")

local Chili

local spGetSelectedUnits   = Spring.GetSelectedUnits
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitPosition    = Spring.GetUnitPosition
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local glColor              = gl.Color

local drawAlpha = 0.17
local disabledColor = { 0.9,0.5,0.3, drawAlpha}
local cloakedColor = { 0.4, 0.4, 0.9, drawAlpha} -- drawAlpha on purpose!

options_path = 'Settings/Interface/Defense and Cloak Ranges'
options_order = {
	"label",
	"drawranges",
	"mergeCircles",
}

options = {
	label = { type = 'label', name = 'Decloak Ranges' },
	drawranges = {
		name = 'Draw decloak ranges',
		type = 'bool',
		value = true,
		OnChange = function (self)
			if self.value then
				widgetHandler:UpdateCallIn("DrawWorldPreUnit")
			else
				widgetHandler:RemoveCallIn("DrawWorldPreUnit")
			end
		end
	},
	mergeCircles = {
		name = "Draw merged cloak circles",
		desc = "Merge overlapping grid circle visualisation. Does not work on older hardware and should automatically disable.",
		type = 'bool',
		value = true,
	},
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Drawing

local function DrawMergedDecloakRanges(drawActive, drawDisabled)
	-- From showeco action.
	local drawGroundCircle = options.mergeCircles.value and gl.Utilities.DrawMergedGroundCircle or gl.Utilities.DrawGroundCircle

	local selUnits = spGetSelectedUnits()
	for i = 1, #selUnits do
		local unitID = selUnits[i]
		local unitDefID = spGetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		local cloaked = Spring.GetUnitIsCloaked(unitID)
		local wantCloak = (not cloaked) and ((spGetUnitRulesParam(unitID, "wantcloak") == 1) or (spGetUnitRulesParam(unitID, "areacloaked") == 1))
		if (cloaked and drawActive) or (wantCloak and drawDisabled) then
			local radius = ud.decloakDistance
			
			local commCloaked = spGetUnitRulesParam(unitID, "comm_decloak_distance")
			if commCloaked and (commCloaked > 0) then
				radius = commCloaked
			end
			
			local areaCloaked = spGetUnitRulesParam(unitID, "areacloaked_radius")
			if areaCloaked and (areaCloaked > 0) then
				radius = areaCloaked
			end
			
			if radius then
				glColor((wantCloak and disabledColor) or cloakedColor)
				local x, y, z = spGetUnitPosition(unitID)
				drawGroundCircle(x, z, radius)
			end
		end
	end
	-- Keep clean for everyone after us
	gl.Clear(GL.STENCIL_BUFFER_BIT, 0)
end

local function HighlightPylons()
	if options.mergeCircles.value then
		DrawMergedDecloakRanges(false, true)
		DrawMergedDecloakRanges(true, false)
	else
		DrawMergedDecloakRanges(true, true)
	end
end

function widget:DrawWorldPreUnit()
	if Spring.IsGUIHidden() then
		return
	end

	HighlightPylons()
	glColor(1,1,1,1)
end
