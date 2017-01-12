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

local private = {private = true}
local public = {public = true}
local GaiaID = -9999

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
	Spring.spEcho("[Commshare] Commshare is off. Shutting down.")
	gadgetHandler:RemoveGadget()
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
	return select(4, spGetPlayerInfo(playerID))
end

local function GetTeamLeader(teamID)
	return select(2, spGetTeamInfo(teamID))
end

local function IsTeamLeader(playerID)
	local teamID = GetTeamID(playerID)
	local teamleaderid = select(2, spGetTeamInfo(teamID))
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
	local command, aug1, aug2
	local i = 1
	-- A "word" is anything between two spaces or the start and the first space. So ProccessCommand("1 2 3 4")
	-- would return 2 3 4 (first 'word' is ignored, only 2nd, 3rd, and 4th count).
	for word in strGmatch(str, "%S+") do 
		if i == 2 then
			command = word
		elseif i == 3 then
			aug1 = word
		elseif i == 4 then
			aug2 = word
			break
		end
		i = i + 1
	end
	return command, aug1, aug2 -- less creating tables this way. Old version would create a table, this one is slightly smarter.
end

local function UnmergePlayer(playerID) -- Takes playerID, not teamID!!!
	local name,_ = spGetPlayerInfo(playerID)
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
			spSetTeamRulesParam(originalTeamID[playerID], "isCommsharing", 0, public)
			originalUnits[orgTeamID],controlledPlayers[playerID] = nil
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
	local name,_,spec,_,_,allyteam  = spGetPlayerInfo(playerID)
	if spAreTeamsAllied(orgTeamID,target) and (not spec) and target ~= GaiaID then
		spEcho("[Commshare] Assigning player id " .. playerID .. "(" .. name .. ") to team " .. target)
		if GetSquadSize(orgTeamID) - 1 == 0 then
			local metal = spGetTeamResources(orgTeamID,"metal")
			local energy = spGetTeamResources(orgTeamID,"energy")
			controlledTeams[orgTeamID] = target
			spShareTeamResource(orgTeamID,target,"metal",metal)
			spShareTeamResource(orgTeamID,target,"energy",energy)
			MergeUnits(orgTeamID,target)
			spSetTeamRulesParam(orgTeamID,"isCommsharing",1,public)
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
	local playerlist2 = spGetPlayerList(team2,true)
	if GetSquadSize(team1) >= GetSquadSize(team2) then
		for i = 1, #playerlist do
			MergePlayer(playerlist[i],team2)
		end
	else
		for i = 1, #playerlist2 do
			MergePlayer(playerlist2[i],team1)
		end
	end
end

local function MergeAllHumans(teamlist)
	local mergeid = -1
	local AI
	for i = 1, #teamlist do
		AI = select(4, spGetTeamInfo(teamlist[i]))
		if not AI and mergeid ~= -1 then
			spEcho("[Commshare] Merging team " .. teamlist[i])
			MergeTeams(teamlist[i], mergeid)
		elseif not AI and mergeid == -1 then
			mergeid = teamlist[i]
			spEcho("[Commshare] MergeID for ally ???? is " .. mergeid)
		end
	end
end

local function MergeAll()
	local ally = spGetAllyTeamList()
	for i = 1, #ally do
		local teamlist = spGetTeamList(ally[i])
		if #teamlist > 1 then
			MergeAllHumans(teamlist)
		end
	end
end

local function SendInvite(player, target, targetid) -- targetplayer is which player is the merger
	if spGetGameFrame() > config.mintime then
		local targetspec = select(3, spGetPlayerInfo(target))
		local _,_,dead,ai,_ = spGetTeamInfo(GetTeamID(target))
		if player == target then
			spEcho("[Commshare] " .. player .. "(" .. select(1,spGetPlayerInfo(player)) .. ") tried to merge with theirself!")
			return
		end
		if not IsTeamLeader(player) and targetid ~= player then
			spEcho("[Commshare] " .. player .. "(" .. select(1,spGetPlayerInfo(player)) .. ") tried to send an invite as a member of a squad (You must be leader!)!")
			return
		end
		if targetspec then
			spEcho("[Commshare] " .. player .. "(" .. select(1,spGetPlayerInfo(player)) .. ") tried to merge with spectator!")
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
			invites[target][player] = {id = player, timeleft = 60, controller = targetid}
		end
	end
end

local function AcceptInvite(player,target)
	spEcho("verifying invite")
	if invites[player][target] then
		spEcho("invite verified")
		if invites[player][target]["controller"] ~= player then
			MergePlayer(player,GetTeamID(target))
		else -- target->player
			MergeTeams(GetTeamID(target),GetTeamID(player))
		end
		invites[player][target] = nil
		invites[target][player] = nil
	else
		spEcho("[Commshare] Invalid invite: " .. player,target .. "!")
	end
