-- $Id: unit_autoretreat.lua 4459 2009-04-20 19:57:33Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Auto Retreat",
    desc      = "Sets pre-defined units when built to 'Retreat at 90% health.'",
    author    = "CarRepairer",
    date      = "Feb 12, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = false  --  loaded by default?
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CMD_RETREAT = 10000

local unitSet = {}

local unitArray = {
  "arm_marky",
  "armseer",
  "corvoyr",
  "corvrad",

  --"armaser",
  "armspy",

  "armcsa",
  "corcsa",
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Initialize() 
  for i, v in pairs(unitArray) do
    unitSet[v] = true
  end
end




function widget:UnitFromFactory(unitID, unitDefID, unitTeam)
  local ud = UnitDefs[unitDefID]
   if ud and (unitTeam == Spring.GetMyTeamID()) then
    for i, v in pairs(unitSet) do
      if (unitSet[ud.name]) then        
	WG['retreat'].addRetreatCommand(unitID, unitDefID, 3)
      end
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

