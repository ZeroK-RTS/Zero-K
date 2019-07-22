function gadget:GetInfo()
	return {
		name	 = "Share mode",
		desc	 = "Allows one to share control of resources and units with other players.",
		author	 = "_Shaman",
		date	 = "6-23-2016",
		license	 = "Do whatever you want with it, just give credit",
		layer	 = 0,
		enabled	 = true,
	}
end

-- Remove unsync and remove if off --

if gadgetHandler:IsSyncedCode() == false then
	return
end

--------------------------------------------------------
-- Speedups

local strGmatch = string.gmatch
local strGsub = string.gsub
local strFind = string.find
local strLower = string.lower

-- Spring API --
local spEcho = Spring.Echo
local spSetPlayerRulesParam = Spring.SetPlayerRulesParam
local spGetPlayerInfo = Spring.GetPlayerInfo
local spGetTeamInfo = Spring.GetTeamInfo
local spGetPlayerList = Spring.GetPlayerList
local spAssignPlayerToTeam = Spring.AssignPlayerToTeam
local spTransferUnit = Spring.TransferUnit
local spShareTeamResource = Spring.ShareTeamResource
local spValidUnitID = Spring.ValidUnitID
local spAreTeamsAllied = Spring.AreTeamsAllied
local spSetTeamRulesParam = Spring.SetTeamRulesParam
local spGetTeamList = Spring.GetTeamList
local spGetTeamResources = Spring.GetTeamResources
local spGetUnitTeam = Spring.GetUnitTeam
local spGetTeamUnits = Spring.GetTeamUnits
local spGetAllyTeamList = Spring.GetAllyTeamList
local spGetGameFrame = Spring.GetGameFrame

-- Other --
local public = {public = true}
local GaiaID = Spring.GetGaiaTeamID()

--------------------------------------------------------
-- Configuration

local function GetConfig()
	local modOptions = Spring.GetModOptions()
	return {
		mergeEnabled = modOptions.sharemode ~= "none",
		permanentMerge = modOptions.sharemode == "all",
		mintime   = 5, -- GET RID OF ME EVENTUALLY!
	}
end
local config = GetConfig()

if not config.mergeEnabled then
	spEcho("[Commshare] Commshare is off. Shutting down.")
	return
end

--------------------------------------------------------
-- Variables
local invites = {}
local controlledPlayers = {} -- table containing which team a playerID should be under.
local controlledTeams = {} -- contains which team a team of players should be under.
local originalTeamID = {} -- takes playerID as the key, gives the team as the value.
local originalUnits = {} -- contains which units are owned by a team that has commshared.

local firstMintime = true -- Partial initialize in gameframe after the game starts

--------------------------------------------------------
-- Utilities

local function GetTeamID(playerID)
	return select(4, spGetPlayerInfo(playerID, false))
end

local function GetTeamLeader(teamID)
	return select(2, spGetTeamInfo(teamID, false))
end

local function IsTeamLeader(playerID)
	local teamID = GetTeamID(playerID)
	local teamleaderid = select(2, spGetTeamInfo(teamID, false))
	if playerID == teamleaderid then
		return true
	else
		return false
	end
end

local function IsPlayerOnSameTeam(playerID,playerid2)
	local id1 = GetTeamID(playerID)
	local id2 = GetTeamID(playerid2)
	if id1 == id2 then
		return true
	else
		return false
	end
end

local function GetSquadSize(teamID)
	return #spGetPlayerList(teamID, true)
end

local function ProccessCommand(str)
	local command, targetID
	local i = 1
	-- A "word" is anything between two spaces or the start and the first space. So ProccessCommand("1 2 3 4")
	-- would return 2 3 4 (first 'word' is ignored, only 2nd, 3rd, and 4th count).
	for word in strGmatch(str, "%S+") do 
		if i == 2 then
			command = word
		elseif i == 3 then
			targetID = word
			break
		end
		i = i + 1
	end
	return command, targetID -- less creating tables this way. Old version would create a table, this one is slightly smarter.
end

local function IsTeamAfk(teamID)
	local _, shares = GG.Lagmonitor.GetResourceShares()
	if shares == 0 then
		return true
	else
		return false
	end
end

