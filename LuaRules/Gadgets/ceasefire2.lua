function gadget:GetInfo()
  return {
    name      = "Ceasefires2",
    desc      = "Handles reciprocating ceasefires with a voting system.",
    author    = "CarRepairer",
    date      = "2011-06-25",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = false -- loaded by default?
  }
end

local TESTMODE = false
local testOnce = true

if Spring.FixedAllies() then
	return
end

local echo 				= Spring.Echo
local spGetPlayerInfo	= Spring.GetPlayerInfo
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetTeamList		= Spring.GetTeamList
local spAreTeamsAllied	= Spring.AreTeamsAllied
local spGetAllUnits     = Spring.GetAllUnits
local spGetUnitDefID    = Spring.GetUnitDefID

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then 
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitPosition		= Spring.GetUnitPosition
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetTeamUnitCount	= Spring.GetTeamUnitCount
local spInsertUnitCmdDesc	= Spring.InsertUnitCmdDesc
local spGetAllyTeamList		= Spring.GetAllyTeamList
local spSetTeamRulesParam	= Spring.SetTeamRulesParam
local spSetGameRulesParam	= Spring.SetGameRulesParam

local CMD_ATTACK            = CMD.ATTACK

local cfData = {}
local cloakedUnits = {}
local gaiaAlliance, gaiaTeam

include("LuaRules/Configs/customcmds.h.lua")

local nukeDefs = {}
local nukeNames = { 'staticnuke', }

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function SetCeasefireOffered(a1, a2, value)
	--echo('setcfoffer', a1, a2, value)

	spSetGameRulesParam('cf_offer_' .. a1 .. '_' .. a2, value and 1 or 0)
	cfData[a1][a2].ceasefireOffered = value
end
local function SetCeasefire(a1, a2, value)
	--echo('setcf', a1, a2, value)
	spSetGameRulesParam( 'cf_' .. a1 .. '_' .. a2, value and 1 or 0)
	spSetGameRulesParam( 'cf_' .. a2 .. '_' .. a1, value and 1 or 0)
	cfData[a1][a2].ceasefired = value
	cfData[a2][a1].ceasefired = value
end

local function SetVote(a1, a2, teamID, value)
	--echo('setvote', a1, a2, teamID, value)
	cfData[a1][a2].votes[teamID] = value
	spSetTeamRulesParam(teamID, 'cf_vote_' ..a2, value and 1 or 0)
end	


function clearVotes(alliance, enAlliance)
	local teamList = cfData[alliance][enAlliance].votes
	for teamID,_ in pairs(teamList) do
		SetVote(alliance, enAlliance, teamID, false)
		if TESTMODE and alliance == 2 and testOnce then	
			testOnce = false
			SetVote(alliance, enAlliance, teamID, true)
		end
	end
end

function checkOffers()
	for alliance,aData in pairs(cfData) do
		for enAlliance,enData in pairs(aData) do
			--both sides offer, set ceasefire
			if enData.ceasefireOffered and cfData[enAlliance][alliance].ceasefireOffered then
				if not enData.inCF then
					enData.inCF = true
					SetCeasefire(alliance, enAlliance, true)
					SendToUnsynced('ceasefire', alliance, enAlliance, true) --delete
				end
			--one side not offering, break ceasefires if they exist
			else
				if enData.inCF then
					enData.inCF = false
					SetCeasefire(alliance, enAlliance, false)
					clearVotes(alliance, enAlliance)
					SetCeasefireOffered(alliance, enAlliance, false)
					
					SendToUnsynced('ceasefire', alliance, enAlliance, false) --delete
				end
			end
		end
	end
end

function checkVotes()
	for alliance, aData in pairs(cfData) do
		for enAlliance, enData in pairs(aData) do			
			local yesVotes,totalVotes = 0,0
			for teamID, vote in pairs(enData.votes) do
				totalVotes = totalVotes + 1
				if vote then yesVotes = yesVotes + 1 end
			end
			
			--100%
			if yesVotes == totalVotes then 
				SetCeasefireOffered(enAlliance, alliance, true)
			else
				SetCeasefireOffered(enAlliance, alliance, false)
			end
			
		end
	end			
end

function checkAllianceSizes()
	local allianceList = spGetAllyTeamList()
	for _, alliance in ipairs(allianceList) do
		
		local teamList = spGetTeamList(alliance)
		local livingTeam = false
		for _,teamID in ipairs(teamList) do
			local teamNum, leader, isDead = spGetTeamInfo(teamID, false)
			if not isDead then livingTeam = true end
		end
		if not livingTeam then
			cfData[alliance] = nil
			for _, aData in pairs(cfData) do
				aData[alliance] = nil
			end
		end
	end
end

local function distSqr(x1,z1,  x2,z2)
	return (x2-x1)*(x2-x1) + (z2-z1)*(z2-z1)
end

local function checkNukeAttack(unitID, cmdParams)
	local allianceID = spGetUnitAllyTeam(unitID)
	local x,z
	if cmdParams[2] then
		x,z = cmdParams[1],cmdParams[3]
	else
		x,_,z = spGetUnitPosition(cmdParams[1])
	end
	if not x then return false end
	for _, anzData in pairs(antinukeZones) do
		local aData1 = cfData[allianceID][anzData.allianceID]
		if aData1 and aData1.ceasefired then
			local aData2 = cfData[anzData.allianceID][allianceID]
			if distSqr(anzData.x,anzData.z,  x,z) < anzData.range*anzData.range then
				SetCeasefireOffered(allianceID, anzData.allianceID, false)
				SetCeasefireOffered(anzData.allianceID, allianceID, false)
			end
		end
	end
end


