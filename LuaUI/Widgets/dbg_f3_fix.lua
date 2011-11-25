-- $Id: dbg_dcicon.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "F3 fix",
    desc      = "Workaround for F3 key",
    author    = "KingRaptor",
    date      = "Oct 02, 2007",
    license   = "Public Domain",
    layer     = -10000,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local NUM_EVENTS = 4
local lastEvents = {
}
local num = 1

function GoToLastEvent()
	local event = lastEvents[num]
	if not event then return end
	Spring.SetCameraTarget(event[1], event[2], event[3],1)
	num = num + 1
	if num > #lastEvents then num = 1 end
end

local function AddEventPos(px, py, pz)
	table.insert(lastEvents, 1, {px, py, pz})
	if lastEvents[NUM_EVENTS + 1] then lastEvents[NUM_EVENTS + 1] = nil end
	num = 1
end
WG.AddEventPos = AddEventPos

function widget:MapDrawCmd(playerID, cmdType, px, py, pz, caption)
	if (cmdType == 'point') then
		widget:AddMapPoint(playerID,caption, px,py,pz)
	end
end

function widget:AddMapPoint(player, caption, px, py, pz)
	AddEventPos(px, py, pz)
end

function widget:Initialize()
	widgetHandler:AddAction("gotoevent", GoToLastEvent, nil, "t")	
	Spring.SendCommands("unbindkeyset Any+f3")
	Spring.SendCommands("bind Any+f3 gotoevent")
end

function widget:Shutdown()
	widgetHandler:RemoveAction("gotoevent")
	Spring.SendCommands("unbindkeyset Any+f3")
	Spring.SendCommands("bind Any+f3 LastMsgPos")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------