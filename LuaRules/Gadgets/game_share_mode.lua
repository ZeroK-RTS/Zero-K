function gadget:GetInfo()
	return {
		name	 = "Share mode",
		desc	 = "Allows one to share control of resources and units with other players.",
		author	 = "Shaman",
		date	 = "6-23-2016",
		license	 = "PD",
		layer	 = 0,
		enabled	 = true,
	}
end


if not gadgetHandler:IsSyncedCode() then
	local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
	function gadget:PlayerChanged(playerID)
		spSendLuaRulesMsg("sharemode playerchanged " .. playerID) -- tell synced land that I changed status.
	end
end

--------------------------------------------------------
-- Speedups

local strGmatch = string.gmatch
local strGsub = string.gsub
local strFind = string.find
local strLower = string.lower

-- Spring API --
local spEcho = Spring.Echo
local spIsGameOver = Spring.IsGameOver
local spGetPlayerRulesParam = Spring.GetPlayerRulesParam
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
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spGetTeamList = Spring.GetTeamList
local spGetTeamResources = Spring.GetTeamResources
local spGetUnitTeam = Spring.GetUnitTeam
local spGetTeamUnits = Spring.GetTeamUnits
local spGetAllyTeamList = Spring.GetAllyTeamList
local spGetGameFrame = Spring.GetGameFrame

-- Other --
local public = {public = true} -- this is a speedup for gamerules playerrules, etc.
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
local debug = false
local playerstates = {} -- keeps track of player states so that we can remerge them if necessary.
local invites = {} -- the invites people have out.
local originalUnits = {} -- contains which units are owned by a team that has commshared.
local updateplayers = {}
local updateplayercount = 0

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

local function GetNewLeader(teamID)
	local playerlist = spGetPlayerList(teamID)
	for i=1, #playerlist do
		if not IsTeamLeader(playerlist[i]) then
			return playerlist[i]
		end
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

local function DebugEcho(str)
	if debug then
		spEcho(str)
	end
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

local function UnmergeUnits(orgTeamID, newOwner)
	local unitID
	local units = originalUnits[orgTeamID]
	for i = 1, #units do
		unitID = units[i]
		if spValidUnitID(unitID) and spAreTeamsAllied(spGetUnitTeam(unitID), orgTeamID) then
			spTransferUnit(unitID, newOwner, true)
		end
	end
	if newOwner == orgTeamID then
		originalUnits[orgTeamID] = nil
	end
end

local function UnmergePlayer(playerID) -- Takes playerID, not teamID!!!
	local name = spGetPlayerInfo(playerID, false)
	if not config.permanentMerge then
		spEcho("game_message: Unmerging player " .. name)
		if spGetPlayerRulesParam(playerID,"commshare_orig_teamid") then
			local orgTeamID = spGetPlayerRulesParam(playerID,"commshare_orig_teamid")
			spAssignPlayerToTeam(playerID,orgTeamID)
			UnmergeUnits(orgTeamID, orgTeamID)
			spSetTeamRulesParam(orgTeamID, "isCommsharing", nil)
			spSetPlayerRulesParam(playerID,"commshare_team_id",nil)
			spSetPlayerRulesParam(playerID,"commshare_orig_teamid",nil)
		elseif IsTeamLeader(playerID) then -- leader wants to unmerge
			local myteamid = GetTeamID(playerID)
			local playerlist = spGetPlayerList(myteamid)
			local newleader = GetNewLeader(myteamid)
			local leaderTeam = spGetPlayerRulesParam(newleader,"commshare_orig_teamid")
			spSetTeamRulesParam(leaderTeam, "isCommsharing", nil) -- clean up the new leader.
			spSetPlayerRulesParam(newleader,"commshare_team_id",nil)
			spSetPlayerRulesParam(newleader,"commshare_orig_teamid",nil)
			spAssignPlayerToTeam(newleader,leaderTeam)
			UnmergeUnits(leaderTeam, leaderTeam)
			for i=1, #playerlist do
				if playerlist[i] ~= playerID and playerlist[i] ~= newleader then -- don't reproccess
					local myOldTeam = spGetPlayerRulesParam(newleader,"commshare_orig_teamid")
					UnmergeUnits(myOldTeam, leaderTeam)
					spSetTeamRulesParam(myOldTeam,"isCommsharing",newleader,public)
					spSetPlayerRulesParam(playerlist[i],"commshare_team_id",leaderTeam)
					spAssignPlayerToTeam(playerlist[i],leaderTeam)
				end
			end
		else
			DebugEcho("[Commshare]: Tried to unmerge a player that never merged (Perhaps cheated in?)")
		end
	else
		spEcho("[Commshare]: Unmerging is forbidden in this game mode!")
	end
