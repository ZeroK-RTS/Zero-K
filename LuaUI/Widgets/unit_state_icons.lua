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

local REVERSE_COMPAT = not Script.IsEngineMinVersion(104, 0, 1121)

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

-- Visibility of these state icons is now owned by the Unit Overlay GL4 widget's "Unit States"
-- options (the single source of truth). This widget only computes the current state and pushes
-- the icon data through WG.icons; the overlay decides what is shown via WG.icons.SetDisplay.

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
	
	do
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

	do
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

	do
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

	do
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

-- todo: intercept state change and (un-)armoring events, and get rid of polling altogether
function widget:GameFrame(f)

	if f%(30) == 0 then --1 second
		UpdateAllUnits()
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	-- this won't handle priority for some reason, so that should be intercepted right in the widgets giving the order
	if (cmdID == CMD.MOVE_STATE) or (cmdID == CMD.FIRE_STATE) then
		SetUnitStateIcons(unitID)
	end
end

function widget:Initialize()

	WG.icons.SetOrder( 'firestate', 5 )
	WG.icons.SetOrder( 'movestate', 6 )

	UpdateAllUnits()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
