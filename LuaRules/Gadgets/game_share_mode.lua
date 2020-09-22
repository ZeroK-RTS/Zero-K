function gadget:GetInfo()
	return {
		name	 = "Share mode",
		desc	 = "Allows one to share control of resources and units with other players.",
		author	 = "Shaman",
		date	 = "6-23-2016",
		license	 = "PD",
		layer	 = 10, -- after lagmonitor
		enabled	 = true,
	}
end


if not gadgetHandler:IsSyncedCode() then
	local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
	function gadget:PlayerChanged(playerID)
		spSendLuaRulesMsg("sharemode playerchanged " .. playerID) -- tell synced land that I changed status.
	end
	return -- unsyncedland doesn't need anything else here.
end

--------------------------------------------------------
-- Speedups

local strGmatch = string.gmatch
local strGsub = string.gsub
local strFind = string.find
local strLower = string.lower

-- Spring API --
local spIsCheatingEnabled = Spring.IsCheatingEnabled
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
		mintime = 5, -- Needed to prevent commshare==all from fucking over comm spawns. Remove me once Start Position Rework gets merged.
	}
end
local config = GetConfig()

if not config.mergeEnabled then
	spEcho("[Commshare] Commshare is off. Shutting down.")
	return
end

local Names

if config.permanentMerge then -- only add these if we're on hivemind mode. These give all the 'hiveminds' special names. Mostly a fun little touch to the game mode.
	--Note: to add a name template, add a new entry to both tables here. Use <leader> to add a clan or player name to the name.
	--TODO: Translation.
	--Also note, this only shows up after a luaui reload or during the "<allyname> wins message, because pregame commshare still isn't a thing. (Yet)
	Names = {
		long = {
			[1] = 'The <leader>', -- EX: The Shaman or The ADVENT
			[2] = 'The <leader> Collective',
			[3] = '<leader> Aggregate',
			[4] = 'The <leader> Swarm',
			[5] = 'The <leader> Hivemind',
			[6] = 'Hyron Core <leader>',
			[7] = 'The <leader> Core',
			[8] = 'The <leader> Network',
			[9] = '<leader> Prime',
			[10] = 'The <leader> Cult',
		},
		short = {
			[1] = '<leader>',
			[2] = '<leader> Collective',
			[3] = '<leader> Aggregate',
			[4] = '<leader> Swarm',
			[5] = '<leader> Hivemind',
			[6] = 'Hyron Core <leader>',
			[7] = '<leader> Core',
			[8] = '<leader> Network',
			[9] = '<leader> Prime',
			[10] = '<leader> Cult',
		},
		templates = 0,
		easteregg = false, -- Have we set the easteregg yet? (Set to true to remove it entirely)
	}
	Names.templates = math.min(#Names.long, #Names.short) -- tell name setter how many templates we have to choose from
	-- self check --
	if #Names.long > Names.templates then
		for i = Names.templates, #Names.long do
			spEcho("[Commshare] Dropped template '" .. Names.long[i] .. "' (ID: " .. i .. ") due to missing Short name.")
		end
	elseif #Names.short > Names.templates then
		for i = Names.templates, #Names.short do
			spEcho("[Commshare] Dropped short template '" .. Names.short[i] .. "' (ID: " .. i .. ") due to missing Long name.")
		end
	end
end

--------------------------------------------------------
-- Variables
local debugMode = false
local firstError = true
local playerstates = {} -- keeps track of player states so that we can remerge them if necessary.
local invites = {} -- the invites people have out.
local originalUnits = {} -- contains which units are owned by a team that has commshared.
local updateplayers = {}
local updateplayercount = 0

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
	return playerID == teamleaderid
end

local function GetNewLeader(teamID)
	local playerlist = spGetPlayerList(teamID)
	for i=1, #playerlist do
		if not IsTeamLeader(playerlist[i]) then
			return playerlist[i]
		end
	end
end

local function IsPlayerOnSameTeam(playerID, playerid2)
	local id1 = GetTeamID(playerID)
	local id2 = GetTeamID(playerid2)
	return id1 == id2
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

local function IsTeamAfk(teamID) -- TODO: Replace me with race condition AFK check when avaliable.
	local _, shares = GG.Lagmonitor.GetResourceShares()
	if debugMode then
		spEcho("[Commshare] " .. teamID .. " shares: " .. tostring(shares[teamID]))
	end
	return shares[teamID] == 0
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
		if spGetPlayerRulesParam(playerID, "commshare_orig_teamid") then
			local orgTeamID = spGetPlayerRulesParam(playerID, "commshare_orig_teamid")
			spAssignPlayerToTeam(playerID, orgTeamID)
			UnmergeUnits(orgTeamID, orgTeamID)
			spSetTeamRulesParam(orgTeamID, "isCommsharing", nil)
			spSetPlayerRulesParam(playerID, "commshare_team_id", nil)
			spSetPlayerRulesParam(playerID, "commshare_orig_teamid", nil)
		elseif IsTeamLeader(playerID) then -- leader wants to unmerge
			local myteamid = GetTeamID(playerID)
			local playerlist = spGetPlayerList(myteamid)
			local newleader = GetNewLeader(myteamid)
			local leaderTeam = spGetPlayerRulesParam(newleader, "commshare_orig_teamid")
			spSetTeamRulesParam(leaderTeam, "isCommsharing", nil) -- clean up the new leader.
			spSetPlayerRulesParam(newleader, "commshare_team_id", nil)
			spSetPlayerRulesParam(newleader, "commshare_orig_teamid", nil)
			spAssignPlayerToTeam(newleader, leaderTeam)
			UnmergeUnits(leaderTeam, leaderTeam)
			for i=1, #playerlist do
				if playerlist[i] ~= playerID and playerlist[i] ~= newleader then -- don't reproccess
					local myOldTeam = spGetPlayerRulesParam(newleader, "commshare_orig_teamid")
					UnmergeUnits(myOldTeam, leaderTeam)
					spSetTeamRulesParam(myOldTeam, "isCommsharing", newleader, public)
					spSetPlayerRulesParam(playerlist[i], "commshare_team_id", leaderTeam)
					spAssignPlayerToTeam(playerlist[i], leaderTeam)
				end
			end
		else
			if debugMode then
				spEcho("[Commshare] Tried to unmerge a player that never merged (Perhaps cheated in?)")
			end
		end
	else
		spEcho("[Commshare] Unmerging is forbidden in this game mode!")
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
	
local function MergePlayer(playerID, target)
	if playerID == nil then
		if debugMode then
			spEcho("[Commshare] Tried to merge a nil player!")
		end
		return
	end
	local orgTeamID = GetTeamID(playerID)
	local name, _, spec, _, _, allyteam  = spGetPlayerInfo(playerID, false)
	if spAreTeamsAllied(orgTeamID, target) and (not spec) and target ~= GaiaID then
		if debugMode then
			spEcho("[Commshare] Assigning player id " .. playerID .. "(" .. name .. ") to team " .. target)
		end
		if GetSquadSize(orgTeamID) - 1 == 0 then
			local metal = spGetTeamResources(orgTeamID, "metal")
			local energy = spGetTeamResources(orgTeamID, "energy")
			spShareTeamResource(orgTeamID, target, "metal", metal)
			spShareTeamResource(orgTeamID, target, "energy", energy)
			spSetTeamRulesParam(orgTeamID, "isCommsharing", target, public) -- this team is commsharing under this teamid.
			MergeUnits(orgTeamID, target)
		end
		spSetPlayerRulesParam(playerID, "commshare_team_id", target, public) -- this player is commsharing under this teamid
		if spGetPlayerRulesParam(playerID, "commshare_orig_teamid") == nil then -- first merges always store their original teamIDs.
			spSetPlayerRulesParam(playerID, "commshare_orig_teamid", orgTeamID, public)
		end
		if spGetTeamRulesParam(target, "isCommsharing") then -- completely delete this nasty bug where rejoining and inviting your original squad would give all nanoframes to your old team ID, rendering your squad useless.
			spSetTeamRulesParam(target, "isCommsharing", nil)
		end
		spAssignPlayerToTeam(playerID, target)
	else
		spEcho("[Commshare] Merge error: " .. playerID .. "," .. target)
	end
end

local function MergeTeams(team1, team2) -- bandaid for an issue during planning.
	local playerlist = spGetPlayerList(team1, true)
	for i = 1, #playerlist do
		MergePlayer(playerlist[i], team2)
	end
end

local function GetAllyTeamLeader(teamlist)
	local highestElo = -999999
	local highestEloID = -1
	local clanSupremecy = false
	local mergeID = -1
	local leadername = ""
	local players = #teamlist
	local clanthreshhold = math.ceil(players/2) + 1
	local clans = {}
	for i=1, #teamlist do
		local teamID = teamlist[i]
		local _, _, _, AI = spGetTeamInfo(teamlist[i], false)
		if not AI then
			local playerlist = spGetPlayerList(teamlist[i]) -- usually this will be one.
			for p=1, #playerlist do
				local playerID = playerlist[p]
				local cp = select(10,spGetPlayerInfo(playerID, false))
				local elo = cp.elo
				local clan = cp.clan or ""
				if debugMode then
					spEcho("[Commshare] Stats for " .. spGetPlayerInfo(playerID, false) .. ":\nElo: " .. tostring(elo) .. "\nClan: " .. tostring(clan))
				end
				if elo ~= nil then
					elo = tonumber(elo)
				else
					elo = -999999
				end
				if debugMode then
					spEcho("[Commshare] Player " .. playerID .. "'s Clan: " .. clan)
				end
				if elo > highestElo then
					if debugMode then
						spEcho("[Commshare] Highest Elo for team is now " .. elo)
					end
					highestElo = elo
					highestEloID = playerID
					if not clanSupremecy then
						mergeID = teamID
					end
				end
				if clan ~= "" then
					if clans[clan] == nil then
						clans[clan] = {players = 1, highestelo = elo, highestid = teamID}
					else
						clans[clan].players = clans[clan].players + 1
						if elo > clans[clan].highestelo then
							clans[clan].highestelo = elo
							clans[clan].highestid = teamID
							if debugMode then
								spEcho("[Commshare] Highest Elo for clan " .. clan .. " is now " .. elo)
							end
						end
						if clans[clan].players > clanthreshhold then
							if debugMode then
								spEcho("[Commshare] Clan supremecy detected for " .. clan .. "!")
							end
							leadername = clan
							mergeID = clans[clan].highestid
							clanSupremecy = true
						end
					end
				end
			end
		end
	end
	if mergeID == -1 then
		return "", mergeID
	end
	if not clanSupremecy then -- fallback to using the highest elo player.
		leadername = spGetPlayerInfo(highestEloID)
	end
	if debugMode then
		spEcho("[Commshare] mergeID: " .. mergeID .. ", leadername: " .. leadername)
	end
	return leadername, mergeID
end

local function MergeAllHumans(teamlist, allyID)
	local leaderName,mergeid = GetAllyTeamLeader(teamlist)
	if mergeid == -1 then -- this is a team of AIs
		if debugMode then
			spEcho("[Commshare] AI allyteam detected. Skipping.")
		end
		return
	end
	if debugMode then
		spEcho("[Commshare] MergeID: " .. mergeid)
	end
	for i = 1, #teamlist do
		local teamID = teamlist[i]
		local _, _, _, AI = spGetTeamInfo(teamlist[i], false)
		if not AI and teamID ~= mergeid then
			if debugMode then
				spEcho("[Commshare] Merging team " .. teamlist[i])
			end
			MergeTeams(teamID,mergeid)
		else
			if debugMode then
				spEcho("[Commshare] Skipping team " .. i .. " [inhuman/mergeID]")
			end
		end
	end
	if debugMode then
		spEcho("[Commshare] Setting up name for team.")
	end
	local templateID = math.random(1, Names.templates)
	if debugMode then
		spEcho("[Commshare] Template ID: " .. templateID)
	end
	local longName = Names.long[templateID]
	local shortName = Names.short[templateID]
	local easteregg = Names.easteregg
	longName = longName:gsub("<leader>", leaderName)
	shortName = shortName:gsub("<leader>", leaderName)
	if not easteregg and math.random(1, 1000) == 515 then -- Kshatriya's silly name. Has a 1.49% chance of showing up in 16 way ffas and a .002% chance of showing up in team games.
		longName = 'Buzzy Buzzy Bumblebees'
		shortName = 'THE BEES!!'
		Names.easteregg = true
	end
	if debugMode then
		spEcho("[Commshare] Setting allyteam " .. allyID .. "'s name to: " .. longName .. " ( " .. shortName .. " )")
	end
	Spring.SetGameRulesParam("allyteam_short_name_" .. allyID, shortName) -- override any default names with special merge mode names.
	Spring.SetGameRulesParam("allyteam_long_name_"  .. allyID, longName)
end

local function MergeAll()
	local ally = spGetAllyTeamList()
	for i = 1, #ally do
		local allyID = ally[i]
		local teamlist = spGetTeamList(allyID)
		if #teamlist > 1 then
			if debugMode then
				spEcho("[Commshare] Merging alliance " .. i)
			end
			MergeAllHumans(teamlist, allyID)
		end
	end
end

local function SendInvite(player, target) -- target is which player the player is trying to merge with.
	if spGetGameFrame() > config.mintime then
		local targetspec = select(3, spGetPlayerInfo(target, false))
		local _, _, dead,ai = spGetTeamInfo(GetTeamID(target), false)
		if player == target or GetTeamID(target) == GetTeamID(player) then
			spEcho("[Commshare] " .. select(1, spGetPlayerInfo(player, false)) .. " tried to merge with theirself or a squad member!")
			return
		end
		if targetspec then
			spEcho("[Commshare] " .. select(1, spGetPlayerInfo(player, false)) .. " tried to merge with a spectator!")
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

local function AcceptInvite(player, target)
	spEcho("verifying invite")
	if invites[player][target] then
		if debugMode then
			spEcho("[Commshare] invite verified")
		end
		local teamID = GetTeamID(player)
		if GetTeamLeader(teamID) == player and GetSquadSize(teamID) > 1 then
			MergeTeams(GetTeamID(player), GetTeamID(target))
		else
			MergePlayer(player, GetTeamID(target))
		end
		invites[player][target] = nil
		if invites[target] then
			invites[target][player] = nil
		end
	else
		spEcho("[Commshare] Invalid invite: " .. player, target .. "!")
	end
end

local function DisposePlayer(playerID) -- clean up this player. Called 1 frame after players resign (to prevent multiple calls)
	if spIsGameOver() then -- Don't even bother processing.
		return
	end
	local name = spGetPlayerInfo(playerID, false)
	local teamid = playerstates[playerID].teamid
	if debugMode then 
		spEcho("[Commshare] Disposing of player " .. name)
		spEcho("TeamID: " .. tostring(teamid) .. "\nIsTeamLeader: " .. tostring(IsTeamLeader(playerID)) .. "\nSquadsize: " .. GetSquadSize(teamid))
	end
	if invites[playerID] then
		local i = 0
		for key, data in pairs(invites[playerID]) do -- kill off invites.
			i = i + 1
			spSetPlayerRulesParam(player, "commshare_invite_" .. i .. "_id", nil)
			spSetPlayerRulesParam(player, "commshare_invite_" .. i .. "_timeleft", nil)
			spSetPlayerRulesParam(player, "commshare_invitecount", nil)
		end
		invites[playerID] = nil
	end
	spSetPlayerRulesParam(playerID, "commshare_team_id", nil)
	local origteam = spGetPlayerRulesParam(playerID, "commshare_orig_teamid")
	if origteam then -- force original team to resign.
		spEcho("game_message: " .. name .. " resigned.")
		originalUnits[origteam] = nil
		spSetTeamRulesParam(origteam, "isCommsharing", nil)
	else
		local squadsize = GetSquadSize(teamid) + 1
		local newleader = select(2, spGetTeamInfo(teamid, false))
		local newleadername = spGetPlayerInfo(newleader, false)
		if squadsize > 2 then -- needed because often times squad members resign and there's no resign message. (This is because lagmonitor doesn't see a team dying I think. We're dealing with players after all.)
			spEcho("game_message: " .. name .. " resigned, transfering squad lead to " .. newleadername .. ".")
		elseif squadsize == 2 then
			spEcho("game_message: " .. name .. " resigned. Squad broken!")
		end
	end
	spSetPlayerRulesParam(playerID, "commshare_orig_teamid", nil)
	playerstates[playerID] = nil
end

local function CheckIfAlreadyExists(targetID)
	if updateplayercount == 0 then
		return false
	end
	for i = 1, updateplayercount do
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
	MergePlayer(targetID, commshareID)
end

---------------- Debug ---------------------

local function ToggleDebug()
	if spIsCheatingEnabled() then -- toggle debugMode
		debugMode = not debugMode
		if debugMode then
			spEcho("[Commshare] Debug enabled.")
		else
			spEcho("[Commshare] Debug disabled.")
		end
	end
end

------------------ Callins ------------------
	
function gadget:GameFrame(frame)
	if frame%30 == 0 then
		local invitecount
		for player, playerInvites in pairs(invites) do
			invitecount = 0
			for key, data in pairs(playerInvites) do
				if debugMode then
					spEcho("player: " .. player .. ", invite: " .. key)
				end
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
			spSetPlayerRulesParam(player, "commshare_invitecount", invitecount)
			if invitecount == 0 then
				-- Cleanup the table so that next second this doesn't run.
				invites[player] = nil
			end
		end
	end
	if frame == config.mintime and config.permanentMerge then
		MergeAll()
	end
	if updateplayercount > 0 and not spIsGameOver() then -- this is prevent excessive processing on game over.
		local player
		for i = 1, updateplayercount do
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
	if not (message and strFind(message, "sharemode")) then
		return
	end
	local command, targetID = ProccessCommand(strLower(message))
	local name, active, spectator, teamID, _, _, _, _, _, cp = spGetPlayerInfo(playerID, false)
	
	if command == nil and (debugMode or firstError) then
		spEcho("LUA_ERRRUN", "[Commshare] " .. player .. "(" .. name .. ") sent an invalid command")
		firstError = false
		return
	end
	
	-- process augs --
	if targetID then
		targetID = strGsub(targetID, "%D", "")
		if targetID ~= "" then
			targetID = tonumber(targetID)
		end
	end
	
	if debugMode then
		spEcho("[Commshare] Command: " .. tostring(command) .. " from " .. playerID)
	end
	if strFind(command, "unmerge") then
		local afk = IsTeamAfk(GetTeamID(playerID))
		if debugMode then
			spEcho("team is afk: " .. tostring(afk))
		end
		if not afk and #spGetPlayerList(playerID) > 1 then
			UnmergePlayer(playerID)
			return
		else
			spEcho("[Commshare] " .. playerID .. "(" .. name .. ") is afk/not in a squad!")
			return
		end
	end
	
	if type(targetID) ~= "number" then
		return
	end
	
	-- Commands with a targetID associated with them--
	if strFind(command, "invite") then
		SendInvite(playerID, targetID)
		if invites[playerID] and invites[playerID][targetID] and invites[targetID] and invites[targetID][playerID] then
			AcceptInvite(playerID, targetID)
		end
	elseif command:find("playerchanged") then -- hack in remerging. this is sent by the gadget's unsynced stuff.
		local targetName, targetActive, targetSpectator, targetTeamID = spGetPlayerInfo(targetID, false)
		if debugMode then
			spEcho("[Commshare] Playerchanged: " .. targetID .. "( " .. targetName .. ")")
		end
		local commshareID = spGetPlayerRulesParam(targetID, "commshare_team_id")
		if debugMode then
			spEcho("[Commshare] playerstates exists for player: " .. tostring(playerstates[targetID] == nil) .. "\nSpectator: " .. tostring(targetSpectator))
		end
		if not targetSpectator then
			if not playerstates[targetID] then -- this player has commshared or changed state.
				if debugMode then
					spEcho("[Commshare] generated playerstate table for playerID " .. targetID .. " (" .. targetName .. ")")
				end
				playerstates[targetID] = {active = targetActive, spectator = targetSpectator, teamid = targetTeamID}
			else
				if debugMode then
					spEcho("[Commshare] PlayerChange: " .. targetName .."(ID: " .. targetID ..")\nActive: " .. tostring(playerstates[targetID].active) .. "->" .. tostring(targetActive) .. "\nSpectator: " .. tostring(playerstates[targetID].spectator) .. "->" .. tostring(targetSpectator) .."\nMergeID: " .. tostring(commshareID))
				end
				if targetActive ~= playerstates[targetID].active and targetActive and commshareID then -- this player has reconnected.
					AddUpdatePlayer(targetID, "remerge")
					if debugMode then
						spEcho("[Commshare] Remerged " .. targetName)
					end
				end
				playerstates[targetID].active = targetActive
				playerstates[targetID].spectator = targetSpectator
				playerstates[targetID].teamid = targetTeamID
			end
		elseif spectator and playerstates[targetID] then -- this player resigned
			if debugMode then
				spEcho("[Commshare] Disposing of " .. targetName)
			end
			AddUpdatePlayer(targetID, "dead")
			return
		end
	elseif strFind(command, "accept") then
		if invites[playerID] and invites[playerID][targetID] then
			AcceptInvite(playerID, targetID)
			return
		else
			spEcho("[Commshare] " .. playerID .. "(" .. name .. ") sent an invalid accept command: " .. targetID .. " doesn't exist.")
		end
	elseif strFind(command, "decline") then
		if invites[playerID] then
			invites[playerID][targetID] = nil
		end
	elseif strFind(command, "kick") then
		if IsTeamLeader(playerID) then
			if IsPlayerOnSameTeam(playerID, targetID) then
				UnmergePlayer(targetID)
				return
			else
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") tried to kick a player that isn't on their team! ID: " .. targetID)
				return
			end
		else
			spEcho("[Commshare] " .. playerID .. "(" .. name .. ") isn't a leader! Kick is not allowed.")
			return
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if spGetTeamRulesParam(unitTeam, "isCommsharing") then
		local commshareTeamID = spGetTeamRulesParam(unitTeam, "isCommsharing")
		if debugMode then
			spEcho("[Commshare] unitCreated triggered for " .. unitTeam .. ", given to " .. commshareTeamID)
		end
		spTransferUnit(unitID, commshareTeamID, true) -- this is in case of late commer coms,etc.
	end
end

function gadget:Initialize()
	gadgetHandler:AddChatAction("debugcommshare", ToggleDebug, "Toggles Commshare debugMode echos.")
end
