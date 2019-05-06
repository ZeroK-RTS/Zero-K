--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--      file:   mobile_unit_to_structure_morph.lua
--      brief:  Helper for morphing from mobile unit to structure
--      author: Matt Vollrath
--
--      Copyright (C) 2019.
--      Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name     = "MobileUnitToStructureMorph",
    desc     = "Helper for morphing from mobile unit to structure",
    author   = "mv",
    date     = "May, 2019",
    license  = "GNU GPL, v2 or later",
    layer    = -1, --same priority as unit_morph.lua
    enabled  = true
  }
end

if (gadgetHandler:IsSyncedCode()) then

include("LuaRules/Configs/customcmds.h.lua")

local LANDING_BOX_SZ = 8

--let's start with Mobile Gunship Plant preMorphing and go from there.
--for general use we would build tables from all unitdefs.
local gunshipPlantID = UnitDefNames["factorygunship"].id
local mobileGunshipPlantID = UnitDefNames["mobilefactorygunship"].id
local mobileGunshipPlants = {}

--keep track of units moving into morph position.
local preMorphing = {}

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z, facing)
  if (unitDefID ~= gunshipPlantID or not mobileGunshipPlants[builderID]) then
    --if this is not morpher creating morphee, don't care.
    return true
  end

  preMorphing[builderID] = {
    unitID = builderID,
    x = x,
    y = y,
    z = z,
    facing = facing,
    needsMove = true,
  }

  return false
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
  if unitDefID == mobileGunshipPlantID then
    --keep a list of mobile gunship plants in play.
    mobileGunshipPlants[unitID] = true
  end
end

function gadget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
  if (unitDefID ~= mobileGunshipPlantID or not preMorphing[unitID]) then
    return
  end

  local preMorphData = preMorphing[unitID]

  if (cmdID == -404) then
    return --avoid conflicting with the premorph build commands.
  end

  Spring.Echo('premorph cmdDone for ' .. unitID)

  --make sure the build location hasn't become blocked while moving to it.
  local blocking, featureID = Spring.TestBuildOrder(gunshipPlantID, preMorphData.x, preMorphData.y, preMorphData.z, preMorphData.facing)
  if (blocking < 2 or featureID ~= nil) then
    Spring.Echo('cancelling premorph due to landing blocked for ' .. unitID)
    preMorphing[unitID] = nil
    return
  end

  Spring.Echo('setting physics for ' .. unitID .. ' post cmd ' .. cmdID)
  local x, y, z = Spring.GetUnitPosition(unitID)
  local rx, ry, rz = Spring.GetUnitRotation(unitID)
  Spring.SetUnitPhysics(unitID, x, y, z, 0, -1, 0, rx, ry, rz, 0, 0, 0)
end

function gadget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
  if (unitDefID ~= mobileGunshipPlantID or not preMorphing[unitID]) then
    return
  end

  local preMorphData = preMorphing[unitID]

  if (cmdParams[1] == preMorphData.x and cmdParams[2] == preMorphData.y and cmdParams[3] == preMorphData.z) then
    return --avoid conflicting with the premorph move commands.
  end

  if (cmdParams[1] == 404) then
    return --avoid conflicting with the premorph build commands.
  end

  Spring.Echo('cancelling premorph of ' .. unitID .. ' cmdID ' .. cmdID)
  Spring.Echo('pmd x: ' .. preMorphData.x .. ' y: ' .. preMorphData.y .. ' z: ' .. preMorphData.z)
  for i, param in ipairs(cmdParams) do
    Spring.Echo(i .. ': ' .. param)
  end

  preMorphing[unitID] = nil
end

function gadget:GameFrame(frame)
  local genericMorphCmd = GG.MorphInfo["CMD_MORPH_BASE_ID"]

  for unitID, preMorphData in pairs(preMorphing) do
    if preMorphData then
      if preMorphData.needsMove then
        --defer move command because it can not be issued in AllowUnitCreation.
        Spring.GiveOrderToUnit(preMorphData.unitID, CMD.MOVE, {preMorphData.x, preMorphData.y, preMorphData.z}, 0)
        preMorphing[unitID].needsMove = false
      end

      local found = Spring.GetUnitsInBox(
        preMorphData.x - LANDING_BOX_SZ, preMorphData.y - LANDING_BOX_SZ, preMorphData.z - LANDING_BOX_SZ,
        preMorphData.x + LANDING_BOX_SZ, preMorphData.y + LANDING_BOX_SZ, preMorphData.z + LANDING_BOX_SZ
      )
      for _, foundID in ipairs(found) do
        Spring.Echo('found ' .. foundID)
        if unitID == foundID then
          Spring.SetUnitPosition(unitID, preMorphData.x, preMorphData.y, preMorphData.z)
          Spring.SetUnitRotation(unitID, 0, 0, 0)
          Spring.GiveOrderToUnit(unitID, genericMorphCmd, {gunshipPlantID}, 0)
          preMorphing[unitID] = nil
        end
      end
    end
  end
end


end --SYNCED
