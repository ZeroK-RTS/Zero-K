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

local modOptions = {}
modOptions = Spring.GetModOptions()

if modOptions["sharemode"] == "off" then
	Spring.Echo("[Commshare] Commshare is off. Shutting down.")
	gadgetHandler:RemoveGadget()
end

-- set up config --
local config = {
	mergetype = modOptions["sharemode"],
	unmerging = false,
	mintime	 = 5,
}
modOptions = nil -- no longer needed.
if config.mergetype == nil then config.mergetype = "invite"; end
if config.mergetype == "all" then config.unmerging = false else config.unmerging = true end

------------------ Variables ------------------
local private = {private = true}
local public = {public = true}
local Invites = {}
local coroutinestate = false -- Used for staggering. When false, it means it's done/not started. When true, it is suspended/executing.
local controlledplayers = {} -- table containing which team a playerid should be under.
local controlledteams = {} -- contains which team a team of players should be under.
local originalteamids = {} -- takes playerid as the key, gives the team as the value.
local originalunits = {} -- contains which units are owned by a team that has commshared.

------------------ tool box functions ------------------
local function GetTeamID(playerid)
	return select(4,Spring.GetPlayerInfo(playerid))
end

local function GetTeamLeader(teamid)
	return select(2,Spring.GetTeamInfo(teamid))
end

local function IsTeamLeader(playerid)
	local teamid = GetTeamID(playerid)
	local teamleaderid = select(2,Spring.GetTeamInfo(teamid))
	if playerid == teamleaderid then
		teamid,teamleaderid = nil
		return true
	else
		teamid,teamleaderid = nil
		return false
	end
end

local function IsPlayerOnSameTeam(playerid,playerid2)
	local id1 = GetTeamID(playerid)
	local id2 = GetTeamID(playerid2)
	if id1 == id2 then
		id1,id2 = nil
		return true
	else
		id1,id2 = nil
		return false
	end
end

local function GetSquadSize(teamid)
	return #Spring.GetPlayerList(teamid,true)
end


local function ProccessCommand(str)
	local command,aug1,aug2
	local i = 1
	for word in string.gmatch(str, "%S+") do
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
	return command,aug1,aug2 -- less creating tables this way
end

local function UnmergePlayer(player) -- Takes playerid, not teamid!!!
	local name,_ = Spring.GetPlayerInfo(player)
	if config.unmerging then
		Spring.Echo("game_message: Unmerging player " .. name)
		if originalteamids[player] then
			local originalteam = originalteamids[player]
			Spring.AssignPlayerToTeam(player,originalteam)
			controlledteams[originalteam] = nil
			local unit
			for i=1,#originalunits[originalteam] do
				unit = originalunits[originalteam][i]
				if Spring.ValidUnitID(unit) and Spring.AreTeamsAllied(Spring.GetUnitTeam(unit),originalteam) then
					Spring.TransferUnit(unit,originalteam,true)
				end
			end
			Spring.SetTeamRulesParam(originalteamids[player],"isCommsharing",0,public)
			originalunits[originalteam],controlledplayers[player] = nil
		else
			Spring.Echo("[Commshare]: Tried to unmerge a player that never merged (Perhaps cheated in?)")
		end
	else
		Spring.Echo("[Commshare]: Unmerging is forbidden in this game mode!")
	end
end
	
local function MergeUnits(team,target)
	originalunits[team] = Spring.GetTeamUnits(team)
	local unit
	for i=1, #originalunits[team] do
		unit = originalunits[team][i]
		if Spring.ValidUnitID(unit) then
			Spring.TransferUnit(unit,target,true)
		end
	end
end
	
local function MergePlayer(playerid,target)
	if playerid == nil then
		Spring.Echo("[Commshare] Tried to merge a nil player!")
		return
	end
	local originalteam = GetTeamID(playerid)
	local name,_,spec  = Spring.GetPlayerInfo(playerid)
	if Spring.AreTeamsAllied(originalteam,target) and spec == false and target ~= Spring.GetGaiaTeamID() and config.mergetype ~= "none" then
		Spring.Echo("[Commshare] Assigning player id " .. playerid .. "(" .. name .. ") to team " .. target)
		local name,_,spec,_,_,allyteam = Spring.GetPlayerInfo(playerid)
		if GetSquadSize(originalteam) - 1 == 0 then
			local metal = Spring.GetTeamResources(originalteam,"metal")
			local energy = Spring.GetTeamResources(originalteam,"energy")
			controlledteams[originalteam] = target
			Spring.ShareTeamResource(originalteam,target,"metal",metal)
			Spring.ShareTeamResource(originalteam,target,"energy",energy)
			MergeUnits(originalteam,target)
			Spring.SetTeamRulesParam(originalteam,"isCommsharing",1,public)
		end
		Spring.AssignPlayerToTeam(playerid,target)
		if originalteamids[playerid] == nil then
			originalteamids[playerid] = originalteam
		end
		controlledplayers[playerid] = target
	else
		Spring.Echo("[Commshare] Merger error.")
	end