local function broadcastNuke(unitID, cmdParams)
	local allianceID = spGetUnitAllyTeam(unitID)
	local teamID = Spring.GetUnitTeam(unitID)
	local x,z
	if cmdParams[2] then
		x,y,z = cmdParams[1],cmdParams[2],cmdParams[3]
	else
		x,y,z = spGetUnitPosition(cmdParams[1])
	end
	if not x then return false end
	
	local luaMsg = 'nukelaunch|' .. allianceID .. '|' .. x .. '|' .. y .. '|' .. z
	CallAsTeam(teamID, function () return Spring.SendLuaUIMsg (luaMsg, 'a' ) end) --sends to allies only?
	
	
end
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:TeamDied(deadTeamID)
	for alliance, aData in pairs(cfData) do
		for enAlliance, enData in pairs(aData) do
			--echo('++++++++++ CF ++ team died', deadTeamID)
			enData.votes[deadTeamID] = nil
		end
	end
	checkAllianceSizes()
end

function gadget:RecvLuaMsg(msg, playerID)
	--echo('recv',msg, playerID)
	local msg_table = Spring.Utilities.ExplodeString(':', msg)
	if msg_table[1] ~= 'ceasefire' then
		return
	end
	local _,_,isSpec,teamID, allianceID = spGetPlayerInfo(playerID, false)
	if isSpec then
		return
	end
	
	local vote = msg_table[2]
	local actionAlliance = tonumber( msg_table[3] )
	if cfData[allianceID] and cfData[allianceID][actionAlliance] then
		SetVote(allianceID, actionAlliance, teamID, vote=='y')
	end
end

function gadget:GameFrame(f)
	if (f%32) < 0.1 then
		checkVotes()
		checkOffers()
		local teamList = spGetTeamList()
		for _,teamID in ipairs(teamList) do
			if spGetTeamUnitCount(teamID) == 0 then
				--gadget:TeamDied(teamID)
			end
		end
	end
end


function gadget:Initialize()
	Spring.SetGameRulesParam('cf', 1)
	
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam, false)
	
	local allianceList = spGetAllyTeamList()
	local enAllianceList = spGetAllyTeamList()
	
	for _, alliance in ipairs(allianceList) do
		if alliance ~= gaiaAlliance then
			cfData[alliance] = {}
			for _, enAlliance in ipairs(enAllianceList) do
				if enAlliance ~= alliance and enAlliance ~= gaiaAlliance then
					cfData[alliance][enAlliance] = {}
					cfData[alliance][enAlliance].votes = {}
					local teamList = spGetTeamList(alliance)
					for _,teamID in ipairs(teamList) do
						cfData[alliance][enAlliance].votes[teamID] = false
						if TESTMODE and alliance == 2 then
							cfData[alliance][enAlliance].votes[teamID] = true
						end
					end
				end
			end
		end
	end
	
	-- for devving purposes
	for _, alliance in ipairs(allianceList) do
		if alliance ~= gaiaAlliance then
			for _, enAlliance in ipairs(enAllianceList) do
				if enAlliance ~= alliance and enAlliance ~= gaiaAlliance then
					clearVotes(alliance, enAlliance) 
					SetCeasefireOffered(alliance, enAlliance, false)
					SetCeasefire(alliance, enAlliance, false)
				end
			end
		end
	end
	
	for _,name in pairs(nukeNames) do
		local ud = UnitDefNames[name]
		if ud then
			nukeDefs[ud.id] = true
		end
	end
	
	checkAllianceSizes()
	checkVotes()
	_G.cfData = cfData

end

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD_ANTINUKEZONE] = true, [CMD_ATTACK] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID,cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_ATTACK and nukeDefs[unitDefID] then
		broadcastNuke(unitID, cmdParams)
	end
	return true  -- command was not used
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------



local spSendCommands		= Spring.SendCommands
local spGetSpectatingState 	= Spring.GetSpectatingState

local spGetLocalAllyTeamID	= Spring.GetLocalAllyTeamID
local spGetLocalTeamID		= Spring.GetLocalTeamID

local cycle				= 1
local spec				= true
local myAllyID 		= spGetLocalAllyTeamID()
local myTeamID 		= spGetLocalTeamID()
local myCeasefires 	= {}
local teamNames = {}


--------------------------------------------------------


--called from synced
local function ceasefire(_, a1, a2, enable)
	--echo('unsync cf', a1, a2, enable)
	if not spec and myAllyID == a1 then
		if enable then
			spSendCommands({'ally '.. a2 .. ' 1'})
			myCeasefires[a2] = true
		else
			spSendCommands({'ally '.. a2 .. ' 0'})
			myCeasefires[a2] = nil
		end
	end
end

-----------------------------------------------------------------------------
				

function gadget:Initialize()
	gadgetHandler:AddSyncAction('ceasefire', ceasefire)
	local teamList = Spring.GetTeamList()
	for _,teamID in ipairs(teamList) do
		local _, leaderPlayerID = Spring.GetTeamInfo(teamID, false)
		if leaderPlayerID and leaderPlayerID ~= -1 then
			
			teamNames[teamID] = Spring.GetPlayerInfo(leaderPlayerID, false) or '?? Rob P. ??'
		end
	end
end

function gadget:Update()
	cycle = cycle % 32 + 1

	spec = spGetSpectatingState()
	
	if cycle == 1 then
		myAllyID = spGetLocalAllyTeamID()
		myTeamID = spGetLocalTeamID()
		
		if not spec then
			for cAlliance, _ in pairs(myCeasefires) do
				
				local cTeamList = spGetTeamList(cAlliance)	
				if not spAreTeamsAllied(cTeamList[1], myTeamID) then
					spSendCommands({'ally '.. cAlliance .. ' 1'})
					echo('Ceasefire: Please use only the control panel to break ceasefires, '..teamNames[myTeamID] ..'!!')
				end
			end
		
		end
	end

end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end