--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- UNSYNCED ONLY
if (gadgetHandler:IsSyncedCode()) then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local singleplayer = false
do
	local playerlist = Spring.GetPlayerList() or {}
	if (#playerlist <= 1) then
		singleplayer = true
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name      = "AutoReadyStartpos",
		desc      = "Automatically readies all people after they all pick start positons, replaces default wait screen",
		author    = "Licho",
		date      = "15.4.2012",
		license   = "Nobody can do anything except me, Microsoft and Apple! Thieves hands off",
		layer     = 0,
		enabled   = not (singleplayer and VFS.FileExists("mission.lua"))  --  loaded by default?
	}
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local MAX_TIME_DIFF = 150 -- wait this long for disconnected players

local allReady = false
local startTimer = nil
local readyTimer = nil
local lastLabel = nil
local waitingFor = {}
local isReady = {}

local glPopMatrix      = gl.PopMatrix
local glPushMatrix     = gl.PushMatrix
local glRotate         = gl.Rotate
local glScale          = gl.Scale
local glText           = gl.Text
local glTranslate      = gl.Translate

local forceSent = false

local fixedStartPos = (Spring.GetModOptions().fixedstartpos == "1")

function gadget:Initialize()
	startTimer = Spring.GetTimer()
end

function gadget:GameSetup(label, ready, playerStates)
	lastLabel = label
	local timeDiff = Spring.DiffTimers(Spring.GetTimer(), startTimer)
	local readyCount = 0
	local waitingCount = 0
	local missingCount = 0
	local totalCount = 0
	waitingFor = {}
	local activeAllies = {}
	local totalAllies = {}
		
	for num, state in pairs(playerStates) do
		local name,active,spec,teamID,allyTeamID,ping = Spring.GetPlayerInfo(num, false)
		--Note: BUG, startPosSet returned by GetTeamStartPosition() always return true for Spring 96.0.1-442-g7191625 (game always start immediately)
		-- therefore, a reasonable indicator for placing startPos could be x>0 because 0 is precisely an impossible position to be place by hand.
		-- we might not need to check for -100 anymore IMHO.
		local x,y,z,startPosSet = Spring.GetTeamStartPosition(teamID)
		local _,_,_,isAI = Spring.GetTeamInfo(teamID, false)
		startPosSet = x and x > 0
	
		if not spec and not isAI then
			totalCount = totalCount + 1
			if not active then
				missingCount = missingCount + 1
				waitingFor[name] = "missing"
			else
				if state == "ready" or startPosSet then
					readyCount = readyCount + 1
					if isReady[name] == nil then
						isReady[name] = true
						Spring.SendCommands("wbynum 255 SPRINGIE:READY:".. name)
					end
				else
					waitingCount = waitingCount + 1
					waitingFor[name] = "notready"
				end
				activeAllies[allyTeamID] = true
			end
			totalAllies[allyTeamID] = true
		end
	end
	
	local numActiveAllies, numTotalAllies = 0, 0
	for i in pairs(activeAllies) do
		numActiveAllies = numActiveAllies + 1
	end
	for i in pairs(totalAllies) do
		numTotalAllies = numTotalAllies + 1
	end
	local enoughAlliesActive = (numTotalAllies == 1) or (numActiveAllies > 1)
	
	if ( ( (timeDiff > MAX_TIME_DIFF) and enoughAlliesActive ) or missingCount == 0) and readyCount > 0 and waitingCount ==0 then
		if (readyTimer == nil) then
			readyTimer = Spring.GetTimer()
		end
	end
	
	if (readyTimer ~= nil and Spring.DiffTimers(Spring.GetTimer(), readyTimer) > 4) then
		if not forceSent then
			Spring.SendCommands("wbynum 255 SPRINGIE:FORCE")
			forceSent = true
		end
		return true, true
	end
	
	return true, false
end

local function GetStartText()
	if Spring.GetGameRulesParam("totalSaveGameFrame") then
		return "Loading game..."
	end
	
	local text = lastLabel
	if text == nil then
		text = "Waiting for people "
	end
	
	if (next(waitingFor) ~= nil) then
		if singleplayer then
			text = "\255\255\255\255Choose start position"
		else
			text = text .. "\n\255\255\255\255Waiting for "
			
			local cnt = 0
			for name, state in pairs(waitingFor) do
				if cnt % 6 == 5 then
					text = text .. "\n"
				end
				cnt = cnt + 1
				if state == "missing" then
					text = text .. "\255\255\0\0"
				else
					text = text .. "\255\255\255\0"
				end
				text = text .. name .. ", "
			end
			text = text .. "\n\255\255\255\255 Say !force to start sooner"
		end
	elseif string.find(text, "Choose") then
		return "\255\255\255\255Starting"
	end
	return text
end

function gadget:DrawScreen()
	if fixedStartPos then
		return
	end
	local vsx, vsy = gl.GetViewSizes()

	glPushMatrix()
	glTranslate((vsx * 0.5), (vsy * 0.5) + 150, 0)
	glScale(1.5, 1.5, 1)
	glText(GetStartText(), 0, 0, 14, "oc")
	glPopMatrix()
end

function gadget:Update()
	if (Spring.GetGameFrame() > 1) then
		gadgetHandler:RemoveGadget()
	end
end
