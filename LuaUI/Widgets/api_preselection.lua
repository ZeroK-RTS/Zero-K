function widget:GetInfo()
	return {
		name      = "Pre-Selection Handler",
		desc      = "Utility Functions for handling units in selection box and under selection cursor",
		author    = "Shadowfury333",
		date      = "Jan 6th, 2016",
		license   = "GPLv2",
		version   = "1",
		layer     = 1000,
		enabled   = true,  --  loaded by default?
		api       = true,
		alwaysStart = true,
	}
end
----------------------------------------------------------------------------
-------------------------Interface---------------------------------------

WG.PreSelection_GetUnitUnderCursor = function (onlySelectable)
	--return nil | unitID
end

WG.PreSelection_IsSelectionBoxActive = function ()
	--return boolean
end

WG.PreSelection_GetUnitsInSelectionBox = function ()
	--return nil | {[1] = unitID, etc.}
end

WG.PreSelection_IsUnitInSelectionBox = function (unitID)
	--return boolean
end

----------------------------------------------------------------------------
----------------------Implementation-------------------------------------

include("Widgets/COFCtools/TraceScreenRay.lua")


local math_acos             = math.acos
local math_atan2            = math.atan2
local math_pi               = math.pi
local math_min              = math.min
local math_max              = math.max
local spIsUnitSelected      = Spring.IsUnitSelected
local spTraceScreenRay      = Spring.TraceScreenRay
local spGetMouseState       = Spring.GetMouseState
local spIsAboveMiniMap      = Spring.IsAboveMiniMap
local spWorldToScreenCoords = Spring.WorldToScreenCoords

local start
local screenStartX, screenStartY = 0, 0
local cannotSelect = false
local holdingForSelection = false
local thruMinimap = false

local boxedUnitIDs

local function SafeTraceScreenRay(x, y, onlyCoords, useMinimap, includeSky, ignoreWater)
	local type, pt = Spring.TraceScreenRay(x, y, onlyCoords, useMinimap, includeSky, ignoreWater)
	if not pt then
		local cs = Spring.GetCameraState()
		local camPos = {px=cs.px,py=cs.py,pz=cs.pz}
		local camRot = {}
		if cs.rx then
			camRot = {rx=cs.rx,ry=cs.ry,rz=cs.rz}
		else
			local ry = (math_pi - math_atan2(cs.dx, -cs.dz)) --goes from 0 to 2PI instead of -PI to PI, but the trace maths work either way
			camRot = {rx=math_pi/2 - math_acos(cs.dy),ry=ry,rz=0}
		end
		local vsx, vsy = Spring.GetViewGeometry()
		local x, y, z = TraceCursorToGround(vsx, vsy, {x=x, y=y}, cs.fov, camPos, camRot, -4900)
		pt = {x, y, z}
		type = "ground"
	end
	return type, pt
end

WG.PreSelection_GetUnitUnderCursor = function (onlySelectable, ignoreSelectionBox)
	local x, y, lmb, mmb, rmb, outsideSpring = spGetMouseState()

	if mmb or rmb or outsideSpring then
		cannotSelect = true
	elseif cannotSelect and not lmb then
		cannotSelect = false
	end
	if outsideSpring then
		return
	end

	local aboveMiniMap = spIsAboveMiniMap(x, y)
	local onAndUsingMinimap = (not WG.MinimapDraggingCamera and aboveMiniMap) or not aboveMiniMap

	if (ignoreSelectionBox or not WG.PreSelection_IsSelectionBoxActive()) and
			onAndUsingMinimap and
			(not onlySelectable or (onlySelectable and not cannotSelect)) then
		--holding time when starting box selection, that way it avoids flickering if the hovered unit is selected quickly in the box selection
		local pointedType, data = spTraceScreenRay(x, y, false, true)
		if pointedType == 'unit' and Spring.ValidUnitID(data) and not WG.drawtoolKeyPressed then -- and not spIsUnitIcon(data) then
			return data
		else
			return nil
		end
	end
end

