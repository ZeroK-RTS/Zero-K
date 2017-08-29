function widget:GetInfo()
  return {
    name      = "Stop Self-D",
    desc      = "Stop orders cancel self destruct commands",
    author    = "Bluestone",
    date      = "GPL v3 or later",
    license   = "Feb 2015",
    layer     = 0,
    enabled   = true  
  }
end

local CMD_STOP = CMD.STOP

function widget:UnitCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
    if cmdID ~= CMD_STOP then return end
    if not unitID then return end
    if teamID ~= Spring.GetMyTeamID() then return end

    if (Spring.GetUnitSelfDTime(unitID) > 0) then
        Spring.GiveOrderToUnit(unitID, CMD.SELFD, {}, {})
    end 
end