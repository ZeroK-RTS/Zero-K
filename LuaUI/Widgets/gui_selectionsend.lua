-- $Id: gui_selectionhalo.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Selection Send",
    desc      = "Sends IDs of selected units to allies to be used by other widgets.",
    author    = "CarRepairer",
    date      = "2009-4-27",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local selUnitsSend = {}
local timeSinceBroadcast = 0
local BROADCAST_PERIOD = 10
local selchanged = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
end


function widget:Shutdown()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--
-- Speed-ups
--
local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGetSelectedUnits  	= Spring.GetSelectedUnits
local SendLuaUIMsg       	= Spring.SendLuaUIMsg




local function SendSelUnits(selUnitsToSend)
	numSelUnits = #selUnitsToSend
	numSelUnits = numSelUnits < 10 and numSelUnits or 10
	local uStr = '@'
	for i = 1, numSelUnits do
		--Spring.Echo ("pack to", selUnitsToSend[i], VFS.PackU16(selUnitsToSend[i]))
		uStr = uStr .. VFS.PackU16(selUnitsToSend[i])
	end
	SendLuaUIMsg(uStr,"allies")	
end

function CheckSpecState()
	local _, _, spec, _, _, _, _, _ = spGetPlayerInfo(spGetMyPlayerID())
		
	if spec then
		Spring.Echo("<SelectionSend> Spectator mode. Widget removed.")
		widgetHandler:RemoveWidget()
	end
	
	return true	
end


function widget:Update(dt)
	timeSinceBroadcast = timeSinceBroadcast + dt
		
	if timeSinceBroadcast > BROADCAST_PERIOD then
		timeSinceBroadcast = 0
		CheckSpecState()
		SendSelUnits(spGetSelectedUnits())
	elseif timeSinceBroadcast > 1 and selchanged then
		timeSinceBroadcast = 0
		CheckSpecState()
		selchanged = false
		SendSelUnits(spGetSelectedUnits())
	end
	
	
end

function widget:SelectionChanged(selectedUnits)
	selchanged = true
end




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------