WG.PreSelection_IsSelectionBoxActive = function ()
	local x, y, lmb = spGetMouseState()
	local _, here = SafeTraceScreenRay(x, y, true, thruMinimap)

	if lmb and not cannotSelect and holdingForSelection and not (here[1] == start[1] and here[2] == start[2] and here[3] == start[3]) then
		return true
	end
	return false
end

WG.PreSelection_GetUnitsInSelectionBox = function ()

	local x, y, lmb = spGetMouseState()

	if lmb and not cannotSelect and holdingForSelection then
		local spec, fullview, fullselect = Spring.GetSpectatingState()
		local myTeamID = Spring.GetMyTeamID()

		if thruMinimap then
			local posX, posY, sizeX, sizeY = Spring.GetMiniMapGeometry()
			x = math_max(x, posX)
			x = math_min(x, posX+sizeX)
			y = math_max(y, posY)
			y = math_min(y, posY+sizeY)
			local _, here = SafeTraceScreenRay(x, y, true, thruMinimap)
			left = math_min(start[1], here[1])
			bottom = math_min(start[3], here[3])
			right = math_max(start[1], here[1])
			top = math_max(start[3], here[3])
			local units = Spring.GetUnitsInRectangle(left, bottom, right, top)
			if spec and fullselect then
				return (WG.SelectionRank_GetFilteredSelection and WG.SelectionRank_GetFilteredSelection(units)) or units --nil if empty
			else
				local myUnits = {}
				local teamID = 0
				for i = 1, #units do
					teamID = Spring.GetUnitTeam(units[i])
					if teamID == myTeamID and not Spring.GetUnitNoSelect(units[i]) then
						myUnits[#myUnits+1] = units[i]
					end
				end
				if #myUnits > 0 then
					return (WG.SelectionRank_GetFilteredSelection and WG.SelectionRank_GetFilteredSelection(myUnits)) or myUnits
				else
					return nil
				end
			end
		else
			local allBoxedUnits = {}
			local units = {}

			if spec and fullselect then
				units = Spring.GetAllUnits()
			else
				units = Spring.GetTeamUnits(myTeamID)
			end

			for i=1, #units do
				local uvx, uvy, uvz = Spring.GetUnitViewPosition(units[i], true)
				local ux, uy, uz = spWorldToScreenCoords(uvx, uvy, uvz)
				local hereMouseX, hereMouseY = x, y
				if ux and not Spring.GetUnitNoSelect(units[i]) then
					if ux >= math_min(screenStartX, hereMouseX) and ux < math_max(screenStartX, hereMouseX) and uy >= math_min(screenStartY, hereMouseY) and uy < math_max(screenStartY, hereMouseY) then
						allBoxedUnits[#allBoxedUnits+1] = units[i]
					end
				end
			end
			if #allBoxedUnits > 0 then
				return (WG.SelectionRank_GetFilteredSelection and WG.SelectionRank_GetFilteredSelection(allBoxedUnits)) or allBoxedUnits
			else
				return nil
			end
		end
	else
		holdingForSelection = false
		return nil
	end
end

WG.PreSelection_IsUnitInSelectionBox = function (unitID)
	if not boxedUnitIDs then
		boxedUnitIDs = {}
		local boxedUnits = WG.PreSelection_GetUnitsInSelectionBox()
		if boxedUnits then
			for i=1, #boxedUnits do
				boxedUnitIDs[boxedUnits[i]] = true
			end
		end
	end
	return boxedUnitIDs[unitID] or false
end

function widget:ShutDown()
	WG.PreSelection_GetUnitUnderCursor = nil
	WG.PreSelection_IsSelectionBoxActive = nil
	WG.PreSelection_GetUnitsInSelectionBox = nil
	WG.PreSelection_IsUnitInSelectionBox = nil
end

function widget:Update()
	boxedUnitIDs = nil
end

function widget:MousePress(x, y, button)
	screenStartX = x
	screenStartY = y
	if (button == 1) and Spring.GetActiveCommand() == 0 then
		thruMinimap = not WG.MinimapDraggingCamera and spIsAboveMiniMap(x, y)
		_, start = SafeTraceScreenRay(x, y, true, thruMinimap)
		holdingForSelection = true
	end
	return false
end