end

------------------ Callins ------------------
function gadget:PlayerAdded(playerID)
	local name,active,spec = spGetPlayerInfo(playerID)
	if not spec and active and controlledPlayers[playerID] then
		MergePlayer(playerID, controlledPlayers[playerID])
		spEcho("game_message: Player " .. name .. "has been remerged!")
	end
end
	
function gadget:GameFrame(frame)
	if frame%30 == 0 then
		local invitecount
		for player, invites in pairs(invites) do
			invitecount = 0
			for key,data in pairs(invites) do
				invitecount = invitecount+1
				if data.timeleft > 0 then
					data.timeleft = data.timeleft - 1
				end
				if data.timeleft == -1 then 
					-- this is so we know an invite has expired. UI will remove the invite at timeleft = 0, 
					-- but gadget will remove it at -1. Otherwise UI will just see it constantly at 1.
					invitecount = invitecount-1
					invites[key] = nil
				end
				if data and data.timeleft > -1 then
					spSetTeamRulesParam(GetTeamID(player), "commshare_invite_" .. invitecount .. "_timeleft", data.timeleft, private)
					spSetTeamRulesParam(GetTeamID(player), "commshare_invite_" .. invitecount .. "_id", data.id, private)
					spSetTeamRulesParam(GetTeamID(player), "commshare_invite_" .. invitecount .. "_controller", data.controller, private)
				end
			end
			spSetTeamRulesParam(GetTeamID(player),"commshare_invitecount",invitecount,private)
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
	if strFind(message,"sharemode") then
		local command,aug1,aug2 = ProccessCommand(strLower(message))
		local name = select(1, spGetPlayerInfo(playerID)) 
		if command == nil then
			spEcho("[Commshare] " .. player .. "(" .. name .. ") sent an invalid command")
			return
		end
		-- process augs --
		if aug1 then
			aug1 = strGsub(aug1,"%D","")
			if aug1 ~= "" then
				aug1 = tonumber(aug1)
			end
		end
		if aug2 then
			aug2 = strGsub(aug2,"%D","")
			if aug2 ~= "" then
				aug2 = tonumber(aug2)
			end
		end
		-- Do commands --
		if strFind(command, "invite") then
			if type(aug1) == "number" and type(aug2) == "number" then
				SendInvite(playerID, aug1, aug2) -- #4 should be the controller id.
				if invites[playerID] and invites[playerID][aug1] and invites[aug1][playerID] then
					AcceptInvite(playerID,aug1)
				end
				return
			else
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") sent an invalid invite!")
				return
			end
		elseif strFind(command, "accept") then
			if type(aug1) ~= "number" then
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") sent an invalid augment for Accept.")
				return
			end
			if invites[playerID] and invites[playerID][aug1] and IsTeamLeader(playerID) then
				AcceptInvite(playerID,aug1)
				return
			elseif not IsTeamLeader(playerID) then
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") isn't a leader!")
			end
		elseif strFind(command,"unmerge") then
			if controlledPlayers[playerID] then
				UnmergePlayer(playerID)
				return
			else
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") isn't on a squad!")
				return
			end
		elseif strFind(command,"decline") and IsTeamLeader(playerID) then
			if type(aug1) == "number" and IsTeamLeader(playerID) then
				invites[playerID][aug1] = nil
				return
			elseif IsTeamLeader(playerID) then
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") isn't a leader! Cannot decline this invite.")
				return
			else
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") sent an invalid aug for Decline.")
				return
			end
		elseif strFind(command,"kick") then
			if IsTeamLeader(playerID) and type(aug1) == "number" then
				if IsPlayerOnSameTeam(playerID,aug1) then
					UnmergePlayer(aug1)
					return
				else
					spEcho("[Commshare] " .. playerID .. "(" .. name .. ") tried to kick a player that isn't on their team! ID: " .. aug1)
					return
				end
			elseif type(aug1) ~= "number" and IsTeamLeader(playerID) then
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") sent an invalid kick command!")
				return
			else
				spEcho("[Commshare] " .. playerID .. "(" .. name .. ") isn't a leader! Cannot kick this player.")
				return
			end
		end
	end
end

function gadget:GameStart()
	GaiaID = Spring.GetGaiaTeamID
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if controlledTeams[unitTeam] then
		spTransferUnit(unitID, controlledTeams[unitTeam], true) -- this is in case of late commer coms,etc.
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if controlledTeams[newTeam] then
		spTransferUnit(unitID, controlledTeams[newTeam], true)
	end
end
