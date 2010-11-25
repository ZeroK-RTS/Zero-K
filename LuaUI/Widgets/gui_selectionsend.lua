--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Selection Send",
    desc      = "v0.02 Sends and Receives IDs of selected units to allies to be used by other widgets.",
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

local allySelData = {}
local allyActiveTx = {}
WG.allySelUnits = {}

local echo = Spring.Echo
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	WG.allySelUnits = {}
end


function widget:Shutdown()
	WG.allySelUnits = {}
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

local function IsSpec()
	local _, _, spec, _, _, _, _, _ = spGetPlayerInfo(spGetMyPlayerID())
	return spec
	--[[
	if spec then
		Spring.Echo("<SelectionSend> Spectator mode. Widget removed.")
		widgetHandler:RemoveWidget()
	end
	--]]
end


local function SendSelUnits(selUnitsToSend)
	if IsSpec() then return end
	
	numSelUnits = #selUnitsToSend
	numSelUnits = numSelUnits < 10 and numSelUnits or 10
	local uStr = '@'
	for i = 1, numSelUnits do
		--Spring.Echo ("pack to", selUnitsToSend[i], VFS.PackU16(selUnitsToSend[i]))
		uStr = uStr .. VFS.PackU16(selUnitsToSend[i])
	end
	SendLuaUIMsg(uStr,"allies")	
end


local function UpdateAllySelUnits()
	local allSelStr = ''
	for pid,dataStr in pairs(allySelData) do
		allSelStr = allSelStr .. dataStr
	end

	local allySelUnits2 = {}
	local num_units = allSelStr:len() / 2
	for i = 1, num_units do
		local code = allSelStr:sub(i*2-1,i*2)
		--allySelUnits2[i] = VFS.UnpackU16(code)
		allySelUnits2[VFS.UnpackU16(code)] = true
		--Spring.Echo (i, "unpack to", code, VFS.UnpackU16(code))
	end
	WG.allySelUnits = allySelUnits2
end	

function widget:Update(dt)
	timeSinceBroadcast = timeSinceBroadcast + dt
		
	if timeSinceBroadcast > BROADCAST_PERIOD then
		timeSinceBroadcast = 0
		
		SendSelUnits(spGetSelectedUnits())
		
		for pid,dataStr in pairs(allySelData) do
			allyActiveTx[pid] = allyActiveTx[pid] - 1
		end
		if allyActiveTx[pid] == 0 then
			allySelData[playerID] = nil
		end	
		
	elseif timeSinceBroadcast > 1 and selchanged then
		timeSinceBroadcast = 0
		selchanged = false
		SendSelUnits(spGetSelectedUnits())
	end
	
	
end

function widget:SelectionChanged(selectedUnits)
	selchanged = true
end


function widget:RecvLuaMsg(msg, playerID)
	if (msg:sub(1,1)=="@") then
		local _, _, spec = spGetPlayerInfo(playerID)
		if spec or (playerID==Spring.GetMyPlayerID()) then return true; end
		if msg == '@' then
			allySelData[playerID] = ''
		else
			allySelData[playerID] = msg:sub(2)
		end
		allyActiveTx[playerID] = 2
		
		UpdateAllySelUnits()
	end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------