end

local function MergeUnits(teamID, target)
	originalUnits[teamID] = spGetTeamUnits(teamID)
	local unitID
	local units = originalUnits[teamID]
	for i = 1, #units do
		unitID = units[i]
		if spValidUnitID(unitID) then
			spTransferUnit(unitID, target, true)
		end
	end
end
	
local function MergePlayer(playerID,target)
	if playerID == nil then
		DebugEcho("[Commshare] Tried to merge a nil player!")
		return
	end
	local orgTeamID = GetTeamID(playerID)
	local name,_,spec,_,_,allyteam  = spGetPlayerInfo(playerID, false)
	if spAreTeamsAllied(orgTeamID,target) and (not spec) and target ~= GaiaID then
		DebugEcho("[Commshare] Assigning player id " .. playerID .. "(" .. name .. ") to team " .. target)
		if GetSquadSize(orgTeamID) - 1 == 0 then
			local metal = spGetTeamResources(orgTeamID,"metal")
			local energy = spGetTeamResources(orgTeamID,"energy")
			spShareTeamResource(orgTeamID,target,"metal",metal)
			spShareTeamResource(orgTeamID,target,"energy",energy)
			spSetTeamRulesParam(orgTeamID,"isCommsharing",target,public) -- this team is commsharing under this teamid.
			MergeUnits(orgTeamID,target)
		end
		spSetPlayerRulesParam(playerID, "commshare_team_id",target,public) -- this player is commsharing under this teamid
		if spGetPlayerRulesParam(playerID, "commshare_orig_teamid") == nil then -- first merges always store their original teamIDs.
			spSetPlayerRulesParam(playerID, "commshare_orig_teamid",orgTeamID,public)
		end
		if spGetTeamRulesParam(target,"isCommsharing") then -- completely delete this nasty bug where rejoining and inviting your original squad would neuter your team.
			spSetTeamRulesParam(target,"isCommsharing",nil)
		end
		spAssignPlayerToTeam(playerID,target)
	else
		DebugEcho("[Commshare] Merge error.")
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
			DebugEcho("[Commshare] Merging team " .. teamlist[i])
			-- Needed because of recursion error. Only one player on a team at game start anyways.
			MergePlayer(teamLeader,mergeid)
		elseif human and mergeid == -1 then
			mergeid = teamlist[i]
			DebugEcho("[Commshare] MergeID is " .. mergeid)
		else
			DebugEcho("[Commshare] Skipping team " .. i .. " [inhuman]")
		end
	end
end

local function MergeAll()
	local ally = spGetAllyTeamList()
	for i = 1, #ally do
		local teamlist = spGetTeamList(ally[i])
		if #teamlist > 1 then
			DebugEcho("[Commshare] Merging alliance " .. i)
			MergeAllHumans(teamlist)
		end
	end
end

