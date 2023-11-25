--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local versionNumber = "v1.0"

function widget:GetInfo()
	return {
		name      = "Lobster units highlighter",
		desc      = versionNumber .. " Highlights units that will be lobbed by a lobster's dgun command.",
		author    = "dyth68",
		date      = "25 November 2023",
		license   = "PD",
		layer     = 1,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--config
--------------------------------------------------------------------------------
-- TODO: Make this configurable
local unitJumpStatusLineWidth = 4
-- TODO: Make colors configurable
local RED = {1, 0.35, 0.35, 0.75}
local ORANGE = {0.9, 0.7, 0.35, 0.75}
local GREEN = {0.35, 1, 0.35, 0.75}
local YELLOW = {1, 1, 0.35, 0.75}
-- TODO: draw circles above the icons when in icon mode

--------------------------------------------------------------------------------
--vars
--------------------------------------------------------------------------------
local lobstersSelected = {}
local anyLobstersSelected = false

--------------------------------------------------------------------------------
--speedups
--------------------------------------------------------------------------------
local GetActiveCommand       = Spring.GetActiveCommand
local GetUnitPosition        = Spring.GetUnitPosition
local GetUnitsInSphere       = Spring.GetUnitsInSphere
local GetMouseState          = Spring.GetMouseState
local TraceScreenRay         = Spring.TraceScreenRay

local spGetUnitDefID         = Spring.GetUnitDefID

local CMD_MANUALFIRE         = CMD.MANUALFIRE

local glColor                = gl.Color
local glLineWidth            = gl.LineWidth
local glDrawGroundCircle     = gl.DrawGroundCircle


-- TODO: don't hard code lobster and first weapon
local lobsterDefID           = UnitDefNames.amphlaunch.id
local lobsterGatherRange     = UnitDefs[lobsterDefID].customParams.thrower_gather
local lobsterFireRange       = WeaponDefs[UnitDefs[lobsterDefID].weapons[1].weaponDef].range

--------------------------------------------------------------------------------
--math
--------------------------------------------------------------------------------
-- taken from unit_jugglenaut_juggle.lua
local function distance(x1,y1,z1,x2,y2,z2)
  return math.sqrt((x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2)
end

--------------------------------------------------------------------------------
--lobster finding
--------------------------------------------------------------------------------

local function UpdateSelection(sel)
	anyLobstersSelected = false
	lobstersSelected = {}
	for i = 1, #sel do
		local unitID = sel[i]
		local unitDefID = spGetUnitDefID(unitID)
		if unitDefID then
			if unitDefID == lobsterDefID then
				anyLobstersSelected = true
				lobstersSelected[#lobstersSelected + 1] = unitID
			end
		end
	end
	
end

--------------------------------------------------------------------------------
--mouse management
--------------------------------------------------------------------------------

-- Taken from gui_attack_aoe.lua
local function GetMouseTargetPosition()
	local mx, my = GetMouseState()
	local mouseTargetType, mouseTarget = TraceScreenRay(mx, my, false, true, false, true)

	if (mouseTargetType == "ground") then
		return mouseTarget[1], mouseTarget[2], mouseTarget[3], true
	elseif (mouseTargetType == "unit") then
		return GetUnitPosition(mouseTarget)
	elseif (mouseTargetType == "feature") then
		local _, coords = TraceScreenRay(mx, my, true, true, false, true)
		if coords and coords[3] then
			return coords[1], coords[2], coords[3], true
		else
			return GetFeaturePosition(mouseTarget)
		end
	else
		return nil
	end
end
--------------------------------------------------------------------------------
--Drawing
--------------------------------------------------------------------------------
function DrawStatusCircle(color, x, y, z)
	glColor(color)
	glLineWidth(unitJumpStatusLineWidth)
	glDrawGroundCircle(x, y, z, 15, 20)
	glColor(1,1,1,1)
end

function drawLobsterLobProperties()
	local mx, my, mz = GetMouseTargetPosition()

	local unitsAffected = {} -- keys are unit IDs, bool value indicates whether targetted area is in range of this lobster
	local unitsJustOutOfRange = {}
	-- Draw lobster circles and figure out what units will be thrown
	for i = 1, #lobstersSelected do
		local unitID = lobstersSelected[i]
		local x,y,z, fx, fy, fz = GetUnitPosition(unitID, true)
		
		-- The "mx and" is to avoid crashes when the mouse is beyond the screen
		local inCursorRange = mx and (distance(x,y,z, mx, my, mz) <= lobsterFireRange)
		
		local unitsAffectedByThis = GetUnitsInSphere(fx, fy, fz, lobsterGatherRange)
		for i = 1, #unitsAffectedByThis do
			local unitAffectedID = unitsAffectedByThis[i]
			if unitID ~= unitAffectedID then
				if unitsAffected[unitAffectedID] == nil or unitsAffected[unitAffectedID] == false then
					unitsAffected[unitAffectedID] = inCursorRange
				end
			end
		end

		local unitsAlmostAffectedByThis = GetUnitsInSphere(fx, fy, fz, lobsterGatherRange + 30)
		for i = 1, #unitsAlmostAffectedByThis do
			local unitAffectedID = unitsAlmostAffectedByThis[i]
			if unitID ~= unitAffectedID and unitsAffected[unitAffectedID] == nil then
				unitsJustOutOfRange[unitAffectedID] = true
			end
		end

		-- Draw the lobster gather circle
		if inCursorRange then
			glColor(YELLOW)
		else
			glColor(ORANGE)
		end
		glLineWidth(1)
		glDrawGroundCircle(fx, fy, fz, lobsterGatherRange, 50)
		glColor(1,1,1,1)
		
		-- Draw the lobster attack circle because the inbuilt one is buggy and only draws one if you have multiple lobs selected
		glColor(RED)
		glLineWidth(1)
		glDrawGroundCircle(x, y, z, lobsterFireRange, 50)
		glColor(1,1,1,1)
	end
	-- Highlight lobsters that will NOT be thrown
	for i = 1, #lobstersSelected do
		local unitID = lobstersSelected[i]
		if unitsAffected[unitID] == nil then
			local _,_,_,fx, fy, fz = GetUnitPosition(unitID, true)
			DrawStatusCircle(RED, fx, fy, fz)
		end
	end
	-- Highlight units that are just out of range
	for unitID, _ in pairs(unitsJustOutOfRange) do
		if unitsAffected[unitID] == nil then
			local _,_,_,fx, fy, fz = GetUnitPosition(unitID, true)
			DrawStatusCircle(RED, fx, fy, fz)
		end
	end
	-- Highlight units that will be thrown
	for unitID, inRange in pairs(unitsAffected) do
		local _,_,_,fx, fy, fz = GetUnitPosition(unitID, true)
		if inRange then
			DrawStatusCircle(GREEN, fx, fy, fz)
		else
			DrawStatusCircle(ORANGE, fx, fy, fz)
			glColor(0.9, 0.7, 0.35, 0.75)
		end
	end
end


--------------------------------------------------------------------------------
--call-ins
--------------------------------------------------------------------------------
function widget:DrawWorld()
	local _, cmd, _ = GetActiveCommand()
	if anyLobstersSelected and cmd == CMD_MANUALFIRE then
		-- Doing lots of logic in the draw step, but it's quite performant 
		drawLobsterLobProperties()
	end
end


function widget:SelectionChanged(sel)
	UpdateSelection(sel)
end