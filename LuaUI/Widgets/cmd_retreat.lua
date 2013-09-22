-- $Id: cmd_retreat.lua 4138 2009-03-22 07:40:46Z carrepairer $
function widget:GetInfo()
  return {
    name      = "Retreat",
    desc      = " v0.277 Place 'retreat zones' on the map and order units to retreat to them at desired HP percentages.",
    author    = "CarRepairer",
    date      = "2008-03-17", --2013-9-21
    license   = "GNU GPL, v2 or later",
    handler   = true,
    layer     = 2, --start after unit_start_state.lua (to apply saved initial retreat state)
    enabled   = true
  }
end

-- speed-ups
local glDepthTest      = gl.DepthTest
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glColor          = gl.Color
local GL_GREATER       = GL.GREATER

local CMD_WAIT          = CMD.WAIT
local CMD_MOVE          = CMD.MOVE
local CMD_PATROL        = CMD.PATROL
local CMD_REPAIR        = CMD.REPAIR
local CMD_STOP			= CMD.STOP

local CMD_CLOAK         = CMD.CLOAK

local CMD_INSERT        = CMD.INSERT
local CMD_REMOVE        = CMD.REMOVE

local CMD_RETREAT       = 10000
local CMD_SETHAVEN      = 10001

local GetGameFrame     = Spring.GetGameFrame
local GetLocalTeamID   = Spring.GetLocalTeamID
local GetUnitHealth    = Spring.GetUnitHealth
local GetUnitCommands  = Spring.GetUnitCommands
local GetUnitPosition  = Spring.GetUnitPosition
local GetUnitDefID     = Spring.GetUnitDefID
local GetSelectedUnits = Spring.GetSelectedUnits
local GetUnitIsStunned	   = Spring.GetUnitIsStunned
local SelectUnitArray = Spring.SelectUnitArray

--local AreTeamsAllied   = Spring.AreTeamsAllied
local GiveOrderToUnit  = Spring.GiveOrderToUnit
--local IsGuiHidden		=	Spring.IsGUIHidden

local echo = Spring.Echo

local abs, rand       = math.abs, math.random

local currentGameFrame = 0

local dist = 160 --retreat zone radius
local maxDistSqr = dist * dist
local myTeamID
local tooltips = {}

local retreatMoveOrders, wantRetreat, retreatOrdersArray = {}, {}, {}, {}
local wantStopRetreat 			= {}
local mobileUnits, havens = {}, {}
local processUnitsNow = {}
local retreatCmds, retreatWaitCmds, checkNextCmd = {}, {}, {}
local waitingForCommands = {}
local havenCount = 0

local retreatedUnits = {} --recently retreating unit that is about to be deselected from user selection
local currentSelection = nil --current unit selection (for deselecting any retreating units. See code for more detail)
local maximumDeselect = 0.4 --maximum fraction of retreating-unit w.r.t. healthy-unit in current selection before auto-deselect ignore selection.

