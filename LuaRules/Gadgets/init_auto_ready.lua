function gadget:GetInfo()
  return {
    name      = "AutoReadyStartpos",
    desc      = "Automatically readies all people after they all pick start positons",
    author    = "Licho",
    date      = "15.4.2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

if (not gadgetHandler:IsSyncedCode()) then

local allReady = false 
local startTimer = nil

function gadget:Initialize() 
	startTimer = Spring.GetTimer()
end 

function gadget:GameSetup(state, label, playerStates)
	local timeDiff = Spring.DiffTimers(Spring.GetTimer(), startTimer)
	if (timeDiff >=15) then
		local okCount = 0
		local allOK = true 
	
		for num, state in pairs(playerStates) do 
			local name,active,spec, teamID,_,ping = Spring.GetPlayerInfo(num)
			local x,y,z = Spring.GetTeamStartPosition(teamID)
			local _,_,_,isAI,_,_ = Spring.GetTeamInfo(teamID)
			local startPosSet = x ~= nil and x~= -100 and y ~= -100 and z~=-100
			
			if active and not spec and not isAI then 
				if state == "ready" or startPosSet then
					okCount = okCount + 1
				else
					allOK = false 
					break 
				end 
			end 
			
		end 
		
		if okCount > 0 and allOK then
			--Spring.Echo("All present people set start position, starting game!")
			return true, true	
		end 
	end 
end



end 