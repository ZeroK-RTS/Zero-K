--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Disable /take",
    desc      = "Disable /take of AI's unit or inactive team's unit unless /cheat is enabled", 
    author    = "xponen",
    date      = "21 January 2015",
    license   = "ZK's default license",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

local spIsCheatingEnabled = Spring.IsCheatingEnabled
local spGetPlayerInfo     = Spring.GetPlayerInfo
local spGetTeamInfo       = Spring.GetTeamInfo
local spGetUnitTeam       = Spring.GetUnitTeam
local spTransferUnit      = Spring.TransferUnit
local spSendLuaRulesMsg   = Spring.SendLuaRulesMsg


function gadget:RecvSkirmishAIMessage(aiTeam, dataStr)
	-- usage: callback.getLua().callRules("ai_give_unit|" + u.getUnitId() + "|" + team, -1);
	
	local dataSplit = {}
	for str in dataStr:gmatch("(([^\|]+))") do  
		dataSplit[#dataSplit + 1] = str
	end 
	local command = dataSplit[1]
	local unitID = tonumber(dataSplit[2])
	local trgTeam = tonumber(dataSplit[3])
	
	if command == "ai_give_unit" and unitID ~= nil and trgTeam ~= nil and spGetUnitTeam(unitID) == aiTeam then	
		
		local _,_,_,_,_,allyTeamSource = spGetTeamInfo(aiTeam)
		local _,_,_,_,_,allyTeamTarget = spGetTeamInfo(trgTeam)
		if (allyTeamSource == allyTeamTarget) then
			spSendLuaRulesMsg(command..'|'..unitID..'|'..trgTeam..'|'..aiTeam);
		end
	end
end	



function gadget:RecvLuaMsg(msg, playerID)
	local dataSplit = {}
	for str in msg:gmatch("(([^\|]+))") do  
		dataSplit[#dataSplit + 1] = str
	end 
	local command = dataSplit[1]
	local unitID = tonumber(dataSplit[2])
	local trgTeam = tonumber(dataSplit[3])
	local srcTeam = tonumber(dataSplit[4])
	
	if command == "ai_give_unit" and unitID ~= nil and trgTeam ~= nil and srcTeam ~= nil and spGetUnitTeam(unitID) == srcTeam then	
		
		local _,_,_,isAI,_,allyTeamSource = spGetTeamInfo(srcTeam)
		local _,_,_,_,_,allyTeamTarget = spGetTeamInfo(trgTeam)
		local _,_,aiHost = Spring.GetAIInfo(srcTeam)
		if (allyTeamSource == allyTeamTarget and isAI and aiHost == playerID) then
			GG.allowTransfer = true
			spTransferUnit(unitID, trgTeam)
			GG.allowTransfer = false
		end
	end
end

GG.allowTransfer = false
function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
	--NOTE: this gadget don't block unit transfer to enemy (which is an Engine setting).
	if capture or GG.allowTransfer or spIsCheatingEnabled() then --ALLOW transfer when capturing unit, or when superuser asked it, or when gadget requested it
		return true 
	end
	local _,leaderID,isDead,isAI = spGetTeamInfo(oldTeam)
	if isAI or isDead then --DISALLOW /take of AI or dead player
		return false
	end
	local _, active, spectator = spGetPlayerInfo(leaderID)
	if (spectator or not active) then --DISALLOW /take of resigned or afk player
		return false
	end
	return true --ALLOW transfer for all other case (eg: player to player)
end
