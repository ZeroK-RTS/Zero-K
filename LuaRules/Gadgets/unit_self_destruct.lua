--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
return {
	name      = "Self destruct blocker",
	desc      = "ctrl+A+D becomes a resign",
	author    = "lurker",
	date      = "April, 2009",
	license   = "public domain",
	layer     = 0,
	enabled   = true  --  loaded by default?
	}
end

local spGetUnitAllyTeam = Spring.GetUnitAllyTeam

deathTeams = {}

-- auto detection of doesnotcount units
local doesNotCountList = {}
for name, ud in pairs(UnitDefs) do
	if (ud.customParams.dontcount or ud.canKamikaze) then
		doesNotCountList[ud.id] = true
	end
end

-- one man ally?
rogueAlly = {}

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD.SELFD] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions,fromSynced)
  local a = spGetUnitAllyTeam(unitID)
  if not rogueAlly[a] and cmdID == CMD.SELFD then
    deathTeams[unitTeam] = true
  end
  return true
end

function gadget:GameFrame(n)
  for team,_ in pairs(deathTeams) do
    local teamUnits = Spring.GetTeamUnits(team)
    local realUnits = 0
    local selfDunits = {}
    for i=1, #teamUnits do
      local u = teamUnits[i]
      local selfDtime = Spring.GetUnitSelfDTime(u)
      local udid = Spring.GetUnitDefID(u)
      if not doesNotCountList[udid] then
        realUnits = realUnits + 1
        if selfDtime > 0 then
          selfDunits[#selfDunits + 1] = u
        end
      end
    end
    if #selfDunits / realUnits > 0.8 then
      Spring.GiveOrderToUnitArray(selfDunits, CMD.SELFD, {}, 0)
      SendToUnsynced('resignteam', team)
    end
  end
  deathTeams = {}

  -- check for rogue allies
  -- max 1 player, active and not a spec
  if n % 20 < 0.1 then
    local allylist = Spring.GetAllyTeamList()
    for i=1,#allylist do
      repeat
      local a = allylist[i]
      local teamlist = Spring.GetTeamList(a)
      if not teamlist then break end -- continue
      local activeTeams = 0
      for _,t in ipairs(teamlist) do
        local playerlist = Spring.GetPlayerList(t, true) -- active players
        if playerlist then
          for j=1,#playerlist do
            local _,_,spec = Spring.GetPlayerInfo(playerlist[j], false)
            if not spec then
              activeTeams = activeTeams + 1
            end
          end
        end
      end
      if activeTeams < 2 then
        rogueAlly[a] = true
      else
        rogueAlly[a] = false
      end
      until true
    end
  end

end
