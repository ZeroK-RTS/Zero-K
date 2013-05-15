function gadget:GetInfo()
  return {
    name      = "Orbital Drop",
    desc      = "Makes units spawned with GG.DropUnit fall from the sky.",
    author    = "quantum",
    date      = "November 2010", --February 2013
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end
--Note: 2 new FIXME: unit wiggle hax & MoveCtrl.SetGravity magic number.

if not gadgetHandler:IsSyncedCode() then
  return false -- no unsynced code
end

local Spring = Spring

----- Settings -----------------------------------------------------------------

local timeToGround = 160 --customizable (frame)

local fallGravity = -1*Game.gravity/30/30 --customizable (elmo/frame^2)
local unitSpawnHeight = 3000 --customizable (elmo)
local unitBrakeHeight = 500 --customizable (elmo)

----------------------------------------------------------------------------------

local initialFallVelocity = 0 --non-customizable/is-overriden (elmo/frame)
local brakeGravity = -7.8 --non-customizable/is-overriden (elmo/frame^2)

do	--Question:What this do? Answer:it automatically configure drop behaviour using value in Settings.
	--see Appendix for sources of the following formula:
	local fallPeriod =  timeToGround/(1+(2*unitBrakeHeight)/(unitSpawnHeight-unitBrakeHeight)) --estimated
	local brakePeriod = (2*unitBrakeHeight)/((unitSpawnHeight-unitBrakeHeight)/fallPeriod+fallGravity*fallPeriod/2)
	brakeGravity = -1*((unitSpawnHeight-unitBrakeHeight)/fallPeriod+fallGravity*fallPeriod/2)/brakePeriod
	initialFallVelocity = -1*((unitSpawnHeight-unitBrakeHeight)/fallPeriod-fallGravity*fallPeriod/2)
	
	brakeGravity = brakeGravity/0.1444444 --have no choice, a magic scalar. FIXME: Spring91 require this magic number
	fallGravity = fallGravity/0.1444444
end

local units = {}

local function StartsWith(s, startString)
  return string.sub(s, 1, #startString) == startString
end


function GG.DropUnit(unitDefName, x, y, z, facing, teamID)
  local gy = Spring.GetGroundHeight(x, z)
  if y < gy then y = gy end
  local unitID = Spring.CreateUnit(unitDefName, x, y, z, facing, teamID)
  if StartsWith(unitDefName, "chicken") then -- don't drop chickens, make them appear in a cloud of dirt instead
    Spring.SpawnCEG("dirt3", x, y, z)
    return unitID
  end
  local unitDef = UnitDefNames[unitDefName]
  if not unitDef.isBuilding and unitDef.speed > 0 and Spring.GetGameFrame() > 1 then
    y = Spring.GetGroundHeight(x, z) + unitSpawnHeight
    units[unitID] = y
    Spring.MoveCtrl.Enable(unitID)
    Spring.MoveCtrl.SetPosition(unitID, x, y, z)
    Spring.MoveCtrl.SetVelocity(unitID,0,initialFallVelocity,0)
    Spring.MoveCtrl.SetGravity(unitID, fallGravity)
  end
  return unitID
end


function gadget:GameFrame(frame)
  for unitID, yLast in pairs(units) do
    if Spring.ValidUnitID(unitID) then
      local x, y, z = Spring.GetUnitPosition(unitID)
      local h = Spring.GetGroundHeight(x, z)
      local _, dy = Spring.GetUnitVelocity(unitID)
      
      if y <= h or dy > 0 then -- unit has landed (or is moving upwards, which means it has missed the ground)
		if (y > unitBrakeHeight) then --unit is moving upwards but is not yet at BrakeHeight (which mean its being thrown upward purposely)
			Spring.Echo("Warning: Unit is thrown upward! timeToGround might be too big.")
		end
        Spring.MoveCtrl.SetPosition(unitID, x, h, z)
        Spring.MoveCtrl.SetVelocity(unitID, 0, 0, 0)
        Spring.MoveCtrl.Disable(unitID)
        units[unitID] = nil
		Spring.AddUnitImpulse(unitID,0,1,0) --wiggle abit. FIXME: Spring91 unit will APPEARs to stuck (not actually stuck) in the sky when SetGravity = 1, SetVelocity = 8, and then Disable.
		Spring.AddUnitImpulse(unitID,0,-1,0)
      elseif y < h + unitBrakeHeight then
        -- unit is braking
        Spring.MoveCtrl.SetGravity(unitID, brakeGravity)
		if frame % 2 == 0 then
			Spring.SpawnCEG("vindiback", x, y - 20, z) -- black dust
			Spring.SpawnCEG("banishertrail", x + 10, y - 40, z + 10) -- braking thrusters
			Spring.SpawnCEG("banishertrail", x - 10, y - 40, z + 10)
			Spring.SpawnCEG("banishertrail", x + 10, y - 40, z - 10)
			Spring.SpawnCEG("banishertrail", x - 10, y - 40, z - 10)
		end
		units[unitID] = y
      else
	  	-- unit is falling
		if frame % 2 == 0 then
			Spring.SpawnCEG("raventrail", x, y - 40, z) -- meteor trail
		end
		units[unitID] = y
      end
    else
      units[unitID] = nil
    end
  end
end





--Appendix for auto-configure algorithm (FOR REFERENCE ONLY!) by msafwan
--[[
--all start with equation of motion:
fallDist = initVel*fallPeriod + fallAcc*(fallPeriod^2)/2 <---START(1) equation of motion
initVel = fallDist/fallPeriod - fallAcc*fallPeriod/2 <--FINISH(1) (equation for getting initial velocity)

finalVel = initVel + fallAcc*fallPeriod <---START(2) equation of motion
finalVel = (fallDist/fallPeriod - fallAcc*fallPeriod/2) + fallAcc*fallPeriod
finalVel = fallDist/fallPeriod + fallAcc*fallPeriod/2 <--FINISH(2) (equation for getting final velocity)

0 = finalVel - brakeAcc* brakePeriod <---START(3) equation of motion
brakeAcc = (fallDist/fallPeriod + fallAcc*fallPeriod/2)/brakePeriod <--FINISH(3) (equation for getting brake acceleration)

brakeDist = finalVel*brakePeriod - brakeAcc*(brakePeriod^2)/2 <---START(4) equation of motion
brakeDist = (fallDist/fallPeriod + fallAcc*fallPeriod/2)*brakePeriod - (fallDist/fallPeriod + fallAcc*fallPeriod/2)*brakePeriod/2
brakeDist = (fallDist/fallPeriod + fallAcc*fallPeriod/2)*brakePeriod*(1-1/2)
2*brakeDist/brakePeriod = (fallDist/fallPeriod + fallAcc*fallPeriod/2)
brakePeriod = 2*brakeDist/(fallDist/fallPeriod + fallAcc*fallPeriod/2) <--FINISH(4) (equation for getting brake period)

totalTime = fallPeriod + brakePeriod <---START(5) sum
totalTime = fallPeriod + 2*brakeDist/(fallDist/fallPeriod + fallAcc*fallPeriod/2)
--assume gravity is 0, then:
totalTime = fallPeriod*(1+ 2*brakeDist/fallDist) --FINISH(5) (equation for estimating fallperiod from total time)
--]]