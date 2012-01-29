-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Low Power Icons",
    desc      = "Shows low power icons",
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


local min   = math.min
local floor = math.floor

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------


local myAllyTeamID = 666

local powerTexture = 'Luaui/Images/energy.png'

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function SetLowPowerIcons(unitID)
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		local lowpower = Spring.GetUnitRulesParam(unitID, "lowpower") 
		if lowpower and lowpower ~= 0 then
			WG.icons.SetUnitIcon( unitID, {name='lowpower', texture=powerTexture} )
		else
			WG.icons.SetUnitIcon( unitID, {name='lowpower', texture=nil} )
		end
	end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


function widget:GameFrame(f)
	if f%(32*5) == 0 then --5 seconds
		SetLowPowerIcons()
	end
end


function widget:Initialize()
	WG.icons.SetOrder( 'lowpower', 2 )
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