-------------------------------------
options_path = 'Game/Unit AI/Retreat Zone' --//for use 'with gui_epicmenu.lua'
options_order = {'removeFromSelection','returnLastPosition'}
options = {
	removeFromSelection = {
		name = 'Auto Unselect units',
		type = 'bool',
		value = false,
		desc = 'Automatically remove retreating unit from current selection if majority is healthy units. (Retreating unit might need exclusion from orders given to healthy units)',
	},
	returnLastPosition = {
		name = 'Return to last position',
		type = 'bool',
		value = false,
		desc = 'Always attempt to return unit to their last known position. (Unit might need to return to their last idle position or their last location where their previous order expired)',
	},
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CanReallyMove(unitDefID)
  -- we let factories have the retreat button, but we don't check them
  -- (factory have canMove for rallying new units, but factory speed should be 0)
  local ud = UnitDefs[unitDefID]
  if (ud == nil) then
    return false
  end
  return (ud.speed > 0)
end

local function HeadingToHaven(unitID)
	if (havenCount == 0) then
		return false
	end

	local dx, dy, dz = retreatMoveOrders[unitID][1], retreatMoveOrders[unitID][2], retreatMoveOrders[unitID][3]

	for havenUnitID, havenPosition in pairs(havens) do
		local hx, hy, hz = havenPosition[1], havenPosition[2], havenPosition[3]
		if hx then 
			local dSquared = (hx - dx)^2 + (hz - dz)^2
			if (dSquared < maxDistSqr) then
				return true
			end
		end
	end--for
	return false
end


function GetFirstCommand(unitID)
	local queue = GetUnitCommands(unitID, 1)
	return queue and queue[1]
end


local function FindClosestHaven(sx, _, sz)
  local closestDistSqr = math.huge
  local cx, cy, cz  --  closest coordinates
  for havenID, havenPosition in pairs(havens) do
    local hx, hy, hz = havenPosition[1], havenPosition[2], havenPosition[3]
    if hx then 
      local dSquared = (hx - sx)^2 + (hz - sz)^2
      if (dSquared < closestDistSqr) then
        closestDistSqr = dSquared
        cx = hx; cy = hy; cz = hz
	cHavenID = havenID
      end
    end
  end
  if (not cx) then return -1, -1, -1, -1 end  -- should not happen
  return cx, cy, cz, closestDistSqr, cHavenID
end

local function FindClosestHavenToUnit(unitID)
  local ux, _, uz = GetUnitPosition(unitID)
  return FindClosestHaven(ux, _, uz)
end

local function IsRetreatMove(unitID, cmd)
	local dest = retreatMoveOrders[unitID]

	if not dest or not cmd then
		return false
	end
	
	echo(CMD[cmd.id], cmd.params[1] , cmd.params[2] , cmd.params[3], dest[1], dest[2], dest[3]  )

	if cmd.params[1] == dest[1] 
		and  cmd.params[2] == dest[2]
		and  cmd.params[3] == dest[3]
		then
		return true
	end
	return false
end

local function addHaven(x, y, z)
	havenCount = havenCount + 1
	havens[#havens+1] = {x, y, z}
end


local function removeHaven(havenID)
	if havens[havenID] then
		havenCount = havenCount - 1
	end
	havens[havenID] = nil
end


local function setRetreatOrder(unitID, unitDefID, retreatOrder)
	retreatOrdersArray[unitID] = retreatOrder
	mobileUnits[unitID] = mobileUnits[unitID] or CanReallyMove(unitDefID) --note: mobileUnits[unitID] is used to filter only moving object for periodic health checks
end

function GetFirst3Commands(unitID)
	local queue = GetUnitCommands(unitID, 3)
	return queue
end


local function IsFirstCommandRetreatMove(unitID)
	local cmd = GetFirstCommand(unitID)
	return IsRetreatMove(unitID, cmd)
end


function StopRetreating(unitID)
	if waitingForCommands[unitID] then
		return
	end
	local cmds = GetFirst3Commands(unitID)

	for _,cmd in ipairs(cmds) do
		if cmd.tag == retreatCmds[unitID] or cmd.tag == retreatWaitCmds[unitID] then
			--echo('remove cmd', cmd.id )
			GiveOrderToUnit(unitID, CMD_REMOVE, { cmd.tag }, {})
		end
	end
	retreatCmds[unitID] = nil
	retreatWaitCmds[unitID] = nil
	
	wantStopRetreat[unitID] = nil
	retreatMoveOrders[unitID] = nil
end


local function StartRetreat(unitID, force)
	local hx, hy, hz, dSquared = FindClosestHavenToUnit(unitID)
	hx = hx + dist - rand(10, dist*2)
	--hy = hy
	hz = hz + dist - rand(10, dist*2)

	if force or dSquared > maxDistSqr then
		local insertIndex = 0
		
		retreatMoveOrders[unitID] = {hx, hy, hz}
		waitingForCommands[unitID] = true
		
		-- using OPT_INTERNAL so that the CMD.MOVE order is not cycled when the unit has repeat enabled
		GiveOrderToUnit(unitID, CMD_INSERT, { insertIndex, CMD_MOVE, CMD.OPT_INTERNAL, hx, hy, hz}, CMD.OPT_ALT) -- ALT makes the 0 positional
		GiveOrderToUnit(unitID, CMD_INSERT, { insertIndex+1, CMD_WAIT, CMD.OPT_SHIFT}, CMD.OPT_ALT) --SHIFT W

		
		--add last position
		if options.returnLastPosition.value then
			local ux, uy, uz = GetUnitPosition(unitID)
			retreatMoveOrders[unitID][4] = ux
			retreatMoveOrders[unitID][5] = uy
			retreatMoveOrders[unitID][6] = uz
		end
	end
end

local function SetWantRetreat(unitID, want)
	if wantRetreat[unitID] ~= want then
		processUnitsNow[unitID] = true
	end
	if wantRetreat[unitID] and not want then
		wantStopRetreat[unitID] = true
	end
	
	wantRetreat[unitID] = want
	WG.icons.SetUnitIcon( unitID, {
		name='retreatstate',
		texture= want and 'Anims/cursorrepair_old.png' or nil
	} )
end

local function CheckSetWantRetreat(unitID, health, maxHealth, retreatOrder)
	local healthRatio = health / maxHealth
	local threshold = retreatOrder * 0.3
	local _,_,inBuild = GetUnitIsStunned(unitID)

	if healthRatio < threshold and (not inBuild) then        
		SetWantRetreat(unitID, true)
	elseif (healthRatio == 1) then
		SetWantRetreat(unitID, nil)
	end
end

local function CheckCommands(unitID)
	local cmds = GetFirst3Commands(unitID)
	if #cmds < 2 then return end
	
	if IsRetreatMove(unitID, cmds[1]) and cmds[2].id == CMD.WAIT then
		retreatCmds[unitID] = cmds[1].tag
		retreatWaitCmds[unitID] = cmds[2].tag
		waitingForCommands[unitID] = nil
		processUnitsNow[unitID] = true
	end
end

local function ProcessUnit(unitID)
	if wantRetreat[unitID] then
		if not retreatWaitCmds[unitID] then
			StartRetreat(unitID, true)
		end
		if options.removeFromSelection.value then
			retreatedUnits[#retreatedUnits+1] = unitID
		end
		
	elseif wantStopRetreat[unitID] then
		StopRetreating(unitID)
	end
end

local function RemoveUnitData(unitID)
	SetWantRetreat(unitID, nil)
	retreatOrdersArray[unitID] = nil
	retreatMoveOrders[unitID] = nil
	retreatCmds[unitID] = nil
	retreatWaitCmds[unitID] = nil
	waitingForCommands[unitID] = nil
	processUnitsNow[unitID] = nil
	wantRetreat[unitID] = nil
	wantStopRetreat[unitID] = nil
	mobileUnits[unitID] = nil
end

local function RemoveAllButRetreatCmds(unitID)
	local cmds = GetUnitCommands(unitID)
	for _,cmd in ipairs(cmds) do
		if cmd.tag ~= retreatCmds[unitID] and cmd.tag ~= retreatWaitCmds[unitID] then
			echo(' -- removing ', CMD[cmd.id], cmd.tag)
			GiveOrderToUnit(unitID, CMD_REMOVE, { cmd.tag }, {})
		end
	end
end

--------------------
-- callins

function widget:Initialize()
	myTeamID = GetLocalTeamID()
	tooltips[1] = 'Orders: Never retreat.'
	tooltips[2] = 'Orders: Retreat at less than 30% health (right-click to cancel).'
	tooltips[3] = 'Orders: Retreat at less than 60% health (right-click to cancel).'
	tooltips[4] = 'Orders: Retreat at less than 90% health (right-click to cancel).'

	WG['retreat'] = {}
	WG['retreat'].addRetreatCommand = function(unitID, unitDefID, retreatOrder)		
		setRetreatOrder(unitID, unitDefID, retreatOrder)
	end
	
	WG.icons.SetOrder( 'retreatstate', 5 )
	WG.icons.SetDisplay( 'retreatstate', true )
	WG.icons.SetPulse( 'retreatstate', true )
	
	WG.retreatingUnits = retreatMoveOrders --make this table global, available to all widget
end

function widget:UnitFromFactory(unitID, unitDefID, teamID, builderID, _, _)
	local ud = UnitDefs[unitDefID]
	if ud.canMove and not retreatOrdersArray[unitID] and builderID then --unit can move, unit not given retreat order yet, unit has a builder    
		setRetreatOrder(unitID, unitDefID, retreatOrdersArray[builderID])
		SetWantRetreat(unitID, nil)
	end	
end

function widget:UnitDestroyed(unitID, _, teamID)
	RemoveUnitData(unitID)
end

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	RemoveUnitData(unitID)
end


function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_SETHAVEN then
		local x,y,z = cmdParams[1], cmdParams[2], cmdParams[3]
		local _, _, _, dSquared, closestHavenID = FindClosestHaven(x,y,z)
		if dSquared ~= -1 and dSquared < dist*dist then
			removeHaven(closestHavenID)
		else
			addHaven(x,y,z)
		end
		return true
		
	elseif cmdID == CMD_RETREAT then
		local foundValidUnit = false
		local newRetreatOrder = nil
		local selectedUnits = GetSelectedUnits()
		for i=1, #selectedUnits do
			local unitID = selectedUnits[i]
			local unitDefID = GetUnitDefID(unitID)
			local ud = UnitDefs[unitDefID]

			if ud.canMove then --Check canmove for mixed selections

				SetWantRetreat(unitID, nil)
				if not foundValidUnit then
					foundValidUnit = true
					-- [[ --scheme1: left-click to cycle between 3 retreat state, right-click to de-activate retreat
					if not cmdOptions.right then
						if retreatOrdersArray[unitID] then
							newRetreatOrder = retreatOrdersArray[unitID] % 3 + 1
						else
							newRetreatOrder = 1
						end
					end
					--]]
					--[[
					--scheme2: left-click to cycle 4 retreat state upward, right-click to cycle 4 retreat state downward.
					newRetreatOrder = retreatOrdersArray[unitID] or 0
					if cmdOptions.right then
						newRetreatOrder = newRetreatOrder - 1
						if newRetreatOrder < 0 then
							newRetreatOrder = 3
						end
					else 
						newRetreatOrder = newRetreatOrder + 1
						if newRetreatOrder == 4 then
							newRetreatOrder = 0
						end
					end
					--]]
				end

				setRetreatOrder(unitID, unitDefID, newRetreatOrder)
				if newRetreatOrder==0 then --if no-retreat
					wantStopRetreat[unitID] = true
				end
			end --if canmove
		end --for
		return true
	else
		if cmdOptions.shift then
			return false
		end
		
		--don't override commandinsert
		local _,_,meta,_ = Spring.GetModKeyState()
		if meta then
			return false
		end
		
		local selectedUnits = GetSelectedUnits()
		for i=1, #selectedUnits do
			local unitID = selectedUnits[i]
			
			local cmdOptions2 = {}
			--if (cmdOptions.shift) then table.insert(cmdOptions2, "shift")   end
			if (cmdOptions.alt)   then table.insert(cmdOptions2, "alt")   end
			if (cmdOptions.ctrl)  then table.insert(cmdOptions2, "ctrl")  end
			if (cmdOptions.right) then table.insert(cmdOptions2, "right") end
			
			
			if wantRetreat[unitID] and
				(
					cmdID == CMD.MOVE
					or cmdID == CMD.FIGHT
					or cmdID == CMD.STOP
				)
				then
				CheckCommands(unitID)
				RemoveAllButRetreatCmds(unitID)
				table.insert(cmdOptions2, "shift")
			end
			GiveOrderToUnit(unitID, cmdID, cmdParams, cmdOptions2 )
			
		end
		
		return true
	end
end


function widget:CommandsChanged()
	local selectedUnits = GetSelectedUnits()
	local foundRetreatable = false
	local customCommands = widgetHandler.customCommands

	--Add retreat-area button
	table.insert(customCommands, {
		id      = CMD_SETHAVEN,
		type    = CMDTYPE.ICON_MAP,
		tooltip = 'Place a retreat zone. Units will retreat there.',
		cursor  = 'Repair',
		action  = 'sethaven',
		params  = { }, 
		texture = 'LuaUI/Images/commands/Bold/retreat.png',

		pos = {CMD_CLOAK}, 
	})

	-- Find out if menu should display retreat-state button 
	--(current unit selection may or may not contain a retreatable unit, this code checks for retreatable unit and add button to menu if appropriate)
	for _, unitID in ipairs(selectedUnits) do

		local unitID = GetSelectedUnits()[1]

		local unitDefID = GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]

		if not foundRetreatable and ud and ud.canMove then --Note: canMove include factory
			foundRetreatable = true
			local retreatOrder = retreatOrdersArray[unitID] or 0			
			--widgetHandler:AddLayoutCommand({
			table.insert(customCommands, {
				id      = CMD_RETREAT,
				type    = CMDTYPE.ICON_MODE,
				name    = 'Retreat',
				tooltip = tooltips[retreatOrder + 1],
				cursor  = 'Retreat',
				action  = 'retreat',
				params  = { retreatOrder , 'Retreat Off', 'Retreat 30%', 'Retreat 60%', 'Retreat 90%' }, 

				pos = {CMD_CLOAK}, 
			})
   
		end--if canmove
		
		if foundRetreatable then
			return
		end
	end--for 
end

function widget:SelectionChanged(newSelection)
	if (havenCount > 0) and options.removeFromSelection.value then
		currentSelection = newSelection
	end
end

function widget:UnitDamaged(unitID) 
	local retreatOrder = retreatOrdersArray[unitID]
	
	if (havenCount > 0)
		and retreatOrder ~= nil
		and retreatOrder > 0
		and mobileUnits[unitID]
		and not retreatMoveOrders[unitID] 
	then 
		local health, maxHealth = GetUnitHealth(unitID)
		if (health) then

			CheckSetWantRetreat(unitID, health, maxHealth, retreatOrder)
			
		end 
	end 

end 

function widget:GameFrame(gameFrame)
	local frame32 = gameFrame % 32 == 0 -- ~1 second
	local frame160 = gameFrame % 160 == 0 -- ~5 second
	currentGameFrame = gameFrame

	if frame32 then
		--check all unit if retreat is needed, apply retreat if needed, remove retreat queue if no longer needed.
		for unitID, retreatOrders in pairs(retreatOrdersArray) do
			if mobileUnits[unitID] then
        		local health, maxHealth = GetUnitHealth(unitID)
				
				if (health) then
					CheckSetWantRetreat(unitID, health, maxHealth, retreatOrders)
				end
				
				if waitingForCommands[unitID] then
					CheckCommands(unitID)
				end
				
			end
		end -- for
	end --if frame 1/30
	
	if frame160 then
		for unitID, retreatOrders in pairs(retreatOrdersArray) do
			if retreatMoveOrders[unitID] and not HeadingToHaven(unitID) then
				StopRetreating(unitID)
				processUnitsNow[unitID] = true
			end
		end
	end
	
	for unitID, _ in pairs(processUnitsNow) do
		ProcessUnit(unitID)
	end
	
	processUnitsNow = {}
	
	--remove retreating unit from selection (only perform at selection change or when retreat is ordered)
	if options.removeFromSelection.value then
		local commitChange = false
		if currentSelection then --new selection?
			local unitsToDeselect= {}
			local selectionCount = #currentSelection
			local retreatedCount = 0
			for i=1, selectionCount do
				local unitID = currentSelection[i]
				if retreatMoveOrders[unitID] then --selection contain retreating units
					unitsToDeselect[#unitsToDeselect+1] = i
					retreatedCount = retreatedCount + 1
				end
			end
			if retreatedCount > 0 and (retreatedCount/selectionCount) < maximumDeselect then --retreating unit is minority?
				table.sort(unitsToDeselect, function(a,b) return a>b end) --sort from biggest index to lowest index
				for i=1, retreatedCount do
					table.remove(currentSelection, unitsToDeselect[i]) --remove from list
				end
				commitChange = true--update unit selection
			end
		end
		if #retreatedUnits > 0 then -- there is recently retreating units?
			currentSelection = currentSelection or GetSelectedUnits() --get existing selection
			local changes = false
			for i=1, #retreatedUnits do
				local retreatingUnitID = retreatedUnits[i]
				for j=1, #currentSelection do
					local selectedUnitID = currentSelection[j]
					if selectedUnitID == retreatingUnitID then --selection contain recently retreating units
						table.remove(currentSelection, j) --unit remove from existing selection
						changes = true
						break;
					end
				end
			end
			if changes then --have unit to deselect?
				commitChange = true --update unit selection
			end
			retreatedUnits = {} --empty recent-retreat list
		end
		if commitChange then
			SelectUnitArray(currentSelection) --apply selection changes
		end
		currentSelection = nil --flag: finish deselecting units
	end
end

function widget:DrawWorld()
	local gameFrame = currentGameFrame

	local fade = abs((gameFrame % 40) - 20) / 20
  
	--Draw ambulance on havens.
	if (havens) then

		glDepthTest(true)
		gl.LineWidth(2)

		for havenID, havenPosition in pairs(havens) do
			local x, y, z = havenPosition[1], havenPosition[2], havenPosition[3]

			gl.LineWidth(4)
			glColor(1, 1, 1, 0.5)
			gl.DrawGroundCircle(x, y, z, dist, 32)

			gl.LineWidth(2)
			glColor(1, 0.1, 0.1, 0.8)
			gl.DrawGroundCircle(x, y, z, dist, 32)

		end --for
		glAlphaTest(GL_GREATER, 0)
		glColor(1,fade,fade,fade+0.1)
		glTexture('LuaUI/Images/commands/Bold/retreat.png')
		
		for unitID, havenPosition in pairs(havens) do
			local x, y, z = havenPosition[1], havenPosition[2], havenPosition[3]
			gl.PushMatrix()
			glTranslate(x, y, z)
			glBillboard()
			glTexRect(-10, 0, 10, 20)
			gl.PopMatrix()
		end --for
		
		glTexture(false)
		glAlphaTest(false)
		glDepthTest(false)
	end --if havens
	
end --DrawWorld

--Bind a hotkey to "luaui noretreat" for quick bravery
function widget:TextCommand(command)
	if (command == "noretreat") then
		widgetHandler:CommandNotify(CMD_RETREAT, {}, { right=true })
		return true
	end
	return false
end