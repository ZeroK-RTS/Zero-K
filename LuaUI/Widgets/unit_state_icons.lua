-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "State Icons",
    desc      = "Shows move and fire state icons",
    author    = "CarRepairer",
    date      = "2012-01-28",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true,
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local echo = Spring.Echo

local GetUnitDefID         = Spring.GetUnitDefID
local GetUnitExperience    = Spring.GetUnitExperience
local GetAllUnits          = Spring.GetAllUnits
local IsUnitAllied         = Spring.IsUnitAllied
local GetSpectatingState   = Spring.GetSpectatingState

local min   = math.min
local floor = math.floor

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

options_path = 'Game/Settings'
options = {
	
	showstateonshift = {
		name = "Show move/fire states on shift",
		desc = "When holding shift, icons appear over units indicating move state and fire state.",
		type = 'bool',
		value = true,
	},
}


include("keysym.h.lua")

local myAllyTeamID = 666


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

local hide = true

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function SetUnitStateIcons(unitID)
	if not (IsUnitAllied(unitID)or(GetSpectatingState())) then
		return
	end
	
	local states = Spring.GetUnitStates(unitID)
	
	if not states then return end
	local fireStateIcon = fireStateIcons[states.firestate]
	local moveStateIcon = moveStateIcons[states.movestate]
	WG.icons.SetUnitIcon( unitID, {name='firestate', texture=fireStateIcon} )
	WG.icons.SetUnitIcon( unitID, {name='movestate', texture=moveStateIcon} )
end

local function UpdateAllUnits()
	if hide then return end
	for _,unitID in pairs( GetAllUnits() ) do
		SetUnitStateIcons(unitID)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


function widget:UnitCreated(unitID, unitDefID, unitTeam)
	SetUnitStateIcons(unitID)
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	WG.icons.SetUnitIcon( unitID, {name='firestate', texture=nil} )
	WG.icons.SetUnitIcon( unitID, {name='movestate', texture=nil} )
end

function widget:KeyPress(key, modifier, isRepeat)
	if isRepeat or not options.showstateonshift.value then
		return
	end
	
	if key == KEYSYMS.LSHIFT
		or key == KEYSYMS.RSHIFT
		then
		
		hide = false
		
		
		WG.icons.SetDisplay('firestate', true)
		WG.icons.SetDisplay('movestate', true)
		
		UpdateAllUnits()
	end
end
function widget:KeyRelease(key, modifier )
	
	if key == KEYSYMS.LSHIFT
		or key == KEYSYMS.RSHIFT
		then
		
		hide = true
		
		WG.icons.SetDisplay('firestate', false)
		WG.icons.SetDisplay('movestate', false)
	end
end


--needed if icon widget gets disabled/enabled after this one. find a better way?
function widget:GameFrame(f)

	if f%(32*5) == 0 then --5 seconds
		UpdateAllUnits()
	end
end


--this needs work
function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOptions, cmdParams)
	if hide then return end
	if (cmdID == CMD.MOVE_STATE) or (cmdID == CMD.FIRE_STATE)  then
		SetUnitStateIcons(unitID)
	end
end

function widget:Initialize()
	
	WG.icons.SetOrder( 'firestate', 5 )
	WG.icons.SetOrder( 'firestate', 6 )
	WG.icons.SetDisplay('firestate', false)
	WG.icons.SetDisplay('movestate', false)
	
	UpdateAllUnits()
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
