-- $Id: share_control.lua 4292 2009-04-05 05:29:29Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    share_control.lua
--  brief:   only allow sharing with allied teams
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "ShareControl",
    desc      = "Controls sharing of units and resources",
    author    = "trepan",
    date      = "Apr 22, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = -5,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetTeamInfo	=	Spring.GetTeamInfo

local resShare  = true  -- allow sharing resources

local unitShare = true  -- allow sharing units

local resShareEnemy  = false  -- allow sharing resources with enemies

local unitShareEnemy = false  -- allow sharing units with enemies

local unitShareCeasefired = false -- allow sharing units with ceasefired 

if not GG.shareunits then
	GG.shareunits = {}
end

--------------- CarRepairer start -------------
--[[
local GetAllyTeamList   = Spring.GetAllyTeamList
local GetTeamList       = Spring.GetTeamList
local GetPlayerList     = Spring.GetPlayerList
local backupPlayerMode
local backups = {}
--]]
local GetTeamInfo       = Spring.GetTeamInfo

--
--  A team indexed list of the last frames that a unit transfer was blocked.
--  This helps to avoid filling up the console with warnings when a user tries
--  to share multiple units.
--
--
local lastRefusals = {}


--------------------------------------------------------------------------------

--if Spring.FixedAllies() == false then return false end  --remove

local function AllowAction(playerID)
  if (playerID ~= 0) then
    Spring.SendMessageToPlayer(playerID, "Must be the host player")
    return false
  end
  if (not Spring.IsCheatingEnabled()) then
    Spring.SendMessageToPlayer(playerID, "Cheating must be enabled")
    return false
  end
  return true
end


local function PrintState()
  Spring.Echo('sharing units is '
              .. (unitShare and 'enabled' or 'disabled'))
  Spring.Echo('sharing resources is '
              .. (resShare and 'enabled' or 'disabled'))
  Spring.Echo('sharing units with enemies is '
              .. (unitShare and unitShareEnemy and 'enabled' or 'disabled'))
  Spring.Echo('sharing resources with enemies is '
              .. (resShare and resShareEnemy and 'enabled' or 'disabled'))
  return true
end


local function ChatControl(cmd, line, words, playerID)
  if (not AllowAction(playerID)) then
    PrintState()
    return true
  end
  local count = #words

  if (count == 0) then
    unitShare = not unitShare
    resShare  = unitShare
  elseif (count == 1) then
    if ((words[1] == '0') or (words[1] == 'none')) then
      resShare  = false
      unitShare = false
      resShareEnemy  = false
      unitShareEnemy = false
    elseif ((words[1] == '1') or (words[1] == 'ally')) then
      resShare  = true
      unitShare = true
      resShareEnemy  = false
      unitShareEnemy = false
    elseif ((words[1] == '2') or (words[1] == 'full')) then
      resShare  = true
      unitShare = true
      resShareEnemy  = true
      unitShareEnemy = true
    elseif (words[1] == 'r') then
      resShare  = not resShare
    elseif (words[1] == 'u') then
      unitShare  = not unitShare
    elseif (words[1] == 'e') then
      resShareEnemy  = not resShareEnemy
      unitShareEnemy = not unitShareEnemy
    end
  elseif (count == 2) then
    if (words[1] == 'e') then
      if (words[2] == '0') then
        resShareEnemy  = false
        unitShareEnemy = false
      elseif (words[2] == '1') then
        resShareEnemy  = true
        unitShareEnemy = true
      end
    elseif (words[1] == 'r') then
      if (words[2] == '0') then
        resShare = false
      elseif (words[2] == '1') then
        resShare = true
      elseif (words[2] == 'e') then
        resShareEnemy = not resShareEnemy
      end
    elseif (words[1] == 'u') then
      if (words[2] == '0') then
        unitShare = false
      elseif (words[2] == '1') then
        unitShare = true
      elseif (words[2] == 'e') then
        unitShareEnemy = not unitShareEnemy
      end
    end
  elseif (count == 3) then
    if (words[1] == 'r') then
      if (words[2] == 'e') then
        if (words[3] == '0') then
          resShareEnemy = false
        elseif (words[3] == '1') then
          resShareEnemy = true
        end
      end
    elseif (words[1] == 'u') then
      if (words[2] == 'e') then
        if (words[3] == '0') then
          unitShareEnemy = false
        elseif (words[3] == '1') then
          unitShareEnemy = true
        end
      end
    end
  end

  PrintState()
  return true
end


function gadget:Initialize()
  if (not gadgetHandler:IsSyncedCode()) then
    gadgetHandler:RemoveGadget()
    return
  end
  
  if( Spring.GetModOptions() ) then
	unitShareEnemy = Spring.GetModOptions().sharemode == 'anyone'
	--resShareEnemy = unitShareEnemy
	unitShareCeasefired = Spring.GetModOptions().sharemode == 'ceasefire'
  end
  
  local cmd, help
  
  cmd  = "sharectrl"
  local h = ''
  h = h..     ' [ "none" | "ally" | "full"]:  basic sharing modes\n'
  h = h..cmd..' <"u"|"r"> ["e"] [0|1]:  finer sharing control\n'
  h = h..'  u: unit sharing\n'
  h = h..'  r: resource sharing\n'
  h = h..'  e: enemy mode\n'
  
