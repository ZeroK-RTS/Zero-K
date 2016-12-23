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

local private = {private = true}
local public = {public = true}

local function ProccessCommand(str)
	local strtbl = {}
	for w in string.gmatch(str, "%S+") do
	strtbl[#strtbl+1] = w
	end
	return strtbl
end

local modOptions = {}
if (Spring.GetModOptions) then
	modOptions = Spring.GetModOptions()
end

if modOptions.sharemode == "off" then
	gadgetHandler:RemoveGadget()
end

local config = {
	mergetype = modOptions.sharemode,
	unmerging = false,
	mintime	 = 5,
}
-- check config --
if config.mergetype == nil then config.mergetype = "invite"; end

if config.mergetype == "all" then config.unmerging = false else config.unmerging = true end

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

if (gadgetHandler:IsSyncedCode()) then
	local Invites = {}
	local controlledplayers = {}
	local originalplayers = {}
	local originalunits = {}

	local function GetLowestID(list,includeai)
		local lowest = 9001
		local aipresent = false
		local isAI
		for _,id in pairs(list) do
			isAI = select(4,Spring.GetTeamInfo(id))
			if isAI then aipresent = true end
			if id < lowest and id > 0 and isAI == false and includeai == false then lowest = id end
			if id < lowest and id > 0 and includeai == true then lowest = id end
		end
		return lowest,aipresent
	end

	local function UnmergePlayer(player) -- Takes playerid, not teamid!!!
		local name,_ = Spring.GetPlayerInfo(player)
		if originalplayers[player] and config.unmerging then
			Spring.Echo("game_message: Unmerging player " .. name)
			if originalplayers[player] then
				GG.Overdrive.RemoveTeamIncomeRedirect(originalplayers[player]) -- Reset team income/storage.
				local target = originalplayers[player]
				Spring.AssignPlayerToTeam(player,originalplayers[player])
				for _,unit in pairs(originalunits[target]) do
					if Spring.ValidUnitID(unit) and Spring.AreTeamsAllied(Spring.GetUnitTeam(unit),target) then
						Spring.TransferUnit(unit,target,true)
					end
				end
				if Spring.GetTeamRulesParam(originalplayers[player],"isCommsharing") and Spring.GetTeamRulesParam(originalplayers[player],"isCommsharing") == true then
					Spring.SetTeamRulesParam(originalplayers[player],"isCommsharing",false,public)
				end
				originalunits[target] = nil
				target,controlledplayers[player] = nil -- cleanup.
			end
		end
	end
	
	local function MergeUnits(team,target)
		local units = Spring.GetTeamUnits(team)
		originalunits[team] = units
		for i=1, #units do
			if  Spring.ValidUnitID(units[i]) then
				Spring.TransferUnit(units[i],target,true)
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
				Spring.ShareTeamResource(originalteam,target,"metal",metal)
				Spring.ShareTeamResource(originalteam,target,"energy",energy)
				MergeUnits(originalteam,target)
				Spring.SetTeamRulesParam(originalteam,"isCommsharing",true,public)
			end
			Spring.AssignPlayerToTeam(playerid,target)
			if originalplayers[playerid] == nil then
				originalplayers[playerid] = originalteam
			end
			controlledplayers[playerid] = target
			GG.Overdrive.RedirectTeamIncome(originalteam, target)
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
				teamlist = nil
			end
			Invites[player][target] = nil
			Invites[target][player] = nil
		else
			Spring.Echo("[Commshare] Invalid invite: " .. player,target .. "!")
		end
	end		
	
	function gadget:PlayerAdded(playerID)
		if Spring.GetGameFrame() > config.mintime then
			local name,active,spec,team,ally,_	 = Spring.GetPlayerInfo(playerID)
			if spec == false and active == true and config.mergetype ~= "none" and controlledplayers[team] then
				MergePlayer(playerID,controlledplayers[playerID])
				Spring.Echo("game_message: Player " .. name .. "has been remerged!")
			end
		end
	end
	
	function gadget:GameFrame(f)
		if f%30 == 0 then
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
		if f== config.mintime then
			local ally = Spring.GetAllyTeamList()
			Spring.Echo("game_message: Commshare avaliable!")
			if config.mergetype == "all" then
				for i=1,#ally do
					teamlist = Spring.GetTeamList(ally[i])
					if teamlist ~= nil and #teamlist > 1 then
						local mergeid,_ = GetLowestID(teamlist,false)
						for i=1,#teamlist do
							Spring.Echo("Checking team " .. teamlist[i])
							if mergeid == teamlist[i] then
								name = select(1,Spring.GetPlayerInfo(mergeid))
								Spring.Echo("[Commshare] MergeID for allyteam " .. i .. " is " .. mergeid .. "(" .. tostring(name) .. ")")
							else
								_,pid,_,isAi = Spring.GetTeamInfo(teamlist[i])
								if not isAi then
									MergeTeams(teamlist[i],mergeid)
								end
							end
						end
					end
				end
				ally,mergeid,name,isAi = nil
			end
		end
	end
	
	function gadget:RecvLuaMsg(msg,playerid) -- Entry points for widgets to interact with the gadget
		if string.find(msg,"sharemode") then -- Format for messages: sharemode_cmd_aug1_aug2
			local cmdlower = string.lower(msg)
			local proccmd = {}
			proccmd = ProccessCommand(cmdlower)
			--Spring.Echo("Got: " .. proccmd[2] .. " " .. tostring(proccmd[3]))
			if proccmd[2] and string.find(proccmd[2],"invite") then
				if proccmd[3] then
					proccmd[3] = string.gsub(proccmd[3],"%D","")
					if proccmd[3] ~= "" and proccmd[4] then
						SendInvite(playerid,tonumber(proccmd[3]),tonumber(proccmd[4])) -- #4 should be the controller id.
						if Invites[playerid] and Invites[playerid][tonumber(proccmd[3])] and Invites[tonumber(proccmd[3])][playerid] then
							AcceptInvite(playerid,tonumber(proccmd[3]))
						end
						return
					end
				else
					Spring.Echo("[Commshare] " .. playerid .. "(" .. select(1,Spring.GetPlayerInfo(playerid)) .. ") sent an invalid invite!")
					return
				end
			elseif proccmd[2] and string.find(proccmd[2],"accept") then
				if proccmd[3] then proccmd[3] = string.gsub(proccmd[3],"%D","") else return end
				if proccmd[3] and Invites[playerid] and Invites[playerid][tonumber(proccmd[3])] and IsTeamLeader(playerid) then
					AcceptInvite(playerid,tonumber(proccmd[3]))
					return
				elseif not IsTeamLeader(playerid) then
					Spring.Echo("[Commshare] " .. playerid .. "(" .. select(1,Spring.GetPlayerInfo(playerid)) .. ") isn't a leader!")
				end
			elseif proccmd[2] and string.find(proccmd[2],"unmerge") then
				if controlledplayers[playerid] then
					UnmergePlayer(playerid)
					return
				else
					Spring.Echo("[Commshare] " .. playerid .. "(" .. select(1,Spring.GetPlayerInfo(playerid)) .. ") isn't on a squad!")
					return
				end
			elseif proccmd[2] and string.find(proccmd[2],"decline") and IsTeamLeader(playerid) then
				if proccmd[3] then
					proccmd[3] = string.gsub(proccmd[3],"%D","")
					Invites[playerid][tonumber(proccmd[3])] = nil
					return
				elseif not IsTeamLeader(playerid) then
					Spring.Echo("[Commshare] " .. playerid .. "(" .. select(1,Spring.GetPlayerInfo(playerid)) .. ") isn't a leader!")
				else
					Spring.Echo("[Commshare] " .. playerid .. "(" .. select(1,Spring.GetPlayerInfo(playerid)) .. ") sent an invalid invite!")
				end
			elseif proccmd[2] and string.find(proccmd[2],"kick") and proccmd[3] then
				if IsTeamLeader(playerid) then
					proccmd[3] = string.gsub(proccmd[3],"%D","")
					if proccmd[3] then
						if IsPlayerOnSameTeam(playerid,tonumber(proccmd[3])) then
							UnmergePlayer(tonumber(proccmd[3]))
							return
						else
							Spring.Echo("[Commshare] " .. playerid .. "(" .. select(1,Spring.GetPlayerInfo(playerid)) .. ") tried to kick a player that isn't on their team! ID: " .. proccmd[3])
							return
						end
					else
						Spring.Echo("[Commshare] " .. playerid .. "(" .. select(1,Spring.GetPlayerInfo(playerid)) .. ") sent an invalid kick command!")
						return
					end
				else
					Spring.Echo("[Commshare] " .. playerid .. "(" .. select(1,Spring.GetPlayerInfo(playerid)) .. ") isn't a leader!")
					return
				end
			end
		end
	end
	
	function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
		if controlledplayers[unitTeam] then
			Spring.TransferUnit(unitID,controlledplayers[unitTeam],false) -- this is in case of late commer coms,etc. False maybe fixes spamming of unit transfered?
		end
	end
end
