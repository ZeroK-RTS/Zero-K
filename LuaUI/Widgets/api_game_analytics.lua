--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Game Analytics Handler",
		desc      = "Handles game analytics events",
		author    = "GoogleFrog",
		date      = "20 February 2017",
		license   = "GPL-v2",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config/Globals

local spGetTimer = Spring.GetTimer
local spDiffTimers = Spring.DiffTimers

local gameTimer
local myTeamID

local ANALYTICS_EVENT = "analyticsEvent_"
local ANALYTICS_EVENT_ERROR = "analyticsEventError_"

local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local Analytics = {}

function Analytics.SendOnetimeEvent(eventName, value)
	if not luaMenu then
		return
	end
	
	if value then
		Spring.SendLuaMenuMsg(ANALYTICS_EVENT .. eventName .. "|" .. value)
	else
		Spring.SendLuaMenuMsg(ANALYTICS_EVENT .. eventName)
	end
end

function Analytics.SendErrorEvent(eventName, severity)
	if not luaMenu then
		return
	end
end

function Analytics.SendOnetimeEventWithTime(eventName)
	Analytics.SendOnetimeEvent(eventName, (gameTimer and spDiffTimers(spGetTimer(), gameTimer)) or 0)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Analytics collectors

local loadSent = false
local startposSent = false

function widget:Update(dt)
	if not gameTimer then
		gameTimer = spGetTimer()
	end
	
	if not loadSent then
		local spectating = Spring.GetSpectatingState()
		loadSent = true
		
		if spectating then
			Analytics.SendOnetimeEvent("game:loaded_spectator")
			widgetHandler:RemoveCallIn("Update")
			return
		else
			Analytics.SendOnetimeEvent("game:loaded_player")
		end
	end
	myTeamID = Spring.GetMyTeamID()
	
	if not startposSent then
		local x,y,z = Spring.GetTeamStartPosition(myTeamID)
		if x then
			startposSent = true
			Analytics.SendOnetimeEventWithTime("game:startpoint_placed")
		end
	end
end

function widget:GameStart()
	Analytics.SendOnetimeEventWithTime("game:start_game_propper")
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if unitTeam ~= myTeamID then
		return
	end
	local ud = unitDefID and UnitDefs[unitDefID]
	if not ud then
		return
	end
	
	if builderID then
		-- Only trigger for build units. Not capture, share, Claw, commander spawn etc..
		Analytics.SendOnetimeEventWithTime("game:unit:first_built:" .. ud.name)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize() 
	WG.Analytics = Analytics
	Analytics.SendOnetimeEvent("game:begin_load")
end
