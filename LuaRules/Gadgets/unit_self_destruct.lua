-- $Id$
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

if (gadgetHandler:IsSyncedCode()) then

local spGetUnitAllyTeam = Spring.GetUnitAllyTeam

deathTeams = {}

-- one man ally?
rogueAlly = {}

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
    local selfDunits = {}
    for _,u in ipairs(teamUnits) do
      local selfDtime = Spring.GetUnitSelfDTime(u)
      if selfDtime > 0 then
        selfDunits[#selfDunits + 1] = u
      end
    end
    if #selfDunits / #teamUnits > 0.8 then
      Spring.GiveOrderToUnitArray(selfDunits, CMD.SELFD, {}, {})
      SendToUnsynced('resignteam', team)
    end
  end
  deathTeams = {}

  -- check for rogue allies
  -- max 1 player, active and not a spec
  if n % 20 < 0.1 then
    local allylist = Spring.GetAllyTeamList()
    for _,a in ipairs(allylist) do
      repeat
      local teamlist = Spring.GetTeamList(a)
      if not teamlist then break end -- continue
      local activeTeams = 0
      for _,t in ipairs(teamlist) do
        local playerlist = Spring.GetPlayerList(t, true) -- active players
        if playerlist then
          for _,p in ipairs(playerlist) do
            local _,_,spec = Spring.GetPlayerInfo(p)
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

else

-- UNSYNCED

function gadget:Initialize() 
  gadgetHandler:AddSyncAction('resignteam',
    function(_,teamID)
      local spec = Spring.GetSpectatingState()
      if (Spring.GetLocalTeamID() == teamID) and (not spec) then
        Spring.SendCommands('spectator')
      end
    end
  )
end 

end

