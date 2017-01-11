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
	mintime	 = 5, -- GET RID OF ME EVENTUALLY!
}
modOptions = nil
if config.mergetype == nil then config.mergetype = "invite"; end -- Set the config up in case. This line controls the default state (in case "sharemode" doesn't exist for some reason.)
if config.mergetype == "all" then config.unmerging = false else config.unmerging = true end -- disable unmerging for all mode, but allow it for invite only

------------------ Variables ------------------
local private = {private = true}
local public = {public = true}
local Invites = {}
local controlledplayers = {} -- table containing which team a playerid should be under.
local controlledteams = {} -- contains which team a team of players should be under.
local originalteamids = {} -- takes playerid as the key, gives the team as the value.
local originalunits = {} -- contains which units are owned by a team that has commshared.
local GaiaID = -9999

------------------ speedups ------------------
local gMatch = string.gmatch
local gSub = string.gsub
local Find = string.find
local Lowercase = string.lower
local tonum = tonumber
local tostr = tostring
local Type = type
local Select = select
-- Spring API --
local Echo = Spring.Echo
local GetPlayerInfo = Spring.GetPlayerInfo
local GetTeamInfo = Spring.GetTeamInfo
local GetPlayerList = Spring.GetPlayerList
local AssignPlayerToTeam = Spring.AssignPlayerToTeam
local TransferUnit = Spring.TransferUnit
local ShareTeamResource = Spring.ShareTeamResource
local IsValidUnitID = Spring.ValidUnitID
local AreTeamsAllied = Spring.AreTeamsAllied
local SetTeamRulesParam = Spring.SetTeamRulesParam
local GetTeamList = Spring.GetTeamList
local GetGaiaTeamID = Spring.GetGaiaTeamID
local GetTeamResources = Spring.GetTeamResources
local GetUnitTeam = Spring.GetUnitTeam
local GetTeamUnits = Spring.GetTeamUnits
local GetAllyTeamList = Spring.GetAllyTeamList
local GetGameFrame = Spring.GetGameFrame
------------------ tool box functions ------------------
local function GetTeamID(playerid)
	return Select(4,GetPlayerInfo(playerid))
end

local function GetTeamLeader(teamid)
	return Select(2,GetTeamInfo(teamid))
end

local function IsTeamLeader(playerid)
	local teamid = GetTeamID(playerid)
	local teamleaderid = Select(2,GetTeamInfo(teamid))
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
	return #GetPlayerList(teamid,true)
end


local function ProccessCommand(str)
	local command,aug1,aug2
	local i = 1
	for word in gMatch(str, "%S+") do -- a "word" is anything between two spaces or the start and the first space. So ProccessCommand("1 2 3 4") would return 2 3 4 (first 'word' is ignored, only 2nd,3rd,and 4th count)
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
	return command,aug1,aug2 -- less creating tables this way. Old version would create a table, this one is slightly smarter.
end

local function UnmergePlayer(player) -- Takes playerid, not teamid!!!
	local name,_ = GetPlayerInfo(player)
	if config.unmerging then
		Echo("game_message: Unmerging player " .. name)
		if originalteamids[player] then
			local originalteam = originalteamids[player]
			AssignPlayerToTeam(player,originalteam)
			controlledteams[originalteam] = nil
			local unit
			for i=1,#originalunits[originalteam] do
				unit = originalunits[originalteam][i]
				if IsValidUnitID(unit) and AreTeamsAllied(GetUnitTeam(unit),originalteam) then
					TransferUnit(unit,originalteam,true)
				end
			end
			SetTeamRulesParam(originalteamids[player],"isCommsharing",0,public)
			originalunits[originalteam],controlledplayers[player] = nil
		else
			Echo("[Commshare]: Tried to unmerge a player that never merged (Perhaps cheated in?)")
		end
	else
		Echo("[Commshare]: Unmerging is forbidden in this game mode!")
	end
end
	
local function MergeUnits(team,target)
	originalunits[team] = GetTeamUnits(team)
	local unit
	for i=1, #originalunits[team] do
		unit = originalunits[team][i]
		if IsValidUnitID(unit) then
			TransferUnit(unit,target,true)
		end
	end
end
	
local function MergePlayer(playerid,target)
	if playerid == nil then
		Echo("[Commshare] Tried to merge a nil player!")
		return
	end
	local originalteam = GetTeamID(playerid)
	local name,_,spec,_,_,allyteam  = GetPlayerInfo(playerid)
	if AreTeamsAllied(originalteam,target) and spec == false and target ~= GaiaID and config.mergetype ~= "none" then
		Echo("[Commshare] Assigning player id " .. playerid .. "(" .. name .. ") to team " .. target)
		if GetSquadSize(originalteam) - 1 == 0 then
			local metal = GetTeamResources(originalteam,"metal")
			local energy = GetTeamResources(originalteam,"energy")
			controlledteams[originalteam] = target
			ShareTeamResource(originalteam,target,"metal",metal)
			ShareTeamResource(originalteam,target,"energy",energy)
			MergeUnits(originalteam,target)
			SetTeamRulesParam(originalteam,"isCommsharing",1,public)
		end
		AssignPlayerToTeam(playerid,target)
		if originalteamids[playerid] == nil then
			originalteamids[playerid] = originalteam
		end
		controlledplayers[playerid] = target
	else
		Echo("[Commshare] Merger error.")
	end
end

local function MergeTeams(team1,team2) -- bandaid for an issue during planning.
	local playerlist = GetPlayerList(team1,true)
	local playerlist2 = GetPlayerList(team2,true)
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

local function MergeAllHumans(teamlist)
	local mergeid = -1
	local AI
	for i=1,#teamlist do
		AI = Select(4,GetTeamInfo(teamlist[i]))
		if not AI and mergeid ~= -1 then
			Echo("[Commshare] Merging team " .. teamlist[i])
			MergeTeams(teamlist[i],mergeid)
		elseif not AI and mergeid == -1 then
			mergeid = teamlist[i]
			Echo("[Commshare] MergeID for ally " .. ally .. " is " .. mergeid)
		end
	end
end

local function MergeAll()
	local ally = GetAllyTeamList()
	for i=1,#ally do
		local teamlist = GetTeamList(ally[i])
		if #teamlist > 1 then
			MergeAllHumans(teamlist)
		end
	end
end

local function SendInvite(player,target,targetid) -- targetplayer is which player is the merger
	if GetGameFrame() > config.mintime then
		local targetspec = Select(3,GetPlayerInfo(target))
		local _,_,dead,ai,_ = GetTeamInfo(GetTeamID(target))
		if player == target then
			Echo("[Commshare] " .. player .. "(" .. Select(1,GetPlayerInfo(player)) .. ") tried to merge with theirself!")
			return
		end
		if not IsTeamLeader(player) and targetid ~= player then
			Echo("[Commshare] " .. player .. "(" .. Select(1,GetPlayerInfo(player)) .. ") tried to send an invite as a member of a squad (You must be leader!)!")
			return
		end
		if targetspec then
			Echo("[Commshare] " .. player .. "(" .. Select(1,GetPlayerInfo(player)) .. ") tried to merge with spectator!")
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
	Echo("verifying invite")
	if Invites[player][target] then
		Echo("invite verified")
		if Invites[player][target]["controller"] ~= player then
			MergePlayer(player,GetTeamID(target))
		else -- target->player
			MergeTeams(GetTeamID(target),GetTeamID(player))
		end
		Invites[player][target] = nil
		Invites[target][player] = nil
	else
		Echo("[Commshare] Invalid invite: " .. player,target .. "!")
	end
end

------------------ Callins ------------------
function gadget:PlayerAdded(playerID)
	local name,active,spec,team,ally,_	 = GetPlayerInfo(playerID)
	if not spec and active and controlledplayers[playerID] then
		MergePlayer(playerID,controlledplayers[playerID])
		Echo("game_message: Player " .. name .. "has been remerged!")
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
					SetTeamRulesParam(GetTeamID(player),"commshare_invite_"..invitecount.."_timeleft",data["timeleft"],private)
					SetTeamRulesParam(GetTeamID(player),"commshare_invite_"..invitecount.."_id",data["id"],private)
					SetTeamRulesParam(GetTeamID(player),"commshare_invite_"..invitecount.."_controller",data["controller"],private)
				end
			end
			SetTeamRulesParam(GetTeamID(player),"commshare_invitecount",invitecount,private)
			if invitecount == 0 then -- Cleanup the table so that next second this doesn't run.
				Invites[player] = nil
			end
		end
	end
	if frame == config.mintime and config.mergetype == "all" then
		MergeAll()
	end
end
	
function gadget:RecvLuaMsg(message,playerid) -- Entry points for widgets to interact with the gadget
	if Find(message,"sharemode") then
		local command,aug1,aug2 = ProccessCommand(Lowercase(message))
		local name = Select(1,GetPlayerInfo(playerid)) 
		if command == nil then
			Echo("[Commshare] " .. player .. "(" .. name .. ") sent an invalid command")
			return
		end
		-- process augs --
		if aug1 then
			aug1 = gSub(aug1,"%D","")
			if aug1 ~= "" then
				aug1 = tonum(aug1)
			end
		end
		if aug2 then
			aug2 = gSub(aug2,"%D","")
			if aug2 ~= "" then
				aug2 = tonum(aug2)
			end
		end
		-- Do commands --
		if Find(command,"invite") then
			if Type(aug1) == "number" and Type(aug2) == "number" then
				SendInvite(playerid,aug1,aug2) -- #4 should be the controller id.
				if Invites[playerid] and Invites[playerid][aug1] and Invites[aug1][playerid] then
					AcceptInvite(playerid,aug1)
				end
				return
			else
				Echo("[Commshare] " .. playerid .. "(" .. name .. ") sent an invalid invite!")
				return
			end
		elseif Find(command,"accept") then
			if Type(aug1) ~= "number" then
				Echo("[Commshare] " .. playerid .. "(" .. name .. ") sent an invalid augment for Accept.")
				return
			end
			if Invites[playerid] and Invites[playerid][aug1] and IsTeamLeader(playerid) then
				AcceptInvite(playerid,aug1)
				return
			elseif not IsTeamLeader(playerid) then
				Echo("[Commshare] " .. playerid .. "(" .. name .. ") isn't a leader!")
			end
		elseif Find(command,"unmerge") then
			if controlledplayers[playerid] then
				UnmergePlayer(playerid)
				return
			else
				Echo("[Commshare] " .. playerid .. "(" .. name .. ") isn't on a squad!")
				return
			end
		elseif Find(command,"decline") and IsTeamLeader(playerid) then
			if Type(aug1) == "number" and IsTeamLeader(playerid) then
				Invites[playerid][aug1] = nil
				return
			elseif IsTeamLeader(playerid) then
				Echo("[Commshare] " .. playerid .. "(" .. name .. ") isn't a leader! Cannot decline this invite.")
				return
			else
				Echo("[Commshare] " .. playerid .. "(" .. name .. ") sent an invalid aug for Decline.")
				return
			end
		elseif Find(command,"kick") then
			if IsTeamLeader(playerid) and Type(aug1) == "number" then
				if IsPlayerOnSameTeam(playerid,aug1) then
					UnmergePlayer(aug1)
					return
				else
					Echo("[Commshare] " .. playerid .. "(" .. name .. ") tried to kick a player that isn't on their team! ID: " .. aug1)
					return
				end
			elseif Type(aug1) ~= "number" and IsTeamLeader(playerid) then
				Echo("[Commshare] " .. playerid .. "(" .. name .. ") sent an invalid kick command!")
				return
			else
				Echo("[Commshare] " .. playerid .. "(" .. name .. ") isn't a leader! Cannot kick this player.")
				return
			end
		end
	end
end

function gadget:GameStart()
	GaiaID = GetGaiaTeamID
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if controlledteams[unitTeam] then
		TransferUnit(unitID,controlledteams[unitTeam],true) -- this is in case of late commer coms,etc.
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if controlledteams[newTeam] then
		TransferUnit(unitID,controlledteams[newTeam],true)
	end
end