end

local function MergeTeams(team1,team2) -- bandaid for an issue during planning.
	local playerlist = Spring.GetPlayerList(team1,true)
	local playerlist2 = Spring.GetPlayerList(team2,true)
	if GetSquadSize(team1) >= GetSquadSize(team2) then
		for i=1,#playerlist do
			MergePlayer(playerlist[i],team2)
		end
	else
		for i=1,#playerlist2 do
			MergePlayer(playerlist2[i],team1)
		end
	end
	playerlist,playerlist2 = nil
end

local function MergeAllHumans(ally)
	local teamlist = Spring.GetTeamList(ally)
	local mergeid = -1
	local AI
	for i=1,#teamlist do
		AI = select(4,Spring.GetTeamInfo(teamlist[i]))
		if not AI and mergeid ~= -1 then
			Spring.Echo("[Commshare] Merging team " .. teamlist[i])
			MergeTeams(teamlist[i],mergeid)
		elseif not AI and mergeid == -1 then
			mergeid = teamlist[i]
			Spring.Echo("[Commshare] MergeID for ally " .. ally .. " is " .. mergeid)
		end
	end
end

local function MergeAll() -- Coroutine, only allow 5 teams to be merged per 2 frames.
	local ally = Spring.GetAllyTeamList()
	local teammanagement = 1
	local neededteams = 0
	for i=1,#ally do
		local teamlist = Spring.GetTeamList(ally[i])
		if #teamlist > 1 then
			if #teamlist < 5 then
				MergeAllHumans(ally[i])
			else -- do up to 5 here.
				local AI
				local mergeid = -1
				local count = 0
				for i=1,#teamlist do
					count = count + 1
					AI = select(4,Spring.GetTeamInfo(teamlist[i]))
					if not AI and mergeid ~= -1 then
						Spring.Echo("[Commshare] Merging team " .. teamlist[i])
						MergeTeams(teamlist[i],mergeid)
					elseif not AI and mergeid == -1 then
						mergeid = teamlist[i]
						Spring.Echo("[Commshare] MergeID for ally " .. ally .. " is " .. mergeid)
					end
					if count > 5 then
						count = 0
						coroutine.yield()
					end
				end
			end
		end
		coroutine.yield()
	end
	coroutinestate = false
end

local function SendInvite(player,target,targetid) -- targetplayer is which player is the merger
	if Spring.GetGameFrame() > config.mintime then
		local targetspec = select(3,Spring.GetPlayerInfo(target))
		local _,_,dead,ai,_ = Spring.GetTeamInfo(GetTeamID(target))
		if player == target then
			Spring.Echo("[Commshare] " .. player .. "(" .. select(1,Spring.GetPlayerInfo(player)) .. ") tried to merge with theirself!")
			return
		end
		if not IsTeamLeader(player) and targetid ~= player then
			Spring.Echo("[Commshare] " .. player .. "(" .. select(1,Spring.GetPlayerInfo(player)) .. ") tried to send an invite as a member of a squad (You must be leader!)!")
			return
		end
		if targetspec then
			Spring.Echo("[Commshare] " .. player .. "(" .. select(1,Spring.GetPlayerInfo(player)) .. ") tried to merge with spectator!")
			return
		end
		if targetid == player then
			local teamid = GetTeamID(target)
			target = GetTeamLeader(teamid)
		end
		if not dead and not ai then
			if Invites[target] == nil then
				Invites[target] = {}
			end
			Invites[target][player] = {id = player,timeleft = 60,controller = targetid}
		end
	end
end
		
local function AcceptInvite(player,target)
	Spring.Echo("verifying invite")
	if Invites[player][target] then
		Spring.Echo("invite verified")
		if Invites[player][target]["controller"] ~= player then
			MergePlayer(player,GetTeamID(target))
		else -- target->player
			MergeTeams(GetTeamID(target),GetTeamID(player))
		end
		Invites[player][target] = nil
		Invites[target][player] = nil
	else
		Spring.Echo("[Commshare] Invalid invite: " .. player,target .. "!")
	end
end

------------------ Callins ------------------
function gadget:PlayerAdded(playerID)
	local name,active,spec,team,ally,_	 = Spring.GetPlayerInfo(playerID)
	if not spec and active and controlledplayers[playerID] then
		MergePlayer(playerID,controlledplayers[playerID])
		Spring.Echo("game_message: Player " .. name .. "has been remerged!")
	end
end
	
