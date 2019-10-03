-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "State Icons",
    desc      = "Shows movestate, firestate and priority icons",
    author    = "CarRepairer and GoogleFrog",
	version   = "0.02",
    date      = "2012-01-28",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true,
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local REVERSE_COMPAT = not Spring.Utilities.IsCurrentVersionNewerThan(104, 1120)

local spGetUnitArmored       = Spring.GetUnitArmored
local spGetUnitRulesParam    = Spring.GetUnitRulesParam
local spGetUnitHealth        = Spring.GetUnitHealth
local spGetUnitStates        = Spring.GetUnitStates
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetAllUnits          = Spring.GetAllUnits
local spIsUnitAllied         = Spring.IsUnitAllied
local spGetSpectatingState   = Spring.GetSpectatingState

local min   = math.min
local floor = math.floor

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

options_path = 'Settings/Interface/Hovering Icons'
options = {
	
	showstateonshift = {
		name = "Show move/fire states on shift",
		desc = "When holding shift, icons appear over units indicating move state and fire state.",
		type = 'bool',
		value = false,
		noHotkey = true,
	},
	showarmorstate = {
		name = 'Armor state visibility',
		desc = "When to show an icon for armored units.",
		type = 'radioButton',
		value = 'shift',
		items = {
			{key ='always', name='Always'},
			{key ='shift',  name='When holding Shift'},
			{key ='never',  name='Never'},
			-- an option to show armor on enemies would be good. Gadget assumes units are own so would need some rewriting.
		},
		OnChange = function (this)
			if this.value == 'always' then
				WG.icons.SetDisplay('armored', true)
			else
				WG.icons.SetDisplay('armored', false)
			end
		end,
		noHotkey = true,
	},

	showpriority = {
		name = "Priority state visibility",
		desc = "When to show an icon for prioritized units.",
		type = 'bool',
		type = 'radioButton',
		value = 'shift',
		items = {
			{key ='always', name='Always'},
			{key ='shift',  name='When holding Shift'},
			{key ='never',  name='Never'},
		},
		OnChange = function (this)
			if this.value == 'always' then
				WG.icons.SetDisplay('priority', true)
			else
				WG.icons.SetDisplay('priority', false)
			end
		end,
		noHotkey = true,
	},
	showmiscpriorityonshift = {
		name = "Show misc priorty on shift",
		desc = "When holding shift, an icon appears over unit with low or high misc priority (morph or stockpile).",
		type = 'bool',
		value = true,
		noHotkey = true,
	},
}

include("keysym.h.lua")

local imageDir = 'LuaUI/Images/commands/'
local fireStateIcons = {
  [0] = imageDir .. 'states/fire_hold.png',
  [1] = imageDir .. 'states/fire_return.png',
  [2] = imageDir .. 'states/fire_atwill.png',
}
local moveStateIcons = {
  [0] = imageDir .. 'states/move_hold.png',
  [1] = imageDir .. 'states/move_engage.png',
  [2] = imageDir .. 'states/move_roam.png',
}
local priorityIcons = {
  [0] = imageDir .. 'states/wrench_low.png',
  [1] = imageDir .. 'states/wrench_med.png',
  [2] = imageDir .. 'states/wrench_high.png',
}
local miscPriorityIcons = {
  [0] = imageDir .. 'states/wrench_low_other.png',
  [1] = imageDir .. 'states/wrench_med_other.png',
  [2] = imageDir .. 'states/wrench_high_other.png',
}

local armoredTexture = 'Luaui/Images/commands/guard.png'

local hide = true

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local prevFirestate = {}
local prevMovestate = {}
local prevPriority = {}
local prevMiscPriority = {}
local lastArmored = {}