local function UnmergePlayer(playerID) -- Takes playerID, not teamID!!!
	local name = spGetPlayerInfo(playerID, false)
	if not config.permanentMerge then
		spEcho("game_message: Unmerging player " .. name)
		if originalTeamID[playerID] then
			local orgTeamID = originalTeamID[playerID]
			spAssignPlayerToTeam(playerID,orgTeamID)
			controlledTeams[orgTeamID] = nil
			local unitID
			for i = 1, #originalUnits[orgTeamID] do
				unitID = originalUnits[orgTeamID][i]
				if spValidUnitID(unitID) and spAreTeamsAllied(spGetUnitTeam(unitID), orgTeamID) then
					spTransferUnit(unitID, orgTeamID, true)
				end
			end
			spSetTeamRulesParam(originalTeamID[playerID], "isCommsharing", nil)
			originalUnits[orgTeamID], controlledPlayers[playerID] = nil, nil
		else
			spEcho("[Commshare]: Tried to unmerge a player that never merged (Perhaps cheated in?)")
		end
	else
		spEcho("[Commshare]: Unmerging is forbidden in this game mode!")
	end
end

local function MergeUnits(teamID, target)
	originalUnits[teamID] = spGetTeamUnits(teamID)
	local unitID
	for i = 1, #originalUnits[teamID] do
		unitID = originalUnits[teamID][i]
		if spValidUnitID(unitID) then
			spTransferUnit(unitID, target, true)
		end
	end
end
	
local function MergePlayer(playerID,target)
	if playerID == nil then
		spEcho("[Commshare] Tried to merge a nil player!")
		return
	end
	local orgTeamID = GetTeamID(playerID)
	local name,_,spec,_,_,allyteam  = spGetPlayerInfo(playerID, false)
	if spAreTeamsAllied(orgTeamID,target) and (not spec) and target ~= GaiaID then
		spEcho("[Commshare] Assigning player id " .. playerID .. "(" .. name .. ") to team " .. target)
		if GetSquadSize(orgTeamID) - 1 == 0 then
			local metal = spGetTeamResources(orgTeamID,"metal")
			local energy = spGetTeamResources(orgTeamID,"energy")
			controlledTeams[orgTeamID] = target
			spShareTeamResource(orgTeamID,target,"metal",metal)
			spShareTeamResource(orgTeamID,target,"energy",energy)
			MergeUnits(orgTeamID,target)
			spSetTeamRulesParam(orgTeamID,"isCommsharing",target,public)
		end
		spAssignPlayerToTeam(playerID,target)
		if originalTeamID[playerID] == nil then
			originalTeamID[playerID] = orgTeamID
		end
		controlledPlayers[playerID] = target
	else
		spEcho("[Commshare] Merger error.")
	end
end

local function MergeTeams(team1,team2) -- bandaid for an issue during planning.
	local playerlist = spGetPlayerList(team1,true)
	for i = 1, #playerlist do
		MergePlayer(playerlist[i],team2)
	end
end

local function MergeAllHumans(teamlist)
	local mergeid = -1
	for i = 1, #teamlist do
		local _, teamLeader, _, AI = spGetTeamInfo(teamlist[i], false)
		local human = not AI and teamLeader ~= -1
		if human and mergeid ~= -1 then
			spEcho("[Commshare] Merging team " .. teamlist[i])
			-- Needed because of recursion error. Only one player on a team at game start anyways.
			MergePlayer(teamLeader,mergeid)
		elseif human and mergeid == -1 then
			mergeid = teamlist[i]
			spEcho("[Commshare] MergeID is " .. mergeid)
		else
			spEcho("[Commshare] Skipping team " .. i .. " [inhuman]")
		end
	end
end

local function MergeAll()
	local ally = spGetAllyTeamList()
	for i = 1, #ally do
		local teamlist = spGetTeamList(ally[i])
		if #teamlist > 1 then
			spEcho("[Commshare] Merging alliance " .. i)
			MergeAllHumans(teamlist)
		end
	end
end

local function SendInvite(player, target) -- targetid is which player is the merger
	if spGetGameFrame() > config.mintime then
		local targetspec = select(3, spGetPlayerInfo(target, false))
		local _,_,dead,ai = spGetTeamInfo(GetTeamID(target), false)
		if player == target or GetTeamID(target) == GetTeamID(player) then
			spEcho("[Commshare] " .. select(1,spGetPlayerInfo(player, false)) .. " tried to merge with theirself or a squad member!")
			return
		end
		if targetspec then
			spEcho("[Commshare] " .. select(1,spGetPlayerInfo(player, false)) .. " tried to merge with a spectator!")
			return
		end
		if targetid == player then
			local teamID = GetTeamID(target)
			target = GetTeamLeader(teamID)
		end
		if not dead and not ai then
			if invites[target] == nil then
				invites[target] = {}
			end
			invites[target][player] = {id = player, timeleft = 60}
		end
	end
end

