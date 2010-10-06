function gadget:GetInfo()
return {
	name      = "Last Ally",
	desc      = "End game (remove units) if only 1 ally with players is left.",
	author    = "SirMaverick",
	date      = "2009",
	license   = "GPL",
	layer     = 0,
	enabled   = true  --  loaded by default?
	}
end

--[[

End game (remove units) if only 1 ally with players is left.
This also is triggered when all others spectate.

]]

if (gadgetHandler:IsSyncedCode()) then

local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local gaiaTeamID = Spring.GetGaiaTeamID()

function gadget:GameFrame(n)

  -- check for last ally:
  -- end condition: only 1 ally with human players, no AIs in other ones
  if n % 37 < 0.1 then

    if Spring.IsCheatingEnabled() then
      gadgetHandler:RemoveGadget()
    end

    local allylist = Spring.GetAllyTeamList()
    local activeAllies = 0
    local lastActive = nil
    for _,a in ipairs(allylist) do
      repeat
	if (a == gaiaTeamID) then break end -- continue
      local teamlist = Spring.GetTeamList(a)
      if (not teamlist) then break end -- continue
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
        -- count AI teams as active
        local _,_,_,isAiTeam = Spring.GetTeamInfo(t)
        if isAiTeam then
          activeTeams = activeTeams + 1
        end
      end
      if activeTeams > 0 then
        activeAllies = activeAllies + 1
        lastActive = a
      end
      until true
    end -- for

    if activeAllies < 2 then
      -- remove every unit except for last active alliance
      for _,a in ipairs(allylist) do
        if (a ~= lastActive)and(a ~= gaiaTeamID) then
          repeat
          local teamlist = Spring.GetTeamList(a)
          if not teamlist then break end -- continue
          for _,t in ipairs(teamlist) do
            local units = Spring.GetTeamUnits(t)
            for _,u in ipairs(units) do
              Spring.DestroyUnit(u, true) -- with self-d explosion
            end
          end
          until true
        end
      end
      gadgetHandler:RemoveGadget()
    end

  end

end

else -- UNSYNCED

end