function SetUnitStateIcons(unitID)
	if not (spIsUnitAllied(unitID)or(spGetSpectatingState())) then
		return
	end
	local unitDefID = spGetUnitDefID(unitID)
	local ud = unitDefID and UnitDefs[unitDefID]
	
	if not ud then
		return
	end
	
	if options.showstateonshift.value then
		local firestate, movestate
		if REVERSE_COMPAT then
			local states = spGetUnitStates(unitID)
			if states then
				firestate, movestate = states.firestate, states.movestate
			end
		else
			firestate, movestate = spGetUnitStates(unitID, false)
		end
		if ud.canAttack or ud.isFactory then
			if not prevFirestate[unitID] or prevFirestate[unitID] ~= firestate then
				prevFirestate[unitID] = firestate
				local fireStateIcon = fireStateIcons[firestate]
				WG.icons.SetUnitIcon( unitID, {name='firestate', texture=fireStateIcon} )
			end
		end
		if (ud.canMove or ud.canPatrol) and ((not ud.isBuilding) or ud.isFactory) then
			if not prevMovestate[unitID] or prevMovestate[unitID] ~= movestate then
				prevMovestate[unitID] = movestate
				local moveStateIcon = moveStateIcons[movestate]
				WG.icons.SetUnitIcon( unitID, {name='movestate', texture=moveStateIcon} )
			end
		end
	end

	if options.showarmorstate.value ~= "never" then
		local armored, amount = spGetUnitArmored(unitID)
		armored = armored and amount and amount ~= 1
		if not lastArmored[unitID] and armored then
			lastArmored[unitID] = true
			WG.icons.SetUnitIcon( unitID, {name='armored', texture=armoredTexture} )
		elseif lastArmored[unitID] and not armored then
			lastArmored[unitID] = nil
			WG.icons.SetUnitIcon( unitID, {name='armored', texture=nil} )
		end
	end

	if options.showpriority.value ~= "never" then
		local state = spGetUnitRulesParam(unitID, "buildpriority")
		if (not ud) or not (ud.canAssist and ud.buildSpeed ~= 0) then
			local _,_,_,_,buildProgress = spGetUnitHealth(unitID)
			if buildProgress == 1 then
				state = 1
			end
		end
		
		if not prevPriority[unitID] or prevPriority[unitID] ~= state then
			if state == 1 then
				prevPriority[unitID] = state
				WG.icons.SetUnitIcon( unitID, {name='priority', texture=nil} )
			else
				prevPriority[unitID] = state
				local priorityIcons = priorityIcons[state]
				WG.icons.SetUnitIcon( unitID, {name='priority', texture=priorityIcons} )
			end
		end
	end
	
	if options.showmiscpriorityonshift.value then
		local state = spGetUnitRulesParam(unitID, "miscpriority")
		
		if not prevMiscPriority[unitID] or prevMiscPriority[unitID] ~= state then
			if state == 1 then
				prevMiscPriority[unitID] = state
				WG.icons.SetUnitIcon( unitID, {name='miscpriority', texture=nil} )
			else
				prevMiscPriority[unitID] = state
				local miscPriorityIcons = miscPriorityIcons[state]
				WG.icons.SetUnitIcon( unitID, {name='miscpriority', texture=miscPriorityIcons} )
			end
		end
	end
end

local function UpdateAllUnits()
	if hide and not ((options.showpriority.value == "always") or (options.showarmorstate.value == "always")) then
		return
	end
	local unitID
	local units = spGetAllUnits()
	for i = 1, #units do
		unitID = units[i]
		SetUnitStateIcons(unitID)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	SetUnitStateIcons(unitID)
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	-- There should be a better way to do this, lazy fix.
	WG.icons.SetUnitIcon( unitID, {name='firestate', texture=nil} )
	WG.icons.SetUnitIcon( unitID, {name='movestate', texture=nil} )
	WG.icons.SetUnitIcon( unitID, {name='armored', texture=nil} )
	WG.icons.SetUnitIcon( unitID, {name='priority', texture=nil} )
	WG.icons.SetUnitIcon( unitID, {name='miscpriority', texture=nil} )
end

function widget:KeyPress(key, modifier, isRepeat)
	if isRepeat then
		return
	end

	if key == KEYSYMS.LSHIFT or key == KEYSYMS.RSHIFT then
		hide = false
		
		if options.showstateonshift.value then
			WG.icons.SetDisplay('firestate', true)
			WG.icons.SetDisplay('movestate', true)
		end
		if options.showarmorstate.value == "shift" then
			WG.icons.SetDisplay('armored', true)
		end
		if options.showpriority.value == "shift" then
			WG.icons.SetDisplay('priority', true)
		end
		if options.showmiscpriorityonshift.value then
			WG.icons.SetDisplay('miscpriority', true)
		end
		
		UpdateAllUnits()
	end
end
function widget:KeyRelease(key, modifier )
	if key == KEYSYMS.LSHIFT or key == KEYSYMS.RSHIFT then
		hide = true
		
		WG.icons.SetDisplay('firestate', false)
		WG.icons.SetDisplay('movestate', false)

		if options.showarmorstate.value == "shift" then
			WG.icons.SetDisplay('armored', false)
		end
		if options.showpriority.value == "shift" then
			WG.icons.SetDisplay('priority', false)
		end

		WG.icons.SetDisplay('miscpriority', false)
	end
end


-- todo: intercept state change and (un-)armoring events, and get rid of polling altogether
function widget:GameFrame(f)

	if f%(30) == 0 then --1 second
		UpdateAllUnits()
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	-- this won't handle priority for some reason, so that should be intercepted right in the widgets giving the order
	if (not hide) and ((cmdID == CMD.MOVE_STATE) or (cmdID == CMD.FIRE_STATE)) then
		SetUnitStateIcons(unitID)
	end
end

function widget:Initialize()
	
	WG.icons.SetOrder( 'firestate', 5 )
	WG.icons.SetOrder( 'movestate', 6 )
	WG.icons.SetDisplay('firestate', false)
	WG.icons.SetDisplay('movestate', false)
	
	UpdateAllUnits()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
