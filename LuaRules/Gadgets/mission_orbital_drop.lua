function gadget:GetInfo()
  return {
    name      = "Orbital Drop",
    desc      = "Makes units spawned in missions fall from the sky.",
    author    = "quantum",
    date      = "November 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end


if not gadgetHandler:IsSyncedCode() then
  return false -- no unsynced code
end

local Spring = Spring

----- Settings -----------------------------------------------------------------


local fallGravity = 1.5
local brakeGravity = -7.8
local unitSpawnHeight = 3000
local unitBrakeHeight = 500

----------------------------------------------------------------------------------

local units = {}


function GG.DropUnit(unitDefName, x, y, z, facing, teamID)
  local unitID = Spring.CreateUnit(unitDefName, x, 0, z, facing, teamID)
  local unitDef = UnitDefNames[unitDefName]
  if not unitDef.isBuilding and unitDef.speed > 0 and Spring.GetGameFrame() > 1 then
    y = Spring.GetGroundHeight(x, z) + unitSpawnHeight
    units[unitID] = true
    Spring.MoveCtrl.Enable(unitID)
    Spring.MoveCtrl.SetPosition(unitID, x, y, z)
    Spring.MoveCtrl.SetGravity(unitID, fallGravity)
  end
  return unitID
end


function gadget:GameFrame(frame)
  for unitID in pairs(units) do
    if Spring.ValidUnitID(unitID) then
      local x, y, z = Spring.GetUnitBasePosition(unitID)
      local h = Spring.GetGroundHeight(x, z)
      if y < h then
        Spring.MoveCtrl.SetPosition(unitID, x, h, z)
        Spring.MoveCtrl.SetVelocity(unitID, 0, 0, 0)
        Spring.MoveCtrl.Disable(unitID)
        units[unitID] = nil
      elseif y < h + unitBrakeHeight then
        Spring.MoveCtrl.SetGravity(unitID, brakeGravity)
        Spring.SpawnCEG("vindiback", x, y - 20, z)
        Spring.SpawnCEG("banishertrail", x + 10, y - 40, z + 10)
        Spring.SpawnCEG("banishertrail", x - 10, y - 40, z + 10)
        Spring.SpawnCEG("banishertrail", x + 10, y - 40, z - 10)
        Spring.SpawnCEG("banishertrail", x - 10, y - 40, z - 10)
      else
        Spring.SpawnCEG("raventrail", x, y - 40, z)
        -- Spring.SpawnCEG(burnEffect2, x, y, z)
      end
    else
      units[unitID] = nil
    end
  end
end