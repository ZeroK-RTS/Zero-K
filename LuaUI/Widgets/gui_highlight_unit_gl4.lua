 function widget:GetInfo()
	return {
		name = "Highlight Unit GL4 v2",
		desc = "Highlights the unit or feature under the cursor",
		author = "Floris (original: trepan)",
		date = "January 2022",
		license = "GNU GPL, v2 or later",
		layer = 5,
		enabled = true
	}
end

local hideBelowGameframe = 5
local edgeAlpha = 0.4
local edgeExponent = 1.2

local HIGHLIGHT_KEY = "mouseover"

local useTeamcolor = false
local teamColorAlphaMult = 1.25
local teamColorMinAlpha = 0.7
local fadeTime = 0.05

local myUnitColor    = {1, 1, 1}
local allyUnitColor  = {1, 1, 1}
local enemyUnitColor = {1, 1, 1}

local vsx, vsy = Spring.GetViewGeometry()

local hidden = (Spring.GetGameFrame() <= hideBelowGameframe)
local selectedUnits = Spring.GetSelectedUnits()
local unitIsSelected = false

local spGetMouseState = Spring.GetMouseState
local spTraceScreenRay = Spring.TraceScreenRay
local spGetUnitTeam = Spring.GetUnitTeam

local unitshapes = {}
local cusHighlights = {}
local fadeUnits = {}

local function UpdateTeamColors()
	local saturation = (options and options.highlightSat.value) or 0.5
	allyUnitColor = (WG.LocalColor or {}).allyColor or {1, 1, 1}
	if options and options.selfHoverSameAsAllies.value then
		myUnitColor = allyUnitColor
	else
		myUnitColor = (WG.LocalColor or {}).myColor or {1, 1, 1}
	end
	enemyUnitColor = (WG.LocalColor or {}).enemyColor or {1, 1, 1}
	allyUnitColor = {
		allyUnitColor[1]*saturation + (1 - saturation),
		allyUnitColor[2]*saturation + (1 - saturation),
		allyUnitColor[3]*saturation + (1 - saturation),
	}
	myUnitColor = {
		myUnitColor[1]*saturation + (1 - saturation),
		myUnitColor[2]*saturation + (1 - saturation),
		myUnitColor[3]*saturation + (1 - saturation),
	}
	enemyUnitColor = {
		enemyUnitColor[1]*saturation + (1 - saturation),
		enemyUnitColor[2]*saturation + (1 - saturation),
		enemyUnitColor[3]*saturation + (1 - saturation),
	}
	Spring.Echo("allyUnitColor", allyUnitColor[1], allyUnitColor[2], allyUnitColor[3])
	Spring.Echo("myUnitColor", myUnitColor[1], myUnitColor[2], myUnitColor[3])
	Spring.Echo("enemyUnitColor", enemyUnitColor[1], enemyUnitColor[2], enemyUnitColor[3])
end

options_path = 'Settings/Graphics/Unit Visibility'
options_order = { 'highlightStrength', 'highlightSat', 'selfHoverSameAsAllies'}
options = {
	highlightStrength = {
		name = "Mouse hover highlight strength",
		type = "number",
		value = 0.35,
		min = 0,
		max = 1,
		step = 0.01,
	},
	highlightSat = {
		name = "Mouse hover highlight saturation",
		type = "number",
		value = 0.5,
		min = 0,
		max = 1,
		step = 0.01,
		OnChange = UpdateTeamColors
	},
	selfHoverSameAsAllies = {
		name = 'Use ally hover cover for self',
		type = 'bool',
		value = false,
		OnChange = UpdateTeamColors
	},
}

local function IsMyUnit(unitID)
	local spectating = Spring.GetSpectatingState()
	return (not spectating) and (Spring.GetUnitTeam(unitID) == Spring.GetMyTeamID())
end

local function IsAllyUnit(unitID)
	return (Spring.GetUnitAllyTeam(unitID) == Spring.GetMyAllyTeamID())
end

local function GetHighlightColorForUnit(unitID)
	if IsMyUnit(unitID) then
		return myUnitColor[1], myUnitColor[2], myUnitColor[3]
	end
	if IsAllyUnit(unitID) then
		return allyUnitColor[1], allyUnitColor[2], allyUnitColor[3]
	end
	return enemyUnitColor[1], enemyUnitColor[2], enemyUnitColor[3]
end

