function gadget:GetInfo()
  return {
    name      = "Ceasefire",
    desc      = "Handles reciprocating ceasefires with a voting system.",
    author    = "CarRepairer",
    date      = "2009-01-15",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = false -- loaded by default?
  }
end

-- 2009-08-26 moved UI into widget

local testMode = false
local testOnce = true

if tobool(Spring.GetModOptions().noceasefire) or Spring.FixedAllies() then
  return
end 

local Echo 				= Spring.Echo
local spGetPlayerInfo	= Spring.GetPlayerInfo
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetTeamList		= Spring.GetTeamList
local spAreTeamsAllied	= Spring.AreTeamsAllied
local spGetAllUnits     = Spring.GetAllUnits
local spGetUnitDefID    = Spring.GetUnitDefID

local rzRadius			= 200
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then 
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetUnitIsActive     = Spring.GetUnitIsActive
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetTeamUnitCount	= Spring.GetTeamUnitCount
local spInsertUnitCmdDesc	= Spring.InsertUnitCmdDesc
local spGetAllyTeamList		= Spring.GetAllyTeamList

local CMD_ONOFF             = CMD.ONOFF
local CMD_ATTACK            = CMD.ATTACK

local cfData = {}
local cloakedUnits = {}
local gaiaAlliance, gaiaTeam
local CMD_ANTINUKEZONE = 35130

local antinukeDefs = {}
local antinukeNames = {'armamd', 'armscab', 'cormabm', 'corfmd', 'cornukesub', 'armcarry'}
local nukeDefs = {}
local nukeNames = {'armsilo', 'corsilo'}
local antinukeZones = {}


local antinukeZoneCmdDesc = {
  id      = CMD_ANTINUKEZONE,
  type    = CMDTYPE.ICON_MODE,
  name    = 'Antinuke Zone',
  cursor  = 'CloakShield', 
  action  = 'antinukezone',
  tooltip = 'NoNuke zone: Nuke attacks within range of this unit will break ceasefires.',
  params  = {'0', 'NoNukeZone', 'NoNukeZone' }
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function AddAntinukeZoneCmdDesc(unitID)
  local insertID = 123456 -- back of the pack
  spInsertUnitCmdDesc(unitID, insertID + 1, antinukeZoneCmdDesc)
end

local function AddZone(unitID, cmdParams, range)
	if (type(cmdParams[1]) ~= 'number') then
		return false
	end
	
	local allianceID = spGetUnitAllyTeam(unitID)
	local state = (cmdParams[1] == 1)
	
	if state then
		local x,_,z = spGetUnitPosition(unitID)
		antinukeZones[unitID] = {
			allianceID=allianceID, x=x,z=z,range=range
		}		
	else
		antinukeZones[unitID] = nil
	end
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_ANTINUKEZONE)
	if (cmdDescID) then
		antinukeZoneCmdDesc.params[1] = (state and '1') or '0'
		spEditUnitCmdDesc(unitID, cmdDescID, { params = antinukeZoneCmdDesc.params})
	end	
end

local function clearVotes(alliance, enAlliance)
	local teamList = cfData[alliance][enAlliance].votes
	for teamID,_ in pairs(teamList) do
		cfData[alliance][enAlliance].votes[teamID] = false
		SendToUnsynced("setVote", alliance, enAlliance, teamID, false)
		if testMode and alliance == 2 and testOnce then	
			Echo('Ceasefire: test votes!', alliance, enAlliance)
			testOnce = false
			cfData[alliance][enAlliance].votes[teamID] = true
			SendToUnsynced("setVote", alliance, enAlliance, teamID, true)
		end
	end
end

local function checkOffers()
	for alliance,aData in pairs(cfData) do
		for enAlliance,enData in pairs(aData) do
			--both sides offer, set ceasefire
			if enData.ceasefireOffered and cfData[enAlliance][alliance].ceasefireOffered then
				
				if not enData.lastCfState then
					enData.lastCfState = true
					enData.ceasefired = true
					SendToUnsynced("setCeasefired", alliance, enAlliance, true)
					clearVotes(alliance, enAlliance)
					SendToUnsynced('ceasefire', alliance, enAlliance, true) 
				end
			--one side not offering, break ceasefires if they exist
			else
				if enData.lastCfState then
					enData.lastCfState = false
					enData.ceasefired = false
					SendToUnsynced("setCeasefired", alliance, enAlliance, false)
					enData.ceasefireOffered = false
					SendToUnsynced('setCeasefireOffered', alliance, enAlliance, false)
					
					SendToUnsynced('ceasefire', alliance, enAlliance, false)
				end
			end
		end
	end
end