function gadget:GameFrame(frame)
	if frame%30 == 0 then
		local invitecount
		for player,invites in pairs(Invites) do
			invitecount = 0
			for key,data in pairs(invites) do
				invitecount = invitecount+1
				if data["timeleft"] > 0 then
					data["timeleft"] = data["timeleft"] - 1
				end
				if data["timeleft"] == -1 then -- this is so we know an invite has expired. UI will remove the invite at timeleft = 0, but gadget will remove it at -1. Otherwise UI will just see it constantly at 1.
					invitecount = invitecount-1
					invites[key] = nil
				end
				if data and data["timeleft"] > -1 then
					Spring.SetTeamRulesParam(GetTeamID(player),"commshare_invite_"..invitecount.."_timeleft",data["timeleft"],private)
					Spring.SetTeamRulesParam(GetTeamID(player),"commshare_invite_"..invitecount.."_id",data["id"],private)
					Spring.SetTeamRulesParam(GetTeamID(player),"commshare_invite_"..invitecount.."_controller",data["controller"],private)
				end
			end
			Spring.SetTeamRulesParam(GetTeamID(player),"commshare_invitecount",invitecount,private)
			if invitecount == 0 then -- Cleanup the table so that next second this doesn't run.
				Invites[player] = nil
			end
		end
	end
	if frame == config.mintime and config.mergetype == "all" then
		staggeredmerge = coroutine.create(function () MergeAll(); end)
		coroutinestate = true
	end
	if coroutinestate == true and frame%2 == 0 then
		coroutine.resume(staggeredmerge)
	end
end
	
function gadget:RecvLuaMsg(message,playerid) -- Entry points for widgets to interact with the gadget
	if string.find(message,"sharemode") then
		local command,aug1,aug2 = ProccessCommand(string.lower(message))
		local name = select(1,Spring.GetPlayerInfo(playerid)) 
		if command == nil then
			Spring.Echo("[Commshare] " .. player .. "(" .. name .. ") sent an invalid command")
			return
		end
		-- process augs --
		if aug1 then
			aug1 = string.gsub(aug1,"%D","")
			if aug1 ~= "" then
				aug1 = tonumber(aug1)
			end
		end
		if aug2 then
			aug2 = string.gsub(aug2,"%D","")
			if aug2 ~= "" then
				aug2 = tonumber(aug2)
			end
		end
		-- Do commands --
		if string.find(command,"invite") then
			if type(aug1) == "number" and type(aug2) == "number" then
				SendInvite(playerid,aug1,aug2) -- #4 should be the controller id.
				if Invites[playerid] and Invites[playerid][aug1] and Invites[aug1][playerid] then
					AcceptInvite(playerid,aug1)
				end
				return
			else
				Spring.Echo("[Commshare] " .. playerid .. "(" .. name .. ") sent an invalid invite!")
				return
			end
		elseif string.find(command,"accept") then
			if type(aug1) ~= "number" then
				Spring.Echo("[Commshare] " .. playerid .. "(" .. name .. ") sent an invalid augment for Accept.")
				return
			end
			if Invites[playerid] and Invites[playerid][aug1] and IsTeamLeader(playerid) then
				AcceptInvite(playerid,aug1)
				return
			elseif not IsTeamLeader(playerid) then
				Spring.Echo("[Commshare] " .. playerid .. "(" .. name .. ") isn't a leader!")
			end
		elseif string.find(command,"unmerge") then
			if controlledplayers[playerid] then
				UnmergePlayer(playerid)
				return
			else
				Spring.Echo("[Commshare] " .. playerid .. "(" .. name .. ") isn't on a squad!")
				return
			end
		elseif string.find(command,"decline") and IsTeamLeader(playerid) then
			if type(aug1) == "number" and IsTeamLeader(playerid) then
				Invites[playerid][aug1] = nil
				return
			elseif IsTeamLeader(playerid) then
				Spring.Echo("[Commshare] " .. playerid .. "(" .. name .. ") isn't a leader! Cannot decline this invite.")
				return
			else
				Spring.Echo("[Commshare] " .. playerid .. "(" .. name .. ") sent an invalid aug for Decline.")
				return
			end
		elseif string.find(command,"kick") then
			if IsTeamLeader(playerid) and type(aug1) == "number" then
				if IsPlayerOnSameTeam(playerid,aug1) then
					UnmergePlayer(aug1)
					return
				else
					Spring.Echo("[Commshare] " .. playerid .. "(" .. name .. ") tried to kick a player that isn't on their team! ID: " .. aug1)
					return
				end
			elseif type(aug1) ~= "number" and IsTeamLeader(playerid) then
				Spring.Echo("[Commshare] " .. playerid .. "(" .. name .. ") sent an invalid kick command!")
				return
			else
				Spring.Echo("[Commshare] " .. playerid .. "(" .. name .. ") isn't a leader! Cannot kick this player.")
				return
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if controlledteams[unitTeam] then
		Spring.TransferUnit(unitID,controlledteams[unitTeam],true) -- this is in case of late commer coms,etc.
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if controlledteams[newTeam] then
		Spring.TransferUnit(unitID,controlledteams[newTeam],true)
	end
end
