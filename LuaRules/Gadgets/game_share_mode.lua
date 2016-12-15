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

local function ProccessCommand(str)
	local strtbl = {}
	for w in string.gmatch(str, "%S+") do
	strtbl[#strtbl+1] = w
	end
	return strtbl
end

local function tobool(var)
	Spring.Echo("tobool: " .. tostring(var))
	if tonumber(var) == 1 or tostring(var) == "true" then
		return true
	elseif var ~= nil then
		return false
	else
		return nil
	end
end

local modOptions = {}
if (Spring.GetModOptions) then
	modOptions = Spring.GetModOptions()
end

if modOptions.sharemode == "off" then
	gadgetHandler:RemoveGadget()
end

local validmodes = {};validmodes["all"] = true;validmodes["none"] = true;validmodes["invite"] = true

local config = {
	default = "invite",
	mergetype = modOptions.sharemode,
	unmerging = false,
	mintime	 = 5,
}
-- check config --
if config.mergetype == nil then config.mergetype = "invite"; end

if config.mergetype == "all" then config.unmerging = false else config.unmerging = true end

--Spring.Echo("Config:\n" .. "\nmergetype:" .. config.mergetype .. "\nantigrief:" .. tostring(config.antigrief) .. "\nunmerging: " .. tostring(config.unmerging))

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
			Spring.Echo("Commshare: Tried to merge a nil player!")
			return
		end
		local originalteam = GetTeamID(playerid)
		local name,_,spec  = Spring.GetPlayerInfo(playerid)
		if Spring.AreTeamsAllied(originalteam,target) and spec == false and target ~= Spring.GetGaiaTeamID() and config.mergetype ~= "none" then
			Spring.Echo("Commshare: Assigning player id " .. playerid .. "(" .. name .. ") to team " .. target)
			local name,_,spec,_,_,allyteam = Spring.GetPlayerInfo(playerid)
			if GetSquadSize(originalteam) - 1 == 0 then
				local metal = select(1,Spring.GetTeamResources(originalteam,"metal"))
				local energy = select(1,Spring.GetTeamResources(originalteam,"energy"))
				Spring.ShareTeamResource(originalteam,target,"metal",metal)
				Spring.ShareTeamResource(originalteam,target,"energy",energy)
				MergeUnits(originalteam,target)
			end
			Spring.AssignPlayerToTeam(playerid,target)
			if originalplayers[playerid] == nil then
				originalplayers[playerid] = originalteam
			end
			controlledplayers[playerid] = target
			GG.Overdrive.RedirectTeamIncome(originalteam, target)
			SendToUnsynced("mergealert",playerid,target) -- Notifier
		else
			Spring.Echo("Commshare: Merger error.")
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
			local _,_,dead,ai,_ = Spring.GetTeamInfo(GetTeamID(targetid))
			if player == target then
				SendToUnsynced("errors",player,"You can't merge with yourself!")
				return
			end
			if not IsTeamLeader(player) and targetid ~= player then
				SendToUnsynced("errors",player,"You can't invite players when you aren't the team leader!")
				return
			end
			if targetspec then
				SendToUnsynced("errors",player,"You can't merge with specs!")
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
		if Invites[player][target] and Invites[target][player] then
			Spring.Echo("invite verified")
			if Invites[player][target]["controller"] ~= player then
				MergePlayer(target,GetTeamID(player))
			else -- target->player
				MergeTeams(GetTeamID(target),GetTeamID(player))
				teamlist = nil
			end
			Invites[player][target] = nil
			Invites[target][player] = nil
		else
			SendToUnsynced("errors",player,"Invalid merge request!")
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
	
	function gadget:GameStart()
		Spring.SetGameRulesParam("sharemode",config.mergetype)
	end
	
	function gadget:GameFrame(f)
		if f%30 == 0 then
			local invitestring
			for player,invites in pairs(Invites) do
				invitestring = ""
				for key,data in pairs(invites) do
					if data["timeleft"] > 0 then
						data["timeleft"] = data["timeleft"] - 1
					end
					if data["timeleft"] == 0 then
						invites[key] = nil
					end
					if data and invitestring ~= "" and data["timeleft"] > 0 then
						invitestring = invitestring .. ", " .. data["id"] .. " " .. data["timeleft"] .. " " .. data["controller"]
					else
						invitestring = data["id"] .. " " .. data["timeleft"] .. " " .. data["controller"]
					end
				end
				Spring.Echo("DEBUG: Got Invitestring: " .. invitestring)
				Spring.SetTeamRulesParam(GetTeamID(player),"invites",invitestring,{private=true})
				if invitestring == "" then -- Cleanup the table so that next second this doesn't run.
					Invites[player] = nil
				end
			end
		end
		if f== config.mintime then
			local ally = Spring.GetAllyTeamList()
			Spring.Echo("game_message: Share mode avaliable!")
			if config.mergetype == "all" then
				for i=1,#ally do
					teamlist = Spring.GetTeamList(ally[i])
					if teamlist ~= nil and #teamlist > 1 then
						local mergeid,_ = GetLowestID(teamlist,false)
						for i=1,#teamlist do
							Spring.Echo("Checking team " .. teamlist[i])
							if mergeid == teamlist[i] then
								name = select(1,Spring.GetPlayerInfo(mergeid))
								Spring.Echo("MergeID is " .. mergeid .. "(" .. tostring(name) .. ")")
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
					SendToUnsynced("errors",playerid,"Error: Invalid invite!")
					return
				end
			elseif proccmd[2] and string.find(proccmd[2],"accept") then
				proccmd[3] = string.gsub(proccmd[3],"%D","")
				if proccmd[3] then proccmd[3] = tonumber(proccmd[3]) end
				if proccmd[3] and Invites[proccmd[3]] and Invites[proccmd[3]][playerid] and IsTeamLeader(playerid) then
					AcceptInvite(proccmd[3],playerid)
					Spring.Echo("invite accepted")
					return
				elseif not IsTeamLeader(playerid) then
					SendToUnsynced("errors",playerid,"You aren't team leader! You can't accept/decline invites!")
				end
			elseif proccmd[2] and string.find(proccmd[2],"unmerge") then
				if controlledplayers[playerid] then
					UnmergePlayer(playerid)
					return
				else
					SendToUnsynced("errors",playerid,"You aren't on any squad!")
					return
				end
			elseif proccmd[2] and string.find(proccmd[2],"decline") and IsTeamLeader(playerid) then
				if proccmd[3] then
					proccmd[3] = string.gsub(proccmd[3],"%D","")
					Invites[playerid][tonumber(proccmd[3])] = nil
					return
				elseif not IsTeamLeader(playerid) then
					SendToUnsynced("errors",playerid,"You aren't team leader! You can't accept/decline invites!")
				else
					SendToUnsynced("errors",playerid,"Invalid decline.")
				end
			elseif proccmd[2] and string.find(proccmd[2],"kick") and proccmd[3] then
				if IsTeamLeader(playerid) then
					proccmd[3] = string.gsub(proccmd[3],"%D","")
					if proccmd[3] then
						if IsPlayerOnSameTeam(playerid,proccmd[3]) then
							UnmergePlayer(proccmd[3])
							SendToUnsynced("errors",proccmd[3],"You were kicked from the squad.")
							return
						else
							SendToUnsynced("errors",playerid,"Player isn't on the same squad!")
							return
						end
					else
						SendToUnsynced("errors",playerid,"Invalid kick command")
						return
					end
				else
					SendToUnsynced("errors",playerid,"You aren't squad leader!")
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
	
else -- unsynced stuff
	
	local function mergealert(_,playerid,target)
		if Spring.GetMyPlayerID() == playerid then
			Spring.SendLuaUIMsg("playerchangedteam " .. playerid .. " " .. target,"a") -- spring doesn't have a callin for player changing team yet :( -- Remove me if engine devs ever make something for this!
		end
	end
	
	local function errors(_,playerid,msg)
		if Spring.GetMyPlayerID() == playerid then
			Spring.Echo("game_message: " .. msg)
		end
	end
	
	function gadget:Initialize()
		gadgetHandler:AddSyncAction("errors", errors)
		gadgetHandler:AddSyncAction("mergealert",mergealert)
	end
end