local function checkVotes()
	for alliance, aData in pairs(cfData) do
		for enAlliance, enData in pairs(aData) do
			local yesVotes,totalVotes = 0,0
			for teamID, vote in pairs(enData.votes) do
				totalVotes = totalVotes + 1
				if vote then yesVotes = yesVotes + 1 end
			end
			--enData.yesVotes = yesVotes
			--enData.totalVotes = totalVotes
			
			if not enData.ceasefired then
				--100%
				if yesVotes == totalVotes then
					-- do not reset same value
					if not cfData[enAlliance][alliance].ceasefireOffered then
						cfData[enAlliance][alliance].ceasefireOffered = true
						SendToUnsynced("setCeasefireOffered", enAlliance, alliance, true)
					end
				else
					if cfData[enAlliance][alliance].ceasefireOffered then
						cfData[enAlliance][alliance].ceasefireOffered = false
						SendToUnsynced("setCeasefireOffered", enAlliance, alliance, false)
					end
				end
			end
		end
	end			
end

local function checkAllianceSizes()
	local allianceList = spGetAllyTeamList()
	for _, alliance in ipairs(allianceList) do
		
		local teamList = spGetTeamList(alliance)
		local livingTeam = false
		for _,teamID in ipairs(teamList) do
			local teamNum, leader, isDead = spGetTeamInfo(teamID)
			if not isDead then livingTeam = true end
		end
		if not livingTeam then
			cfData[alliance] = nil
			for _, aData in pairs(cfData) do
				aData[alliance] = nil
			end
			SendToUnsynced("removeAlliance", alliance)
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
				aData1.ceasefireOffered = false
				aData2.ceasefireOffered = false
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:TeamDied(deadTeamID)
	for alliance, aData in pairs(cfData) do
		for enAlliance, enData in pairs(aData) do
			enData.votes[deadTeamID] = nil
			SendToUnsynced("setVote", alliance, enAlliance, deadTeamID, nil)
		end
	end
	checkAllianceSizes()
end

function gadget:RecvLuaMsg(msg, playerID)
	local _,_,spec,teamID, allianceID = spGetPlayerInfo(playerID)
        if msg == "cf:requestData" then
 		-- send all data
		for alliance, aData in pairs(cfData) do
	                for enAlliance,enData in pairs(aData) do
				-- send only relevant data, anything for specs
				if ((alliance == allianceID) or spec) and (alliance ~= enAlliance) then
		                        local value = enData.ceasefired
		                        SendToUnsynced("setCeasefired", alliance, enAlliance, value)
		                        value = enData.ceasefireOffered
		                        SendToUnsynced("setCeasefireOffered", alliance, enAlliance, value)
		                        -- send team votes
		                        local teamList = spGetTeamList(alliance)
		                        for _,teamID in ipairs(teamList) do
		                        	value = enData.votes[teamID]
		                                SendToUnsynced("setVote", alliance, enAlliance, teamID, value)
		                        end
				end
	                end
		end
                return
	end
	if spec then return end
	if msg:find("cf:",1,true) then
		local actionAlliance = tonumber(msg:sub(5,6))
		if cfData[allianceID] and cfData[allianceID][actionAlliance] then
			local action = msg:sub(4,4)
			if action == 'y' then
				cfData[allianceID][actionAlliance].votes[teamID] = true
				SendToUnsynced("setVote", allianceID, actionAlliance, teamID, true)
			elseif action == 'n' then
				cfData[allianceID][actionAlliance].votes[teamID] = false
				SendToUnsynced("setVote", allianceID, actionAlliance, teamID, false)
			elseif action == 'b' then
				cfData[allianceID][actionAlliance].ceasefireOffered = false
				SendToUnsynced("setCeasefireOffered", allianceID, actionAlliance, false)
				cfData[actionAlliance][allianceID].ceasefireOffered = false
				SendToUnsynced("setCeasefireOffered", actionAlliance, allianceID, false)
			end
		end
	end
end

function gadget:GameFrame(f)
	if (f%32) < 0.1 then
		checkVotes()
		checkOffers()
		local teamList = spGetTeamList()
		for _,teamID in ipairs(teamList) do
			if (spGetTeamUnitCount(teamID) == 0) and (teamID ~= gaiaTeam) then
				gadget:TeamDied(teamID)
			end
		end
	end
end