local function AddUnitHighlight(unitID)
	if not Spring.ValidUnitID(unitID) then
		widget:Shutdown()
		return
	end
	local r, g, b = GetHighlightColorForUnit(unitID)
	local mult = 1
	if not (unitshapes[unitID] or cusHighlights[unitID]) then
		fadeUnits[unitID] = os.clock()
		mult = 0.13
	elseif fadeUnits[unitID] then
		if fadeUnits[unitID] > 0 then
			mult = 0.05 + (os.clock() - fadeUnits[unitID]) / fadeTime + ((1/Spring.GetFPS())/fadeTime)
			if mult >= 1 then
				mult = 1
				fadeUnits[unitID] = nil
			end
		else
			mult = 1 - ((os.clock() - math.abs(fadeUnits[unitID])) / fadeTime)
			if mult <= 0 then
				fadeUnits[unitID] = nil
			end
		end
	end
	if unitshapes[unitID] then
		WG.StopHighlightUnitGL4(unitshapes[unitID])
		unitshapes[unitID] = nil
	end
	if mult <= 0 then
		if WG.HighlightUnitCus then
			cusHighlights[unitID] = nil
			WG.HighlightUnitCus(unitID, HIGHLIGHT_KEY, 0)
		end
		return
	end
	if WG.HighlightUnitCus then
		cusHighlights[unitID] = true
		WG.HighlightUnitCus(unitID, HIGHLIGHT_KEY, math.min(1 + options.highlightStrength.value*mult, 1.99999))
	end
	if WG.HighlightUnitGL4 then
		unitshapes[unitID] = WG.HighlightUnitGL4(unitID, 'unitID', r,g,b, 0, options.highlightStrength.value*mult, edgeExponent, 0)
		return unitshapes[unitID]
	end
end

local function RemoveUnitShape(unitID, force)
	if unitID and (unitshapes[unitID] or cusHighlights[unitID]) then
		if force then
			if WG.StopHighlightUnitGL4 then
				WG.StopHighlightUnitGL4(unitshapes[unitID])
				unitshapes[unitID] = nil
			end
			if WG.HighlightUnitCus then
				WG.HighlightUnitCus(unitID, HIGHLIGHT_KEY, 0)
				cusHighlights[unitID] = nil
			end
			fadeUnits[unitID] = nil
		elseif not fadeUnits[unitID] then
			fadeUnits[unitID] = -os.clock()
		elseif fadeUnits[unitID] and fadeUnits[unitID] > 0 then
			local mult = 1 - ((os.clock() - math.abs(fadeUnits[unitID])) / fadeTime)
			fadeUnits[unitID] = -(os.clock() - (fadeTime * mult))
		end
	end
end

local function ClearHighlights(keepUnitID, force)
	for unitID, _ in pairs(unitshapes) do
		if not keepUnitID or unitID ~= keepUnitID then
			RemoveUnitShape(unitID, force)
		end
	end
	for unitID, _ in pairs(cusHighlights) do
		if not keepUnitID or unitID ~= keepUnitID then
			RemoveUnitShape(unitID, force)
		end
	end
end

function widget:UnitDestroyed(unitID)
	if (unitshapes[unitID] or cusHighlights[unitID]) then
		RemoveUnitShape(unitID, true)
	end
end

function widget:ViewResize()
	vsx, vsy = Spring.GetViewGeometry()
end

local function ShouldHighlight()
	if Spring.IsGUIHidden() then
		return false
	end
	local screen0 = WG.Chili and WG.Chili.Screen0
	if screen0 and screen0.activeControl then
		return false
	end
	if screen0 and screen0.hoveredControl then
		return false
	end
	return true
end

function widget:Update()
	if hidden and Spring.GetGameFrame() > hideBelowGameframe then
		hidden = false
	end
	local mx, my, lmb, mmb, rmb, outsideSpring = spGetMouseState()
	if outsideSpring or options.highlightStrength.value == 0 then
		ClearHighlights(nil, true)
	else
		local targetType, data = spTraceScreenRay(mx, my)
		local unitID
		local addedUnitID
		if targetType == 'unit' and ShouldHighlight() then
			unitID = data
			if not (unitshapes[unitID] or cusHighlights[unitID]) then
				AddUnitHighlight(unitID)
				addedUnitID = unitID
			end
		end
		ClearHighlights(unitID)

		for unitID, v in pairs(fadeUnits) do
			if unitID ~= addedUnitID then
				AddUnitHighlight(unitID)
			end
		end
	end
end

function widget:Initialize()
	if not (WG.HighlightUnitGL4 or WG.HighlightUnitCus) then
		widgetHandler:RemoveWidget()
		return
	end
	WG.LocalColor.RegisterListener("HighlightUnitGl4", UpdateTeamColors)
	UpdateTeamColors()
	if WG.SetHighlightPriority then
		WG.SetHighlightPriority(HIGHLIGHT_KEY, 5)
	end
end

function widget:Shutdown()
	ClearHighlights(false, true)
	WG.LocalColor.UnregisterListener("HighlightUnitGl4")
end
