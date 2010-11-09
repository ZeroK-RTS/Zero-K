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

local function StartsWith(s, startString)
  return string.sub(s, 1, #startString) == startString
end


function GG.DropUnit(unitDefName, x, y, z, facing, teamID)
  local unitID = Spring.CreateUnit(unitDefName, x, 0, z, facing, teamID)
  if StartsWith(unitDefName, "chicken") then -- don't drop chickens, make them appear in a cloud of dirt instead
    local y = Spring.GetGroundHeight(x, z)
    Spring.SpawnCEG("dirt3", x, y, z)
    return unitID
  end
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
        -- unit has landed
        Spring.MoveCtrl.SetPosition(unitID, x, h, z)
        Spring.MoveCtrl.SetVelocity(unitID, 0, 0, 0)
        Spring.MoveCtrl.Disable(unitID)
        units[unitID] = nil
      elseif y < h + unitBrakeHeight then
        -- unit is braking
        Spring.MoveCtrl.SetGravity(unitID, brakeGravity)
        Spring.SpawnCEG("vindiback", x, y - 20, z) -- black dust
        Spring.SpawnCEG("banishertrail", x + 10, y - 40, z + 10) -- braking thrusters
        Spring.SpawnCEG("banishertrail", x - 10, y - 40, z + 10)
        Spring.SpawnCEG("banishertrail", x + 10, y - 40, z - 10)
        Spring.SpawnCEG("banishertrail", x - 10, y - 40, z - 10)
      else
        -- unit is falling
        Spring.SpawnCEG("raventrail", x, y - 40, z) -- meteor trail
      end
    else
      units[unitID] = nil
    end
  end
end