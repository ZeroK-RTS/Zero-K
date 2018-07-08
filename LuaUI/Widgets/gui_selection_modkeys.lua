function widget:GetInfo()
	return {
		name      = "Selection Modkeys",
		desc      = "Implement reimplementation of selection modkeys.",
		author    = "GoogleFrog",
		date      = "24 January 2018",
		license   = "GNU GPL, v2 or later",
		layer     = -32,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local spSelectUnitArray = Spring.SelectUnitArray
local spDiffTimers      = Spring.DiffTimers
local spGetTimer        = Spring.GetTimer

local toleranceTime = Spring.GetConfigInt('DoubleClickTime', 300) * 0.001 -- no event to notify us if this changes but not really a big deal
toleranceTime = toleranceTime + 0.03 -- fudge for Update

local LEFT_CLICK = 1
local RIGHT_CLICK = 3
local TRACE_UNIT = "unit"

local CLICK_LEEWAY = 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Interface/Selection'
options_order = {'enable',}
options = {
	enable = {
		name = "New left click selection modifiers",
		type = "bool",
		value = true,
		noHotkey = true,
		desc = "Implements new modifiers for left clicking on units.",
	},
}

local clickX, clickY = false, false
local clickUnitID = false
local clickSelected = false
local prevTargetID = false
local mousePressed = false

local prevClick = spGetTimer()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Reset()
	clickX = false
	clickY = false
	clickUnitID = false
	clickSelected = false
	mousePressed = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DeselectUnits(selectedUnits, unitList)
	local newSelectedUnits = {}
	
	local unitMap = {}
	for i = 1, #unitList do
		unitMap[unitList[i]] = true
	end
	
	for i = 1, #selectedUnits do
		if not unitMap[selectedUnits[i]] then
			newSelectedUnits[#newSelectedUnits + 1] = selectedUnits[i]
		end
	end
	spSelectUnitArray(newSelectedUnits)
end

local function SelectUnits(selectedUnits, unitList)
	local newSelectedUnits = unitList
	local selectedUnitMap = {}
	for i = 1, #newSelectedUnits do
		selectedUnitMap[unitList[i]] = true
	end
	
	for i = 1, #selectedUnits do
		local unitID = selectedUnits[i]
		if not selectedUnitMap[unitID] then
			newSelectedUnits[#newSelectedUnits + 1] = unitID
		end
	end
	
	return newSelectedUnits
end

local function HandleUnitSelection(selectedUnits, targetID, needSelection)
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	
	local unitDefID = Spring.GetUnitDefID(targetID)
	if unitDefID and ctrl then
		local typeUnits = Spring.GetTeamUnitsByDefs(Spring.GetMyTeamID(), unitDefID)
		local unitList = {}
		for i = 1, #typeUnits do
			local unitID = typeUnits[i]
			if Spring.IsUnitVisible(unitID) then
				unitList[#unitList + 1] = unitID
			end
		end
		
		if clickSelected and shift then
			return DeselectUnits(selectedUnits, unitList)
		else
			if shift then
				return SelectUnits(selectedUnits, unitList)
			else
				return unitList
			end
		end
	elseif shift then
		if clickSelected then
			return DeselectUnits(selectedUnits, {targetID})
		elseif needSelection then
			return SelectUnits(selectedUnits, {targetID})
		end
	elseif needSelection then
		return SelectUnits(selectedUnits, {targetID})
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MousePress(x, y)
	Reset()
	
	if not options.enable.value then
		return
	end
	
	local _, activeCmdID = Spring.GetActiveCommand()
	if activeCmdID then
		return
	end
	
	local targetID = WG.PreSelection_GetUnitUnderCursor(true)
	if not targetID then
		return
	end
	
	if targetID == prevTargetID then
		local now = spGetTimer()
		local doubleClickTime = (spDiffTimers(now, prevClick) <= toleranceTime)
		prevClick = now
		if doubleClickTime then
			Reset()
			return
		end
	end
	
	clickX = x
	clickY = y
	clickUnitID = targetID
	clickSelected = Spring.IsUnitSelected(targetID)
	
	prevClick = spGetTimer()
end

local function MouseRelease(x, y)
	if not options.enable.value then
		return
	end
	
	if not (clickX and clickY and clickUnitID) or (math.abs(clickX - x) > CLICK_LEEWAY) or (math.abs(clickY - y) > CLICK_LEEWAY) then
		Reset()
		return
	end
	
	local targetID = WG.PreSelection_GetUnitUnderCursor(true)
	local needSelection = false
	if (not targetID) then
		needSelection = true
		targetID = clickUnitID
	end
	
	prevTargetID = targetID
	local newSel = HandleUnitSelection(Spring.GetSelectedUnits(), targetID, needSelection)
	if newSel then
		spSelectUnitArray(newSel)
	end
	Reset()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:SelectionChanged(selectedUnits)
	if not (mousePressed and options.enable.value) then
		return
	end
	local x, y = Spring.GetMouseState()
	
	if not (clickX and clickY and clickUnitID) or (math.abs(clickX - x) > CLICK_LEEWAY) or (math.abs(clickY - y) > CLICK_LEEWAY) then
		Reset()
		return
	end
	
	local targetID = WG.PreSelection_GetUnitUnderCursor(true)
	local needSelection = true
	if (not targetID) then
		needSelection = true
		targetID = clickUnitID
	end
	
	prevTargetID = targetID
	local newSel = HandleUnitSelection(selectedUnits, targetID, needSelection)
	Reset()
	return newSel
end

function widget:Update()
	local x, y, left, middle, right, offscreen = Spring.GetMouseState()
	if left and not mousePressed then
		MousePress(x, y)
		mousePressed = true
	end
	if not left and mousePressed then
		MouseRelease(x, y)
		mousePressed = false
	end
end