function gadget:Initialize()
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam)
	
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
						if testMode and alliance == 2 then
							cfData[alliance][enAlliance].votes[teamID] = true
							SendToUnsynced("setVote", alliance, enAlliance, teamID, true)
						end
					end
				end
			end
		end
	end

	for _,name in pairs(antinukeNames) do
		local ud = UnitDefNames[name]
		local weaponDef = ud.weapons[1].weaponDef
		local coverage = WeaponDefs[weaponDef].coverageRange
		antinukeDefs[ud.id] = coverage
	end
	for _,name in pairs(nukeNames) do
		local ud = UnitDefNames[name]
		nukeDefs[ud.id] = true
	end
	
	gadgetHandler:RegisterCMDID(CMD_ANTINUKEZONE)
	local allUnits = spGetAllUnits()
	for _, unitID in ipairs(allUnits) do
		local unitDefID = spGetUnitDefID(unitID)
		if (antinukeDefs[unitDefID]) then
			AddAntinukeZoneCmdDesc(unitID)
		end
	end

	checkAllianceSizes()
	checkVotes()
end

function gadget:AllowCommand(unitID, unitDefID, teamID,cmdID, cmdParams, cmdOptions)
	local range = antinukeDefs[unitDefID]
	if cmdID == CMD_ANTINUKEZONE and range then
		AddZone(unitID, cmdParams, range)  
		return false  -- command was used
	elseif cmdID == CMD_ATTACK and nukeDefs[unitDefID] then
		checkNukeAttack(unitID, cmdParams)
	end
	return true  -- command was not used
end

function gadget:UnitCreated(unitID, unitDefID)
	if antinukeDefs[unitDefID] then
		AddAntinukeZoneCmdDesc(unitID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	antinukeZones[unitID] = nil
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local myAlliance
local myTeam
local myPlayerID
local myCfData
local spec = false
local cycle	= 1
local myCeasefires 	= {}

local spSendCommands 		= Spring.SendCommands
local spGetLocalTeamID		= Spring.GetLocalTeamID

--called from synced
local function ceasefire(_, a1, a2, onoff)
	if not spec and myAlliance == a1 then
		if onoff then
			spSendCommands({'ally '.. a2 .. ' 1'})
			myCeasefires[a2] = true
		else
			spSendCommands({'ally '.. a2 .. ' 0'})
			myCeasefires[a2] = nil
		end
	end
	-- not secret
	if (Script.LuaUI('CeasefireEventCeasefire')) then
		Script.LuaUI.CeasefireEventCeasefire(a1, a2, onoff)
	end
end

local function setVote(_, alliance, enAlliance, teamID, value)
  if (Script.LuaUI("CeasefireEventSetVote")) and ((myAlliance == alliance) or spec) then
    Script.LuaUI.CeasefireEventSetVote(alliance, enAlliance, teamID, value)
    --Spring.Echo("gadget: setVote send to LuaUI")
  end
end

local function setCeasefired(_, alliance, enAlliance, value)
  -- not secret
  if (Script.LuaUI("CeasefireEventSetCeasefired")) then
    Script.LuaUI.CeasefireEventSetCeasefired(alliance, enAlliance, value)
  end
end

local function setCeasefireOffered(_, alliance, enAlliance, value)
  if (Script.LuaUI("CeasefireEventSetCeasefireOffered")) and ((myAlliance == alliance) or spec) then
    Script.LuaUI.CeasefireEventSetCeasefireOffered(alliance, enAlliance, value)
  end
end

local function removeAlliance(_, alliance)
  -- not secret
  if (Script.LuaUI("CeasefireEventRemoveAlliance")) then
    Script.LuaUI.CeasefireEventRemoveAlliance(alliance)
  end
end

function gadget:Initialize()
  
  gadgetHandler:AddSyncAction("ceasefire", ceasefire)
  gadgetHandler:AddSyncAction("setVote", setVote)
  gadgetHandler:AddSyncAction("setCeasefired", setCeasefired)
  gadgetHandler:AddSyncAction("setCeasefireOffered", setCeasefireOffered)
  gadgetHandler:AddSyncAction("removeAlliance", removeAlliance)
  
  myAlliance = Spring.GetLocalAllyTeamID()
  spec = Spring.GetSpectatingState()
  myPlayerID = Spring.GetLocalPlayerID()

end

function gadget:PlayerChanged(playerID)
  if myPlayerID == playerID then
    spec = Spring.GetSpectatingState()
  end
end

function gadget:Update()
	cycle = cycle % (32*3) + 1
	spec = Spring.GetSpectatingState()
	
	if cycle == 1 then
		myTeamID = spGetLocalTeamID()
		myAlliance = Spring.GetLocalAllyTeamID()
		if not spec then
			for cAlliance, _ in pairs(myCeasefires) do
				local cTeamList = spGetTeamList(cAlliance)
				if not spAreTeamsAllied(tonumber(cTeamList[1]), myTeamID) then
					spSendCommands({'ally '.. cAlliance .. ' 1'})
					echo('Ceasefire: Please use the control panel to break ceasefires, '..teamNames[myTeamID] ..'!!')
				end
			end
			
		end
		
	end

end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end

