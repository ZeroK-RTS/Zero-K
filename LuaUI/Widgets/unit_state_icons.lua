-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "State Icons",
    desc      = "Shows move and fire state icons",
    author    = "CarRepairer and GoogleFrog",
    date      = "2012-01-28, Oct 31",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true,
	handler = true,--allow widget to use special widgetHandler's function
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

options_path = 'Settings/Interface/Hovering Icons'
options = {
	
	showstateonshift = {
		name = "Show move/fire states on shift",
		desc = "When holding shift, icons appear over units indicating move state and fire state.",
		type = 'bool',
		value = false,
	},
	showarmorstateonshift = {
		name = "Show armor state on shift",
		desc = "When holding shift, an icon appears over armored units.",
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

local armoredTexture = 'Luaui/Images/commands/guard.png'

local hide = true

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local prevFirestate = {}
local prevMovestate = {}
local lastArmored = {}

function SetUnitStateIcons(unitID)
	if not (IsUnitAllied(unitID)or(GetSpectatingState())) then
		return
	end
	
	local states = Spring.GetUnitStates(unitID)
	
	if not states then return end
	
	local ud = Spring.GetUnitDefID(unitID)
	
	if options.showstateonshift.value then
		if ud then
			ud = UnitDefs[ud]
			if ud then
				if ud.canAttack or ud.isFactory then
					if not prevFirestate[unitID] or prevFirestate[unitID] ~= states.firestate then
						prevFirestate[unitID] = states.firestate
						local fireStateIcon = fireStateIcons[states.firestate]
						WG.icons.SetUnitIcon( unitID, {name='firestate', texture=fireStateIcon} )
					end
				end
				if (ud.canMove or ud.canPatrol) and ((not ud.isBuilding) or ud.isFactory) then
					if not prevMovestate[unitID] or prevMovestate[unitID] ~= states.movestate then
						prevMovestate[unitID] = states.movestate
						local moveStateIcon = moveStateIcons[states.movestate]
						WG.icons.SetUnitIcon( unitID, {name='movestate', texture=moveStateIcon} )
					end
				end
			end
		end
	end
	
	if options.showarmorstateonshift.value then
		local armored, amount = Spring.GetUnitArmored(unitID)
		armored = armored and amount and amount ~= 1
		if not lastArmored[unitID] and armored then
			lastArmored[unitID] = true
			WG.icons.SetUnitIcon( unitID, {name='armored', texture=armoredTexture} )
		elseif lastArmored[unitID] and not armored then
			lastArmored[unitID] = nil
			WG.icons.SetUnitIcon( unitID, {name='armored', texture=nil} )
		end
	end
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
	if isRepeat or not (options.showstateonshift.value or options.showarmorstateonshift.value) then
		return
	end

	if key == KEYSYMS.LSHIFT
		or key == KEYSYMS.RSHIFT
		then
		
		hide = false
		
		if options.showstateonshift.value then
			WG.icons.SetDisplay('firestate', true)
			WG.icons.SetDisplay('movestate', true)
		end
		if options.showarmorstateonshift.value then
			WG.icons.SetDisplay('armored', true)
		end
		
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
		WG.icons.SetDisplay('armored', false)
	end
end

--[[
--needed if icon widget gets disabled/enabled after this one. find a better way?
function widget:GameFrame(f)

	if f%(32) == 0 then --1 second
		UpdateAllUnits()
	end
end
--]]


--this needs work
function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOptions, cmdParams)
	if hide then return end
	if (cmdID == CMD.MOVE_STATE) or (cmdID == CMD.FIRE_STATE)  then
		SetUnitStateIcons(unitID)
	end
end

function widget:Initialize()
	if (not WG.icons) or (#WG.icons==0) then --if "Unit Icons" not enabled, then enable it.
		widgetHandler:EnableWidget("Unit Icons")
	end
	
	WG.icons.SetOrder( 'firestate', 5 )
	WG.icons.SetOrder( 'firestate', 6 )
	WG.icons.SetDisplay('firestate', false)
	WG.icons.SetDisplay('movestate', false)
	
	UpdateAllUnits()
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
