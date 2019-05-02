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

--let's start with Mobile Gunship Plant preMorphing and go from there.
--for general use we would build tables from all unitdefs.
local gunshipPlantID = UnitDefNames["factorygunship"].id
local mobileGunshipPlantID = UnitDefNames["factorymobilegunship"].id
local mobileGunshipPlants = {}

--keep track of units moving into morph position.
local preMorphing = {}

--track proxy nanoframes for later deletion.
local preMorphNanos = {}

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
  if unitDefID == mobileGunshipPlantID then
    --keep a list of mobile gunship plants in play.
    mobileGunshipPlants[unitID] = true
    return
  end

  if (unitDefID ~= gunshipPlantID or not mobileGunshipPlants[builderID]) then
    --if this is not morpher creating morphee, don't care.
    return
  end

  local x, y, z = Spring.GetUnitPosition(unitID)
  local rx, ry, rz = Spring.GetUnitRotation(unitID)

  Spring.GiveOrderToUnit(builderID, CMD.MOVE, {x, y, z}, 0)

  preMorphing[builderID] = {
    x = x,
    y = y,
    z = z,
    rx = rx,
    ry = ry,
    rz = rz,
  }

  table.insert(preMorphNanos, unitID)
end

function gadget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
  if (unitDefID ~= mobileGunshipPlantID or not preMorphing[unitID]) then
    return
  end

  local preMorphData = preMorphing[unitID]
  preMorphing[unitID] = false

  --make sure the build location hasn't become blocked while moving to it.
  --todo: check actual build facing
  blocking, featureID = Spring.TestBuildOrder(gunshipPlantID, preMorphData.x, preMorphData.y, preMorphData.z, 0)
  if (blocking < 2 or featureID ~= nil) then
    return
  end

  local genericMorphCmd = GG.MorphInfo["CMD_MORPH_BASE_ID"]

  Spring.SetUnitPosition(unitID, preMorphData.x, preMorphData.y, preMorphData.z)
  Spring.SetUnitRotation(unitID, preMorphData.rx, preMorphData.ry, preMorphData.rz)
  Spring.GiveOrderToUnit(unitID, genericMorphCmd, {gunshipPlantID}, 0)
end

function gadget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
  if (unitDefID ~= mobileGunshipPlantID or not preMorphing[unitID]) then
    return
  end

  local preMorphData = preMorphing[unitID]

  if (cmdParams[0] == preMorphData.x and cmdParams[1] == preMorphData.y and cmdParams[2] == preMorphData.z) then
    return --avoid race condition with the premorph move command.
  end

  preMorphing[unitID] = false
end

function gadget:GameFrame(frame)
  --destroying the proxy nanoframe is deferred until next game frame to workaround a nasty bug:
  --if you destroy the nanoframe in its UnitCreated call-in, the space it occupied can no longer be built on. rude!
  while table.getn(preMorphNanos) > 0 do
    local nanoID = table.remove(preMorphNanos)
    Spring.DestroyUnit(nanoID, false, true)
  end
end

end --SYNCED
