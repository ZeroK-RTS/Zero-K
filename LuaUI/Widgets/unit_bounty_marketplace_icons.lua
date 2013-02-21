-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Bounty & Marketplace Icons",
    desc      = "Shows bounty and marketplace icons",
    author    = "CarRepairer",
	version   = "0.021",
    date      = "2012-01-28",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = false,
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local echo = Spring.Echo

local GetAllUnits          = Spring.GetAllUnits

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
	
}


include("keysym.h.lua")
local iconTypes = { 'bounty', 'buy', 'sell' }
local teamList = {}
local teamColors = {}
local myAllyTeamID = 666

local imageDir = 'LuaUI/Images/bountymarketplaceicons/'

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function SetIcons(unitID, iconType)
	--for _, teamID in ipairs(Spring.GetTeamList()) do
	for i = 1, #teamList do
		local teamID = teamList[i]
		local price = Spring.GetUnitRulesParam( unitID, iconType .. teamID )
		
		if price and price > 0 then
			local icon = imageDir .. iconType.. price ..'.png'
			if not VFS.FileExists(icon) then
				icon = imageDir .. iconType .. 'notfound.png'
			end
					
			local teamColor = teamColors[teamID] or {1,1,1,1}
			WG.icons.SetUnitIcon( unitID, {name=iconType..teamID, texture=icon, color=teamColor } )
		else
			WG.icons.SetUnitIcon( unitID, {name=iconType..teamID, texture=nil } )
		end
	end
	
end

local function UpdateAllUnits()
	teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		teamColors[teamID] = {Spring.GetTeamColor(teamID)}
	end
	
	for _,unitID in pairs( GetAllUnits() ) do
		for _,iconType in ipairs( iconTypes ) do
			SetIcons(unitID, iconType )
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


function widget:UnitCreated(unitID, unitDefID, unitTeam)
	SetIcons(unitID)
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	
	for _,iconType in ipairs( iconTypes ) do
		for _, teamID in ipairs(Spring.GetTeamList()) do
			WG.icons.SetUnitIcon( unitID, {name=iconType.. teamID, texture=nil} )
		end
	end
end

--needed if icon widget gets disabled/enabled after this one. find a better way?
function widget:GameFrame(f)
	if f%(32) == 0 then --1 second
		UpdateAllUnits()
	end
end


function widget:Initialize()
	for _, teamID in ipairs(Spring.GetTeamList()) do
		WG.icons.SetOrder( 'bounty'..teamID, 9+teamID )
		WG.icons.SetDisplay('bounty'..teamID, true)
		
		WG.icons.SetOrder( 'sell'..teamID, 10+teamID )
		WG.icons.SetDisplay('bounty'..teamID, true)
		
		WG.icons.SetOrder( 'sell'..teamID, 11+teamID )
		WG.icons.SetDisplay('bounty'..teamID, true)	
	
	end
	
	UpdateAllUnits()
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