local function SendInvite(player, target) -- targetid is which player is the merger
	if spGetGameFrame() > config.mintime then
		local targetspec = select(3, spGetPlayerInfo(target, false))
		local _,_,dead,ai = spGetTeamInfo(GetTeamID(target), false)
		if player == target or GetTeamID(target) == GetTeamID(player) then
			DebugEcho("[Commshare] " .. select(1,spGetPlayerInfo(player, false)) .. " tried to merge with theirself or a squad member!")
			return
		end
		if targetspec then
			DebugEcho("[Commshare] " .. select(1,spGetPlayerInfo(player, false)) .. " tried to merge with a spectator!")
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
		DebugEcho("[Commshare] invite verified")
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
		DebugEcho("[Commshare] Invalid invite: " .. player,target .. "!")
	end
end

local function DisposePlayer(playerID) -- clean up this player. Called 1 frame after players resign (to prevent multiple calls)
	if spIsGameOver() then -- Don't even bother processing.
		return
	end
	local name = spGetPlayerInfo(playerID,false)
	local teamid = playerstates[playerID].teamid
	DebugEcho("[Commshare] Disposing of player " .. name)
	DebugEcho("TeamID: " .. tostring(teamid) .. "\nIsTeamLeader: " .. tostring(IsTeamLeader(playerID)) .. "\nSquadsize: " .. GetSquadSize(teamid))
	if invites[playerID] then
		local i = 0
		for key,data in pairs(invites[playerID]) do -- kill off invites.
			i = i + 1
			spSetPlayerRulesParam(player, "commshare_invite_" .. i .. "_id", nil)
			spSetPlayerRulesParam(player, "commshare_invite_" .. i .. "_timeleft", nil)
			spSetPlayerRulesParam(player, "commshare_invitecount",nil)
		end
		invites[playerID] = nil
	end
	spSetPlayerRulesParam(playerID,"commshare_team_id", nil)
	local origteam = spGetPlayerRulesParam(playerID,"commshare_orig_teamid")
	if origteam then -- force original team to resign.
		spEcho("game_message: " .. name .. " resigned.")
		originalUnits[origteam] = nil
		spSetTeamRulesParam(origteam,"isCommsharing",nil)
	else
		local squadsize = GetSquadSize(teamid) + 1
		local newleader = select(2,spGetTeamInfo(teamid,false))
		local newleadername,_ = spGetPlayerInfo(newleader,false)
		if squadsize > 2 then -- needed because often times squad members resign and there's no resign message. (This is because lagmonitor doesn't see a team dying I think. We're dealing with players after all.)
			spEcho("game_message: " .. name .. " resigned, transfering squad lead to " .. newleadername .. ".")
		elseif squadsize == 2 then
			spEcho("game_message: " .. name .. " resigned. Squad broken!")
		end
	end
	spSetPlayerRulesParam(playerID, "commshare_orig_teamid",nil)
	playerstates[playerID] = nil
end

local function CheckIfAlreadyExists(targetID)
	if updateplayercount == 0 then
		return false
	end
	for i=1, updateplayercount do
		if updateplayers[updateplayercount].playerID == targetID then
			return true
		end
	end
	return false
end

local function AddUpdatePlayer(targetID, status)
	if CheckIfAlreadyExists(targetID) then
		return
	end
	updateplayercount = updateplayercount + 1
	if updateplayers[updateplayercount] then
		updateplayers[updateplayercount].playerID = targetID
		updateplayers[updateplayercount].status = status
	else
		updateplayers[updateplayercount] = {playerID = targetID, status = status}
	end
end

local function RemergePlayer(targetID)
	local commshareID = spGetPlayerRulesParam(targetID, "commshare_team_id")
	MergePlayer(targetID,commshareID)
end

------------------ Callins ------------------
	
function gadget:GameFrame(frame)
	if frame%30 == 0 then
		local invitecount
		for player, playerInvites in pairs(invites) do
			invitecount = 0
			for key,data in pairs(playerInvites) do
				DebugEcho("player: " .. player .. ", invite: " .. key)
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
	if updateplayercount > 0 and not spIsGameOver() then -- this is prevent excessive processing on game over.
		local player
		for i=1, updateplayercount do
			player = updateplayers[i]
			if player.status == "dead" then
				DisposePlayer(updateplayers[i].playerID)
			elseif player.status == "remerge" then
				RemergePlayer(updateplayers[i].playerID)
			end
		end
		updateplayercount = 0
	end