local function AcceptInvite(player,target)
	spEcho("verifying invite")
	if invites[player][target] then
		spEcho("invite verified")
		local teamID = GetTeamID(player)
		if GetTeamLeader(teamID) == player and GetSquadSize(teamID) > 1 then
			MergeTeams(GetTeamID(player),GetTeamID(target))
		else
			MergePlayer(player,GetTeamID(target))
		end
		invites[player][target] = nil
		if invites[target] then
			invites[target][player] = nil
		end
	else
		spEcho("[Commshare] Invalid invite: " .. player,target .. "!")
	end
end

------------------ Callins ------------------
	
function gadget:GameFrame(frame)
	if frame%30 == 0 then
		local invitecount
		for player, playerInvites in pairs(invites) do
			invitecount = 0
			for key,data in pairs(playerInvites) do
				invitecount = invitecount+1
				if data.timeleft > 0 then
					data.timeleft = data.timeleft - 1
				end
				if data.timeleft == 0 then 
					invitecount = invitecount-1
					playerInvites[key] = nil
					spSetPlayerRulesParam(player, "commshare_invite_" .. invitecount .. "_id", nil)
					spSetPlayerRulesParam(player, "commshare_invite_" .. invitecount .. "_timeleft", nil)
				elseif data.timeleft > 0 then
					spSetPlayerRulesParam(player, "commshare_invite_" .. invitecount .. "_timeleft", data.timeleft)
					spSetPlayerRulesParam(player, "commshare_invite_" .. invitecount .. "_id", data.id)
				end
			end
			spSetPlayerRulesParam(player, "commshare_invitecount",invitecount)
			if invitecount == 0 then 
				-- Cleanup the table so that next second this doesn't run.
				invites[player] = nil
			end
		end
	end
	if firstMintime and frame >= config.mintime and config.permanentMerge then
		MergeAll()
		firstMintime = false
	end
end

function gadget:RecvLuaMsg(message, playerID) -- Entry points for widgets to interact with the gadget
	if strFind(message, "sharemode") then
		local command,targetID = ProccessCommand(strLower(message))
		local name = select(1, spGetPlayerInfo(playerID, false))
		if command == nil then
			spEcho("[Commshare] " .. player .. "(" .. name .. ") sent an invalid command")
			return
		end
		-- process augs --
		if targetID then
			targetID = strGsub(targetID,"%D","")
			if targetID ~= "" then
				targetID = tonumber(targetID)
			end
		end

		if strFind(command,"remerge") then -- remerging seems impossible gadget side.
			local _,active,spec,_ = spGetPlayerInfo(playerID, false)
			if controlledPlayers[playerID] and not spec then
				spAssignPlayerToTeam(playerID, controlledPlayers[playerID])
				spEcho("game_message: Player " .. name .. " has been remerged!")
			end
		elseif strFind(command,"unmerge") then
			local afk = IsTeamAfk(GetTeamID(playerID))
			spEcho("team is afk: " .. tostring(afk))
			if controlledPlayers[playerID] and not afk then
				UnmergePlayer(playerID)
				return
			else
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") isn't on a squad!")
				return
			end
		end

		if type(targetID) ~= "number" then
			return
		end

		-- Do commands --
		if strFind(command, "invite") then
			SendInvite(playerID, targetID)
			if invites[playerID] and invites[playerID][targetID] and invites[targetID][playerID] then
				AcceptInvite(playerID,targetID)
			end
		elseif strFind(command, "accept") then
			if invites[playerID] and invites[playerID][targetID] then
				AcceptInvite(playerID,targetID)
				return
			else
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") sent an invalid accept command: " .. targetID .. " doesn't exist.")
			end
		elseif strFind(command,"decline") then
			invites[playerID][targetID] = nil
		elseif strFind(command,"kick") then
			if IsTeamLeader(playerID) then
				if IsPlayerOnSameTeam(playerID,targetID) then
					UnmergePlayer(targetID)
					return
				else
					spEcho("[Commshare] " .. playerID .. "(" .. name .. ") tried to kick a player that isn't on their team! ID: " .. targetID)
					return
				end
			else
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") isn't a leader! Cannot kick this player.")
				return
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if controlledTeams[unitTeam] then
		spTransferUnit(unitID, controlledTeams[unitTeam], true) -- this is in case of late commer coms,etc.
	end
end
--[[ No longer needed since share menu does not allow empty teams to receive units. Unbind sharedialogue instead!
function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if controlledTeams[newTeam] and GetSquadSize(oldTeam) > 0 then
		spTransferUnit(unitID, controlledTeams[newTeam], true)
	end
end]]
