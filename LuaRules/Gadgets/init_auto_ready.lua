function gadget:GetInfo()
  return {
    name      = "AutoReadyStartpos",
    desc      = "Automatically readies all people after they all pick start positons, replaces default wait screen",
    author    = "Licho",
    date      = "15.4.2012",
    license   = "Nobody can do anything except me, Microsoft and Apple! Thieves hands off",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end


if (not gadgetHandler:IsSyncedCode()) then

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



function gadget:Initialize() 
	startTimer = Spring.GetTimer()
end 

function gadget:GameSetup(label, ready, playerStates)
	lastLabel = label 
	local timeDiff = Spring.DiffTimers(Spring.GetTimer(), startTimer)
	local okCount = 0
	local allOK = true 
	waitingFor = {}
		
	for num, state in pairs(playerStates) do 
		local name,active,spec, teamID,_,ping = Spring.GetPlayerInfo(num)
		local x,y,z = Spring.GetTeamStartPosition(teamID)
		local _,_,_,isAI,_,_ = Spring.GetTeamInfo(teamID)
		local startPosSet = x ~= nil and x~= -100 and y ~= -100 and z~=-100
	
		if not spec and not isAI then 
			if not active then 
				waitingFor[name] = "missing"
			else 
				if state == "ready" or startPosSet then
					okCount = okCount + 1
					if isReady[name] == nil then 
						isReady[name] = true 
						Spring.SendCommands("wbynum 255 SPRINGIE:READY:".. name)
					end 
				else
					allOK = false 
					waitingFor[name] = "notready"
				end 
			end 
		end 
	end 
		
	if timeDiff > 15 and okCount > 0 and allOK then
		if (readyTimer == nil) then 
			readyTimer = Spring.GetTimer()	
		end 
	end 
	
	if (readyTimer ~= nil and Spring.DiffTimers(Spring.GetTimer(), readyTimer) > 4) then 
		return true, true	
	end 
	
	return true, false
end

function gadget:DrawScreen() 
	local vsx, vsy = gl.GetViewSizes()
	local text = lastLabel 
	if text == nil then 
		text = "Waiting for people "
	end 
	local cnt = 0 
	if (next(waitingFor) ~= nil) then 
		if cnt % 6 == 5 then 
			text = text .. "\n"
		end
		cnt = cnt + 1
		text = text .. "\n\255\255\255\255Waiting for "
		for name, state in pairs(waitingFor) do 
			if state == "missing" then 
				text = text .. "\255\255\0\0"
			else
				text = text .. "\255\255\255\0"
			end 
			text = text .. name .. ", "
		end 
		text = text .. "\n\255\255\255\255 Say !force to start sooner"
	end 

    glPushMatrix()
    glTranslate((vsx * 0.5), (vsy * 0.5)+150, 0)
    glScale(1.5, 1.5, 1)
    glText(text, 0, 0, 14, "oc")
    glPopMatrix()
end 

function gadget:Update() 
	if (Spring.GetGameFrame() > 1) then 
		gadgetHandler:RemoveGadget()
	end 
end 


end 