end

function gadget:RecvLuaMsg(message, playerID) -- Entry points for widgets to interact with the gadget. Also handles PlayerChanged.
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
		if strFind(command,"unmerge") then
			local afk = IsTeamAfk(GetTeamID(playerID))
			DebugEcho("team is afk: " .. tostring(afk))
			if not afk and #spGetPlayerList(playerID) > 1 then
				UnmergePlayer(playerID)
				return
			else
				DebugEcho("[Commshare] " .. playerID .. "(" .. name .. ") is afk/not in a squad!")
				return
			end
		end

		if type(targetID) ~= "number" then
			return
		end
		DebugEcho("[Commshare] Command: " .. tostring(command) .. " from " .. playerID)
		-- Do commands --
		if strFind(command, "invite") then
			SendInvite(playerID, targetID)
			if invites[playerID] and invites[playerID][targetID] and invites[targetID] and invites[targetID][playerID] then
				AcceptInvite(playerID,targetID)
			end
		elseif command:find("playerchanged") then -- hack in remerging. this is sent
			DebugEcho("[Commshare] Playerchanged: " .. targetID)
			local name, active, spectator, teamID = spGetPlayerInfo(targetID)
			local commshareID = spGetPlayerRulesParam(targetID, "commshare_team_id")
			DebugEcho("playerstates: " .. tostring(playerstates[targetID] == nil) .. "\nSpectator: " .. tostring(spectator))
			if playerstates[targetID] == nil and not spectator then -- this player has commshared or changed state.
				DebugEcho("[Commshare] generated playerstate table.")
				playerstates[targetID] = {active = active, spectator = spectator, teamid = teamID}
			elseif not spectator then
				DebugEcho("Commshare: PlayerChange: " .. name .."(ID: " .. targetID ..")\nActive: " .. tostring(playerstates[playerID].active) .. "->" .. tostring(active) .. "\nSpectator: " .. tostring(playerstates[playerID].spectator) .. "->" .. tostring(spectator) .."\nMergeID: " .. tostring(commshareID))
				if active ~= playerstates[targetID].active and active and commshareID then -- this player has reconnected.
					AddUpdatePlayer(targetID,"remerge")
					DebugEcho("Commshare: Remerged " .. name)
				end
				playerstates[targetID].active = active
				playerstates[targetID].spectator = spectator
				playerstates[targetID].teamid = teamID
			elseif spectator and playerstates[targetID] then -- this player resigned
				DebugEcho("Commshare: Disposing of " .. name)
				AddUpdatePlayer(targetID,"dead")
				return
			end
		elseif strFind(command, "accept") then
			if invites[playerID] and invites[playerID][targetID] then
				AcceptInvite(playerID,targetID)
				return
			else
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") sent an invalid accept command: " .. targetID .. " doesn't exist.")
			end
		elseif strFind(command,"decline") then
			if invites[playerID] then
				invites[playerID][targetID] = nil
			end
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
	if spGetTeamRulesParam(unitTeam,"isCommsharing") then
		local commshareTeamID = spGetTeamRulesParam(unitTeam,"isCommsharing")
		DebugEcho("Commshare: unitCreated triggered for " .. unitTeam .. ", given to " .. commshareTeamID)
		spTransferUnit(unitID, commshareTeamID, true) -- this is in case of late commer coms,etc.
	end
end
--[[ No longer needed since share menu does not allow empty teams to receive units. Unbind sharedialogue instead!
function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if controlledTeams[newTeam] and GetSquadSize(oldTeam) > 0 then
		spTransferUnit(unitID, controlledTeams[newTeam], true)
	end
end]]