--  h = h..cmd..' [0|1]:  control unit and resource sharing\n'
--  h = h..cmd..' res [0|1]:  control resource sharing\n'
--  h = h..cmd..' unit [0|1]:  control unit sharing\n'
--  h = h..cmd..' enemy [0|1]:  control enemy unit and resource sharing\n'
--  h = h..cmd..' enemy res [0|1]:  control enemy resource sharing\n'
  help = h
  gadgetHandler:AddChatAction(cmd, ChatControl, help)
  Script.AddActionFallback(cmd .. ' ', help)


--------------- CarRepairer start -------------
--[[
	allyTeamList = GetAllyTeamList()
	allyTeamCount = {}

	backupPlayerMode = (Spring.GetModOptions().backupplayers == 1)

	for _, allyTeam in ipairs(allyTeamList) do
		teamList = GetTeamList(allyTeam)
		allyTeamCount[allyTeam] = #teamList
		
		for _, team in ipairs(teamList) do
			_,_,_,_,faction,_ = GetTeamInfo(team)
			if (faction == 'backup') then
				backups[team] = allyTeam
			end
		end
	end
--]]
--------------- CarRepairer end -------------
end

--------------- CarRepairer start -------------
--[[
function MissingPlayer(allyTeamID)
	local activePlayers = GetPlayerList(true)
	
	activePlayerCount = 0

	for _, activePlayer in ipairs(activePlayers) do
		local _, _, _, curTeamID, curAllyTeamID = GetPlayerInfo(activePlayer)
		if curAllyTeamID == allyTeamID then
			activePlayerCount = activePlayerCount + 1
		end
	end
	if activePlayerCount < allyTeamCount[allyTeamID] then
		return true
	end
	return false
end
--]]
--------------- CarRepairer end -------------


function gadget:Shutdown()
  gadgetHandler:RemoveChatAction("sharectrl", ChatControl)
end

function gadget:AllowResourceTransfer(oldTeam, newTeam, type, amount)
	if(amount < 0) then return end --thx to gnurps@o2.pl for this patch. This prevent player from taking resources from his ally.
  if (resShare) then
  	--if (resShareEnemy or Spring.AreTeamsAllied(oldTeam, newTeam)) then
    local _,_,_,_,_,oldAlliance = spGetTeamInfo(oldTeam)
	local _,_,_,_,_,newAlliance = spGetTeamInfo(newTeam)
    if (resShareEnemy or oldAlliance == newAlliance) then
      return true
    else
      Spring.SendMessageToTeam(oldTeam, "Cannot give resources to enemies when the fixed alliances option is set.")
    end
  else
    Spring.SendMessageToTeam(oldTeam, "Resource sharing has been disabled.")
  end
  return false
end


local function AddRefusal(team, msg)
  local frameNum = Spring.GetGameFrame()
  local lastRefusal = lastRefusals[team]
  if ((not lastRefusal) or (lastRefusal ~= frameNum)) then
    lastRefusals[team] = frameNum
    Spring.SendMessageToTeam(team, msg)
  end
end



function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
--------------- CarRepairer start -------------
--[[
	if (backups[newTeam]) then
		allyTeam = backups[newTeam]

		if backupPlayerMode then
			if (MissingPlayer(allyTeam)) then
				backups[newTeam] = nil
				allyTeamCount[allyTeam] = allyTeamCount[allyTeam] - 1
			else
				AddRefusal(oldTeam, "A Backup Player cannot receive units until a player drops.")
				return false  
			end
		else  
			AddRefusal(oldTeam, "A Backup may only receive units in 'Backup Player Mode.'")
			return false
		end
	end
--]]
--------------- CarRepairer end -------------

  if (capture) then
    return true
  end

  if (Spring.IsCheatingEnabled()) then
    return true
  end

  local _,_,_,_,faction,_ = GetTeamInfo(newTeam)
  if (faction == 'teamspec') then
	AddRefusal(oldTeam, "Cannot share units to a Teamspec.")
    return false
  end

	if GG.shareunits[unitID] then
		GG.shareunits[unitID] = nil
		return true
	end
  
	if (not unitShare) then
		AddRefusal(oldTeam, "Unit sharing has been disabled.")
		return false
	end
	
	-- AreTeamsAllied includes temporary alliances
	local _,_,_,_,_,oldAlliance = spGetTeamInfo(oldTeam)
	local _,_,_,_,_,newAlliance = spGetTeamInfo(newTeam)
	if (unitShareEnemy or oldAlliance == newAlliance) then
		return true
	end

	-- can give PW buildings to gaia
	local pwUnits = (GG.PlanetWars or {}).unitsByID
	if (newTeam == Spring.GetGaiaTeamID()) and (pwUnits or {})[unitID] then
		return true
	end
	
	if (unitShareCeasefired and Spring.AreTeamsAllied(oldTeam, newTeam)) then
		return true
	end

	AddRefusal(oldTeam, "Cannot give units to enemies unless enabled in mod options.")
	return false
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
