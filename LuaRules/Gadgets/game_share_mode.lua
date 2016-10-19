function gadget:GetInfo()
	return {
	  name      = "Share mode",
	  desc      = "Allows one to share control of resources and units with other players.",
	  author    = "_Shaman",
	  date      = "6-23-2016",
	  license   = "Do whatever you want with it, just give credit",
	  layer     = 0,
	  enabled   = true,
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

--if modOptions.sharemode == "off" then
--gadgetHandler:RemoveGadget()
--end

local config = {
  default = "invite",
  mergeai   = false,
  mergetype = modOptions.sharemode, -- not used yet.
  antigrief = tobool(modOptions.sharemodeantigrief),
  unmerging = tobool(modOptions.sharemodeallowunmerge),
  special   = modOptions.sharemodecfg,
  mintime   = modOptions.sharemodemintime,
}
-- check config --
--if config.mergeai == nil then config.mergeai = true; end
if config.mergetype == nil then config.mergetype = "invite"; end
if config.antigrief == nil then config.antigrief = true; end
if config.unmerging == nil then config.unmerging = true; end
if config.special == nil then config.special = "all none invite clan"; end
if config.mintime == nil then config.mintime = 0; end

config.mintime = (config.mintime * 30) + 5 -- The 5 is here to prevent

if mergetype == "special" then -- parse the special def. commas are delimiters
  local instructions = ProccessCommand(config.special)
  config.special = {}
  for allyid,mode in pairs(instructions) do
	config.special[allyid] = string.gsub(mode,"%W","")
	config.special[allyid] = string.gsub(config.special[allyid],"%d","")
	config.special[allyid] = string.lower(config.special[allyid])
  end
end
if config.special then
  config.special = {}
  local allylist = Spring.GetAllyTeamList()
  if config.mergetype == "special" then
    for i=1,#allylist do
      --Verify config--
      if config.special[i] then
        if validmodes[config.special[i]] == nil or validmodes[config.special[i]] == false then
          config.special[i] = config.default
        end
      else
        config.special[i] = config.default
      end
    end
  else
    config.special = {}
    for i=1,#allylist do
      config.special[i] = config.mergetype
    end
  end
end

Spring.Echo("Config:\nmergeai: " .. tostring(config.mergeai) .. "\nmergetype:" .. config.mergetype .. "\nantigrief:" .. tostring(config.antigrief) .. "\nunmerging: " .. tostring(config.unmerging))

local function GetTeamID(playerid)
  local _,_,_,teamid,_ = Spring.GetPlayerInfo(playerid)
  return teamid
end

local function IsTeamLeader(playerid)
  local teamid = GetTeamID(playerid)
  local _,teamleaderid,_ = Spring.GetTeamInfo(teamid)
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
  local validmodes = {};validmodes["all"] = true;validmodes["none"] = true;validmodes["clan"] = true;validmodes["invite"] = true
  local Invites = {}
  local antigriefactiveteams = {}

--Note I wished springiee had a way of setting certain variables in game :(

  local controlledplayers = {}
  local originalplayers = {}
  local originalunits = {}

  local function GetLowestID(list,includeai)
    local lowest = 9001
    local aipresent = false
    local isAI
    for _,id in pairs(list) do
      _,_,_,isAI,_ = Spring.GetTeamInfo(id)
      if isAI then aipresent = true end
      if id < lowest and id > 0 and isAI == false and includeai == false then lowest = id end
      if id < lowest and id > 0 and includeai == true then lowest = id end
    end
    return lowest,aipresent
  end

  local function CountNonAI(list)
    local count = 0
    for _,id in pairs(list) do
      _,_,_,isAI,_ = Spring.GetTeamInfo(id)
      if isAI == false then
        count = count + 1
      end
    end
    return count
  end

  local function UnmergePlayer(player) -- Takes playerid, not teamid!!!
    local name,_ = Spring.GetPlayerInfo(player)
    if originalplayers[player] then
      Spring.Echo("game_message: Unmerging player " .. name)
      if originalplayers[player] then
        if GetSquadSize(GetTeamID(player)) -1 == 1 then
          antigriefactiveteams[GetTeamID(player)] = nil -- turn antigrief off
        end
        local target = originalplayers[player]
        Spring.SetTeamResource(originalplayers[player],"ms",500)
        local _,targetms,_  = Spring.GetTeamResources(controlledplayers[player],"metal")
        local _,targetes,_  = Spring.GetTeamResources(controlledplayers[player],"energy")
        Spring.SetTeamResource(controlledplayers[player],"ms",targetms-500)
        Spring.SetTeamResource(controlledplayers[player],"es",targetes-500)
        Spring.AssignPlayerToTeam(player,originalplayers[player])
        for _,unit in pairs(originalunits[target]) do
          if Spring.ValidUnitID(unit) and Spring.AreTeamsAllied(Spring.GetUnitTeam(unit),target) then
            Spring.TransferUnit(unit,target,true)
          elseif Spring.ValidUnitID(unit) and Spring.AreTeamsAllied(Spring.GetUnitTeam(unit),target) and Spring.IsCheatingEnabled() then
            Spring.TransferUnit(unit,target,false)
          end
        end
        originalunits[target] = nil
        targetms,targetes,target,controlledplayers[player] = nil -- cleanup.
      end
    end
  end

  local function MergeAIPlayers(allyteam) -- Give all units belonging to similar ais to one ai.
    local teamlist = Spring.GetTeamList(allyteam)
    local aitypes = {}
    for _,team in pairs(teamlist) do
      local _,_,_,ai,_ = Spring.GetTeamInfo(team)
      if ai then
        _,name,_ = Spring.GetAIInfo(team)
        Spring.Echo("name (aiinfo): " .. name)
        name = Spring.GetTeamLuaAI(team)
        Spring.Echo(team .. ": " .. name)
        if aitypes[name] == nil then
          aitypes[name] = {}
          table.insert(aitypes[name],team)
        else
          table.insert(aitypes[name],team)
        end
      end
    end
    for name,list in pairs(aitypes) do
      Spring.Echo(name .. ": size: " .. #list)
      if #list > 1 then
        local lowestid,_ = GetLowestID(list,true)
        Spring.Echo("Lowest ID is " .. lowestid)
        for i=1,#list do
          if list[i] ~= lowestid then
            local metal,mstore,_             = Spring.GetTeamResources(list[i],"metal")
            local energy,estore,_            = Spring.GetTeamResources(list[i],"energy")
            local _,targetms,_               = Spring.GetTeamResources(lowestid,"metal")
            local _,targetes,_               = Spring.GetTeamResources(lowestid,"energy")
            local units = Spring.GetTeamUnits(list[i])
            Spring.SetTeamResource(lowestid,"ms",500+targetms)
            Spring.SetTeamResource(lowestid,"es",500+targetes)
            Spring.ShareTeamResource(list[i],lowestid,"metal",metal)
            Spring.ShareTeamResource(list[i],lowestid,"energy",energy)
            Spring.SetTeamResource(list[i],"ms",0)
            Spring.SetTeamResource(list[i],"es",500)
            for i=1,#units do
              Spring.TransferUnit(units[i],lowestid,false)
            end
          end
        end
      end
    end
  end
  
  local function MergeUnits(team,target)
    local units = Spring.GetTeamUnits(team)
    originalunits[team] = units
    for i=1, #units do
      if Spring.IsCheatingEnabled() and Spring.ValidUnitID(units[i]) then
        Spring.TransferUnit(units[i],target,false)
      elseif Spring.ValidUnitID(units[i]) then
        Spring.TransferUnit(units[i],target,true)
      end
    end
  end
  
  local function MergePlayers(player,target,isplayerid) -- Player merges into target's team.
  Spring.Echo("Merge Players")
    if player == nil then
      Spring.Echo("game_message: Attempted to merge a nil player!")
      return
    end
    if not antigriefactiveteams[target] then
      antigriefactiveteams[target] = true
    end
    local pid                        = 0
    local name,_,spec,_,_,allyteam   = Spring.GetPlayerInfo(pid)
    local metal,_,_                  = Spring.GetTeamResources(player,"metal")
    local energy,_,_                 = Spring.GetTeamResources(player,"energy")
    local _,targetms,_               = Spring.GetTeamResources(target,"metal")
    local _,targetes,_               = Spring.GetTeamResources(target,"energy")
    if isplayerid then
      pid = player
      if GetSquadSize(GetTeamID(player))-1 == 0 then
        MergeUnits(GetTeamID(player),target)
      end
    else
      _,pid,_ = Spring.GetTeamInfo(player)
    end
    if pid == nil then
      return
    else
      if GetSquadSize(player) -1 == 0 then
        MergeUnits(player,target)
      end
    end
    if target == nil then
      Spring.Echo("game_message: Encountered a nil target player while attempting to merge " .. name)
      return
    end
    if (Spring.AreTeamsAllied(player,target) and spec == false and target ~= Spring.GetGaiaTeamID() and config.special[allyteam] ~= "none") or Spring.IsCheatingEnabled() then
      Spring.Echo("Assigning player id " .. pid .. "(" .. name .. ") to team " .. target)
      if spec then
        Spring.AssignPlayerToTeam(pid,target)
      elseif Spring.AreTeamsAllied(player,target) then
        originalplayers[pid]  = player -- Added in case of unmerging
        Spring.AssignPlayerToTeam(pid,target)
        Spring.SetTeamResource(target,"ms",500+targetms)
        Spring.SetTeamResource(target,"es",500+targetes)
        Spring.ShareTeamResource(player,target,"metal",metal)
        Spring.ShareTeamResource(player,target,"energy",energy)
        Spring.SetTeamResource(player,"ms",0)
        controlledplayers[player] = target
      end
    elseif target == Spring.GetGaiaTeamID() then
      Spring.Echo("game_message: Player " .. name .. " can't be merged into team " .. target .. "! Reason: Target is Gaia!")
    elseif spec then --Error messages
      Spring.Echo("game_message: Player " .. name .. " can't be merged into team " .. target .. "! Reason: Player is spectator. Enable cheats to enable spectator merging.")
    elseif config.special[allyteam] == "none" then
      Spring.Echo("game_message: Player " .. name .. " can't be merged into team " .. target .. "! Reason: Configuration for this allyteam forbids this! Enable cheats to allow this.")
    elseif Spring.AreTeamsAllied(player,target) == false then
      Spring.Echo("game_message: Player " .. name .. " can't be merged into team " .. target .. "! Reason: Players are not allied.")
    else
      Spring.Echo("game_message: Player " .. name .. " can't be merged into team " .. target .. "! Reason: Unknown failure. Enable cheats may be a fix?")
    end
    pid,name,spec,metal,mstore,energy,estore,targetms,targetes = nil
  end
  
  local function MergeTeams(team1,team2) -- bandaid for an issue during planning.
    local playerlist = Spring.GetPlayerList(team1,true)
    local playerlist2 = Spring.GetPlayerList(team2,true)
    if GetSquadSize(team1) >= GetSquadSize(team2) then
      for _,id in pairs(playerlist) do
        MergePlayers(id,team2,true)
      end
    else
      for _,id in pairs(playerlist2) do
        MergePlayers(id,team1,true)
      end
    end
    playerlist,playerlist2 = nil
  end
  
  local function InvitePlayer(player,target,ismergereq)
    if Spring.GetGameFrame() > config.mintime then
      Spring.Echo("config.mintime passes")
      if player ~= target then
        local _,_,targetspec,_ = Spring.GetPlayerInfo(target)
        if targetspec then SendToUnsync("errors",player,"You can't merge with specs!") return end
        local targetteam = GetTeamID(target)
        local _,_,dead,ai,_ = Spring.GetTeamInfo(targetteam)
        local _,_,spec,_ = Spring.GetPlayerInfo(player)
        if spec then
          SendToUnsynced("errors",player,"You are spectating!")
          return
        end
        if not dead and not ai then
          Spring.Echo("alive passed")
          if Invites[player] then
            Invites[player][target] = {};Invites[player][target]["timeleft"] = 45;Invites[player][target]["ismergereq"] = ismergereq
          else
            Invites[player] = {};Invites[player][target] = {};Invites[player][target]["timeleft"] = 45;Invites[player][target]["ismergereq"] = ismergereq
          end
          SendToUnsynced("newinvite",target,player,ismergereq)
          Spring.Echo("newinvite sent to " .. target .. "(" .. player,tostring(ismergereq) .. ")")
        elseif playerspec then
          SendToUnsynced("errors",player,"Target squad is dead!")
        else
          SendToUnsynced("errors",player,"Target is an AI player!")
        end
      else
        SendToUnsynced("errors",player,"You can't merge with yourself!")
      end
    else
      SendToUnsynced("errors",player,"You can't merge this early!")
    end
  end
  
  local function AcceptInvite(player,target)
    Spring.Echo("verifying invite")
    if Invites[player][target] then
      Spring.Echo("invite verified")
      if Invites[player][target]["ismergereq"] then -- player->target
        MergePlayers(target,GetTeamID(player),true)
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
  
  local function MergeClan(allyteam)
    Spring.Echo("Merge Clan")
    local teamlist = Spring.GetTeamList(allyteam)
    local clanlist = {}
    for _,team in pairs(teamlist) do
      local _,pid,_ = Spring.GetTeamInfo(team)
      local customKeys = select(10, Spring.GetPlayerInfo(pid)) or {}
      local clanShort = customKeys.clan or "none"
      local clanLong = customKeys.clanfull or "none"
      if clanShort ~= "none" then
        if clanlist[clanShort] ~= nil then
          clanlist[clanShort].members[#members+1] = team
        else
          clanlist[clanShort]["members"] = {}
          clanlist[clanShort].members[#members+1] = team
        end
      end
    end
    for _,data in pairs(clanlist) do
      if #data["members"] > 1 then
        Spring.Echo("game_message: Clan " .. clanLong .. " has been merged!")
        local lowestid = GetLowestID(data["members"],false)
        for i=1,#data["members"] do
          MergePlayers(data["members"][i])
        end
      end
    end
  end
  
  function gadget:Initialize()
    local playerlist = Spring.GetPlayerList(true)
    local name = ""
    for _,player in pairs(playerlist) do
      name,_,_,_ = Spring.GetPlayerInfo(player)
      playernametoid[player] = name
      Spring.Echo(player .. ":" .. name)
    end
  end
    
  
  function gadget:PlayerAdded(playerID)
    if Spring.GetGameFrame() > config.mintime then
      local name,active,spec,team,ally,_   = Spring.GetPlayerInfo(playerID)
      if spec == false and active == true and config.special[ally] ~= "none" and controlledplayers[team] then
        MergePlayers(playerID,controlledplayers[playerID],false)
        Spring.Echo("game_message: Player " .. name .. "has been remerged!")
      end
    end
  end
  
  function gadget:GameFrame(f)
    if f%30 == 0 then
      for player,invites in pairs(Invites) do
        for id,data in pairs(invites) do
          data["timeleft"] = data["timeleft"] - 1
          if data["timeleft"] == 0 then
            data = nil
          end
        end
      end
    end
    if f== config.mintime then
      local ally = Spring.GetAllyTeamList()
      Spring.Echo("game_message: Share mode avaliable!")
      if config.mergetype ~= "invite" or config.mergetype ~= "none" then
        for i=1,#ally do
          Spring.Echo("Config for ally " .. ally[i] .. ": " .. tostring(config.special[ally[i]]))
          teamlist = Spring.GetTeamList(ally[i])
          if teamlist ~= nil and #teamlist > 1 and config.special[i] ~= "none" then
            if config.special[ally[i]] == "all" then
              local mergeid,_ = GetLowestID(teamlist,false)
              for _,team in pairs(teamlist) do
                if mergeid == team then
                  Spring.Echo("MergeID is " .. mergeid .. "(" .. tostring(name) .. ")")
                else
                  _,pid,_,isAi = Spring.GetTeamInfo(team)
                  name,_,_,_,_ = Spring.GetPlayerInfo(pid)
                  if isAi == false then
                    MergeTeams(team,mergeid)
                  end
                end
              end
            elseif config.special[ally[i]] == "clan" and CountNonAI(teamlist) > 0 then
              MergeClan(ally[i])
            end
          end
        end
        ally,mergeid,name,isAi = nil
      end
    end
    if f== config.mintime + 600 and config.mergeai then
      local ally = Spring.GetAllyTeamList()
      for i=1,#ally do
        local teamlist = Spring.GetTeamList(ally[i])
        _,ai = GetLowestID(teamlist,false)
      	if ai and config.special[i] ~= "none" then
		  Spring.Echo("Merging AI for team" .. ally[i])
		  MergeAIPlayers(ally[i])
		end
      end
    end
  end
  
  function gadget:RecvLuaMsg(msg,playerid) -- Entry points for widgets to interact with the gadget
    if string.find(msg,"sharemode") then -- Format for messages: sharemode_cmd_aug1_aug2
      local cmdlower = string.lower(msg)
      local proccmd = {}
      proccmd = ProccessCommand(cmdlower)
      for i=1,#proccmd do
        Spring.Echo(playerid .. "sent:\n" .. i .. ":" .. tostring(proccmd[i]))
      end
      if proccmd[2] and string.find(proccmd[2],"invite") then
      	if proccmd[3] then
          proccmd[3] = string.gsub(proccmd[3],"%D","")
          if proccmd[3] ~= "" then
            InvitePlayer(playerid,tonumber(proccmd[3]),false) -- playerid <- proccmd[3] merger
            Spring.Echo("inviteplayer")
            return
          end
        else
          SendToUnsynced("errors",playerid,"Error: Invalid invite!")
          return
        end
      elseif proccmd[2] and string.find(proccmd[2],"mergereq") then -- playerid -> proccmd[3] merger
        proccmd[3] = string.gsub(proccmd[3],"%D","")
        if proccmd[3] ~= "" then
          Spring.Echo("mergereq")
          InvitePlayer(tonumber(proccmd[3]),playerid,true)
          return
        else
          SendToUnsynced("errors",playerid,"Error: Missing mergeid")
          return
        end
      elseif proccmd[2] and string.find(proccmd[2],"accept") then
        proccmd[3] = string.gsub(proccmd[3],"%D","")
        if proccmd[3] then proccmd[3] = tonumber(proccmd[3]) end
        if proccmd[3] and Invites[proccmd[3]] and Invites[proccmd[3]][playerid] then
          AcceptInvite(proccmd[3],playerid)
          Spring.Echo("invite accepted")
          return
        end
      elseif proccmd[2] and string.find(proccmd[2],"unmerge") then
        if controlledplayers[playerid] then
          UnmergePlayer(playerid)
          return
        else
          SendToUnsynced("errors",playerid,"You aren't on any squad!")
          return
        end
      elseif proccmd[2] and string.find(proccmd[2],"restart") then -- Lua was restart! Sender requests invites again.
        if Invites[playerid] then
          for k,v in pairs(Invites[playerid]) do
            SendToUnsynced("widgetstuff",playerid,k,v["timeleft"],v["ismergereq"])
          end
        end
      elseif proccmd[2] and string.find(proccmd[2],"decline") then
        if proccmd[3] then
          proccmd[3] = string.gsub(proccmd[3],"%D","")
          Invites[playerid][tonumber(proccmd[3])] = nil
          SendToUnsynced("widgetstuff",tonumber(proccmd[3]),nil)
          return
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
  
  function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
    if cmdID == CMD.SELFD and config.antigrief and antigriefactiveteams[unitTeam] and UnitDefs[unitDefID].canKamikaze == false then
      Spring.Echo("[AntiGrief] That's not allowed.")
      return false
    end
    return true
  end
  
else -- unsynced stuff
  
  local function Errors(_,playerid,msg)
    if Spring.GetMyPlayerID() == playerid then
      Spring.Echo("game_message: " .. msg)
    end
  end
  
  local function Invite(_,playerid,target,ismerge)
    if playerid == Spring.GetMyPlayerID() then
      name,_ = Spring.GetPlayerInfo(target)
      if ismerge then
        Spring.Echo("game_message:" .. "You got an invitation from " .. name .. "! Type /squad accept " .. target .. " to accept it")
      else
        Spring.Echo("game_message:" .. name .. "has invited you to join their squad! Type /squad accept " .. target .. " to accept it")
      end
    end
  end
  
  local function SendToWidgets(_,playerid,target,timeleft,ismerge)
    if Spring.GetMyPlayerID() == playerid then
      Spring.SendLuaUIMsg("sharemodeupdater " .. playerid .. " " .. timeleft .. " " .. ismerge,"a")
    end
  end
  
  function gadget:Initialize()
    gadgetHandler:AddSyncAction("errors", Errors)
    gadgetHandler:AddSyncAction("widgetstuff", SendToWidgets)
    gadgetHandler:AddSyncAction("newinvite",Invite)
  end
end
