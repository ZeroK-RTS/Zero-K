function widget:GetInfo()
  return {
    name      = "Retreat",
    desc      = "v0.281 Place 'retreat zones' on the map and order units to retreat to them at desired HP percentages.",
    author    = "CarRepairer",
    date      = "2008-03-17", --2014-2-3
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

VFS.Include("LuaRules/Configs/customcmds.h.lua")
VFS.Include("LuaRules/Utilities/unitTypeChecker.lua")
local CMD_WAIT          = CMD.WAIT
local CMD_MOVE          = CMD.MOVE
local CMD_PATROL        = CMD.PATROL
local CMD_REPAIR        = CMD.REPAIR
local CMD_STOP			= CMD.STOP

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

local retreatMoveOrders,retreatRearmOrders, wantRetreat, retreatOrdersArray = {}, {}, {}, {}
local mobileUnits,pauseRetreatChecks, havens = {}, {}, {}
local havenCount = 0
local airpadCount = 0

local retreatedUnits = {} --recently retreating unit that is about to be deselected from user selection
local currentSelection = nil --current unit selection (for deselecting any retreating units. See code for more detail)
local maximumDeselect = 0.51 -- (fraction), threshold ratio of retreating-unit to healthy-unit where retreating-unit become the majority and thus turning off auto-deselect.

-------------------------------------
options_path = 'Game/Unit AI/Retreat Zone' --//for use 'with gui_epicmenu.lua'
options_order = {'overrideableCommand','removeFromSelection','returnLastPosition'}
options = {
	overrideableCommand = {
		name = 'Overrideable Retreat',
		type = 'bool',
		value = false,
		desc = 'Suspend retreat of any unit if you give new order until the unit is idle. (Best to use with Auto-Deselect to prevent accidental override)',
	},
	removeFromSelection = {
		name = 'Auto Deselect units',
		type = 'bool',
		value = false,
		desc = 'Automatically exclude retreating unit from your user interface selection if the majority is healthy units (>50%).',
	},
	returnLastPosition = {
		name = 'Return to last position',
		type = 'bool',
		value = false,
		desc = 'Always try to return unit to their last known position.',
	},
}

local airpadDefs = {
	[UnitDefNames["factoryplane"].id] = true,
	[UnitDefNames["armasp"].id] = true,
	[UnitDefNames["armcarry"].id] = true,
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

local function IsRetreatMove(unitID, cmd)
	local dest = retreatMoveOrders[unitID]

	if not dest or not cmd then
		return false
	end

	if cmd.params[1] == dest[1] 
		and  cmd.params[2] == dest[2]
		and  cmd.params[3] == dest[3]
		then
		return true
	end
	return false
end

function GetFirstCommand(unitID)
	local queue = GetUnitCommands(unitID, 1)
	return queue and queue[1]
end

function GetFirst3Command(unitID)
	local queue = GetUnitCommands(unitID, 3)
	return queue
end

function StopRearm(unitID) --is called until rearm is cancelled
	local queue = GetFirst3Command(unitID)
	if (queue and queue[1] and queue[1].id == CMD_REARM) then
		local tag = queue[1].tag
		GiveOrderToUnit(unitID, CMD_REMOVE, {tag}, {})
		retreatRearmOrders[unitID]= nil
	elseif (not queue or not queue[1] or queue[1].id==CMD_STOP) and --no work to do??
	retreatRearmOrders[unitID][1] then --returnLastPosition enabled??
		local x,y,z = retreatRearmOrders[unitID][1],retreatRearmOrders[unitID][2],retreatRearmOrders[unitID][3]
		GiveOrderToUnit(unitID, CMD_MOVE, { x,y,z}, {})
		retreatRearmOrders[unitID]= nil
	end
end

function StopRetreating(unitID)
	if retreatMoveOrders[unitID] then
		local cmds = GetFirst3Command(unitID)

		if not cmds or not cmds[1] then
			retreatMoveOrders[unitID] = nil

		elseif IsRetreatMove(unitID, cmds[1]) then --is retreating to repair zone(?)	
			GiveOrderToUnit(unitID, CMD_REMOVE, { cmds[1].tag}, {})
			if cmds[2] and cmds[2].id==CMD_WAIT then --is the move+wait retreat combo(?)
				GiveOrderToUnit(unitID, CMD_REMOVE, { cmds[2].tag}, {})
				if (not cmds[3] or cmds[3].id==CMD_STOP) and retreatMoveOrders[unitID][4] then --no work to return to?? returnLastPosition enabled??
					local x,y,z = retreatMoveOrders[unitID][4],retreatMoveOrders[unitID][5],retreatMoveOrders[unitID][6]
					GiveOrderToUnit(unitID, CMD_MOVE, { x,y,z}, {})
				end
				
				retreatMoveOrders[unitID] = nil --unit no longer considered retreating
			end
			
		elseif (cmds[1].id == CMD_WAIT) then --is waiting for repair(?)		
			GiveOrderToUnit(unitID, CMD_REMOVE, { cmds[1].tag}, {})
			if (not cmds[2] or cmds[2].id==CMD_STOP) and retreatMoveOrders[unitID][4] then --no work to return to?? returnLastPosition enabled??
				local x,y,z = retreatMoveOrders[unitID][4],retreatMoveOrders[unitID][5],retreatMoveOrders[unitID][6]
				GiveOrderToUnit(unitID, CMD_MOVE, { x,y,z}, {})
			end
			retreatMoveOrders[unitID] = nil
		else --is currently some other command
			-- retreatMoveOrders[unitID] = nil
			--Note: didn't NIL-ify retreatingUnits[unitID] here so that StopRetreating() can run 2nd time later
		end
	else
		local cmd1 = GetFirstCommand(unitID)
		if not (cmd1 and cmd1.id == CMD_WAIT) then
			pauseRetreatChecks[unitID] = nil
		end
	end
end


local function StartRearm(unitID)
	local insertIndex = 0
	GiveOrderToUnit(unitID, CMD_INSERT, { insertIndex, CMD_FIND_PAD, CMD.OPT_INTERNAL}, CMD.OPT_ALT)
	retreatRearmOrders[unitID] = {nil,nil,nil}
	--add last position
	if options.returnLastPosition.value then
		local ux, uy, uz = GetUnitPosition(unitID)
		retreatRearmOrders[unitID][1] = ux
		retreatRearmOrders[unitID][2] = uy
		retreatRearmOrders[unitID][3] = uz
	end
end

local function StartRetreat(unitID, force)
	local hx, hy, hz, dSquared = FindClosestHavenToUnit(unitID)
	hx = hx + dist - rand(10, dist*2)
	--hy = hy
	hz = hz + dist - rand(10, dist*2)

	if force or dSquared > maxDistSqr then
		local insertIndex = 0
		-- using OPT_INTERNAL so that the CMD.MOVE order is not cycled when the unit has repeat enabled
		GiveOrderToUnit(unitID, CMD_INSERT, { insertIndex, CMD_MOVE, CMD.OPT_INTERNAL, hx, hy, hz}, CMD.OPT_ALT) -- ALT makes the 0 positional
		GiveOrderToUnit(unitID, CMD_INSERT, { insertIndex+1, CMD_WAIT, CMD.OPT_SHIFT}, CMD.OPT_ALT) --SHIFT W
		
		retreatMoveOrders[unitID] = {hx, hy, hz}
		
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
	if want then
		if (not pauseRetreatChecks[unitID])then
			local unitDefID = GetUnitDefID(unitID)
			local movetype = Spring.Utilities.getMovetype(UnitDefs[unitDefID])
			if (movetype==0 or movetype==1) and (airpadCount> 0) and (not retreatRearmOrders[unitID]) then
				StartRearm(unitID)
				if options.removeFromSelection.value then
					retreatedUnits[#retreatedUnits+1] = unitID
				end
			elseif (havenCount > 0) and (not retreatMoveOrders[unitID]) then
				StartRetreat(unitID)
				if options.removeFromSelection.value then
					retreatedUnits[#retreatedUnits+1] = unitID
				end
			end
		end
	elseif retreatMoveOrders[unitID] then 
		StopRetreating(unitID)
	elseif retreatRearmOrders[unitID] then
		StopRearm(unitID)
	end
	
	WG.icons.SetUnitIcon( unitID, {
		name='retreatstate',
		texture= want and 'Anims/cursorrepair_old.png' or nil
	} )
end

local function CheckSetWantRetreat(unitID, retreatOrder)
	local health, maxHealth = GetUnitHealth(unitID)
	if (health) then --note: old widget have this check, won't hurt to have it too
		local healthRatio = health / maxHealth
		local threshold = retreatOrder * 0.3
		local _,_,inBuild = GetUnitIsStunned(unitID)

		if healthRatio < threshold and (not inBuild) then        
			SetWantRetreat(unitID, true)
		elseif (healthRatio == 1) then
			SetWantRetreat(unitID, nil)
		end
	end
end


local function RemoveUnitData(unitID)
	SetWantRetreat(unitID, nil)
	pauseRetreatChecks[unitID] = nil
	retreatOrdersArray[unitID] = nil
	retreatMoveOrders[unitID] = nil
	retreatRearmOrders[unitID] = nil
	mobileUnits[unitID] = nil
end

local function PerformDeselection()
	local commitChange = false
	if currentSelection then --new selection?
		local unitsToDeselect= {}
		local selectionCount = #currentSelection
		local retreatedCount = 0
		for i=1, selectionCount do
			local unitID = currentSelection[i]
			if retreatMoveOrders[unitID] or retreatRearmOrders[unitID] then --selection contain retreating units
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

--------------------
-- callins

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOptions, cmdParams) 
	if not options.overrideableCommand.value then
		local commandOverriden = false
		
		if cmdID == CMD_MOVE then
			if not (math.bit_and(cmdOptions,CMD.OPT_SHIFT) > 0) then
				--move command not queued with SHIFT
				commandOverriden = true
			end
		elseif (math.bit_and(cmdOptions,CMD.OPT_ALT) > 0) then --@ ALT command???? (what is OPT_ALT command?)
			--ignore these priority commands hopefully issued only by this widget. 
		elseif cmdID == CMD.INSERT or cmdID == CMD.REMOVE then
			--any command that is inserted or removed by widget (to skirm & jink)
		elseif not (math.bit_and(cmdOptions,CMD.OPT_SHIFT) > 0)
			and cmdID ~= CMD_SET_WANTED_MAX_SPEED	
			and cmdID ~= CMD_FIRE_STATE	and cmdID ~= CMD_MOVE_STATE
			and cmdID ~= CMD_ONOFF		and cmdID ~= CMD_REPEAT
			and cmdID ~= CMD_WANT_CLOAK		and cmdID ~= CMD_CLOAK_SHIELD	
			and cmdID ~= CMD_STEALTH	and cmdID ~= CMD_WAIT
			and cmdID ~= CMD_IDLEMODE
		then
			--any other command that is not STATE-button and not queued with SHIFT
			commandOverriden = true
		end

		if commandOverriden and retreatMoveOrders[unitID] then
			local cmd1 = GetFirstCommand(unitID)

			if not cmd1 then
				--retreatMoveOrders[unitID] = nil
			elseif IsRetreatMove(unitID, cmd1) then
				StartRetreat(unitID, true) --add retreat each time user issued new command, and FORCE it so that unit inside retreat zone remain in retreat zone.
			elseif (cmd1.id == CMD_WAIT) then			
				GiveOrderToUnit(unitID, CMD_WAIT, {}, {})
			end
			
			--local selectedUnits = GetSelectedUnits()
			--for i=1, #selectedUnits do
				--local unitID = selectedUnits[i]
				--retreatMoveOrders[unitID] = nil
			--end

		elseif  commandOverriden and retreatRearmOrders[unitID] then
			local cmd1 = GetFirstCommand(unitID)
			if (cmd1 and cmd1.id == CMD_REARM) then
				StartRearm(unitID) --add rearm each time user issued new command
			end
		end
	end
end

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
	WG.retreatingUnitsRearm = retreatRearmOrders
	
	local allUnits = Spring.GetAllUnits()
	for i=1, #allUnits do
		local unitID = allUnits[i]
		if airpadDefs[GetUnitDefID(unitID)] then
			airpadCount = airpadCount + 1
		end
	end
end

function widget:UnitFromFactory(unitID, unitDefID, teamID, builderID, _, _)
	local ud = UnitDefs[unitDefID]
	if ud.canMove and not retreatOrdersArray[unitID] and builderID then --unit can move, unit not given retreat order yet, unit has a builder    
		setRetreatOrder(unitID, unitDefID, retreatOrdersArray[builderID])
		SetWantRetreat(unitID, nil)
	end	
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if airpadDefs[unitDefID] then
		airpadCount = airpadCount + 1
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	RemoveUnitData(unitID)
	if airpadDefs[unitDefID] then
		airpadCount = airpadCount - 1
	end
end

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	RemoveUnitData(unitID)
	if airpadDefs[unitDefID] then
		if newTeam == myTeamID then
			airpadCount = airpadCount + 1
		elseif oldTeam== myTeamID then
			airpadCount = airpadCount - 1
		end
	end
end

function widget:UnitIdle(unitID, unitDefID, teamID)
	pauseRetreatChecks[unitID] = nil --clear ignore list when unit idle
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
							newRetreatOrder = retreatOrdersArray[unitID] % 3 + 1 --1,2,3,1,2,3
						else
							newRetreatOrder = 1
						end
					else --right click cancel
						newRetreatOrder = 0
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
					StopRetreating(unitID) --stop retreat instantly
				end
			end --if canmove
		end --for
		return true
	else
		--exclude currently retreating unit until idle
		if ((havenCount > 0) or (airpadCount>0)) and options.overrideableCommand.value then
			local selectedUnits = GetSelectedUnits()
			for i=1, #selectedUnits do
				local unitID = selectedUnits[i]
				if retreatMoveOrders[unitID] then  --currently retreating
					pauseRetreatChecks[unitID] = true --suspend retreat command until unit become idle, "widget:UnitIdle()"
					retreatMoveOrders[unitID] = nil
				elseif retreatRearmOrders[unitID] then
					pauseRetreatChecks[unitID] = true
					retreatRearmOrders[unitID] = nil
				end
			end
		end
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

		pos = {CMD_WANT_CLOAK}, 
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

				pos = {CMD_WANT_CLOAK}, 
			})
		end--if canmove
		
		if foundRetreatable then
			return
		end
	end--for 
end

function widget:SelectionChanged(newSelection)
	if ((havenCount > 0) or (airpadCount>0)) and options.removeFromSelection.value then
		currentSelection = newSelection
	end
end

function widget:UnitDamaged(unitID) 
	local retreatOrder = retreatOrdersArray[unitID]
	
	if ((havenCount > 0) or (airpadCount>0))
		and retreatOrder ~= nil
		and retreatOrder > 0
		and mobileUnits[unitID]
		and not (retreatMoveOrders[unitID] or retreatRearmOrders[unitID] or pauseRetreatChecks[unitID])
	then 
		CheckSetWantRetreat(unitID, retreatOrder)
		
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
				CheckSetWantRetreat(unitID, retreatOrders)
			end
		end -- for
	end --if frame 1/30
	
	--Every 5 seconds, check all unit in case they are heading to a deleted retreat area
	if frame160 then
		for unitID, retreatOrders in pairs(retreatOrdersArray) do
			if retreatMoveOrders[unitID] and not HeadingToHaven(unitID) then
				StopRetreating(unitID) --remove retreat queue and nullify "retreatMoveOrders[unitID]"
			end
		end
	end
	
	--remove retreating unit from selection (only perform at selection change or when retreat is ordered)
	if options.removeFromSelection.value then
		PerformDeselection()
	end
end

function widget:DrawWorld()
	local fade = abs((currentGameFrame % 40) - 20) / 20
  
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