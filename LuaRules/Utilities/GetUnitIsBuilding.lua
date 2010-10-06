-- $Id:$
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--
-- Author: jK @2010
-- License: GPLv2 and later
--
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function Spring.Utilities.GetUnitIsBuilding(unitID)
  local type = ""
  local target

  local buildID = Spring.GetUnitIsBuilding(unitID)
  if (buildID) then
    target = buildID
    type   = "building"
  else
    local cmds = Spring.GetUnitCommands(unitID,1)
    if (cmds)and(cmds[1]) then
      local cmd   = cmds[1]
      local cmdID = cmd.id
      local cmdParams = cmd.params

      if     cmdID == CMD.RECLAIM then
        --// anything except "#cmdParams = 1 or 5" is either invalid or discribes an area reclaim
        if (not cmdParams[2])or(cmdParams[5]) then
          count = 30 --//(you normally reclaim always with 100% power)
          local id = cmdParams[1]
          local unitID_ = id
          local featureID = id - Game.maxUnits

          if (featureID >= 0) then
            if Spring.ValidFeatureID(featureID) then
              target = -featureID
              type   = "reclaim"
            end
          else
            if Spring.ValidUnitID(unitID_) then
              target = unitID_
              type   = "reclaim"
            end
          end
        end

      elseif cmdID == CMD.REPAIR  then
        local repairID = cmdParams[1]
        if Spring.ValidUnitID(repairID) then
          target = repairID
          type   = "repair"
        end

      elseif cmdID == CMD.RESTORE then
        local x = cmd.params[1]
        local z = cmd.params[3]
        type   = "restore"
        target = {x, GetGroundHeight(x,z)+5, z, cmd.params[4]}

      elseif cmdID == CMD.CAPTURE then
        if (not cmdParams[2])or(cmdParams[5]) then
          local captureID = cmdParams[1]
          if Spring.ValidUnitID(captureID) then
            target = captureID
            type   = "capture"
          end
        end

      elseif cmdID == CMD.RESURRECT then
        local rezzID = cmdParams[1] - Game.maxUnits
        if Spring.ValidFeatureID(rezzID) then
          target = -rezzID
          type   = "resurrect"
        end

      end
    end
  end

  return type, target
end
