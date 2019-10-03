--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
  return {
    name      = "Orbital Drop",
    desc      = "Makes units spawned with GG.DropUnit fall from the sky.",
    author    = "quantum, msafwan", --msafwan add dynamic/configurable orbital drop
    date      = "November 2010", --7 April 2013
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end
--Note: 2 new FIXME: unit wiggle hax & MoveCtrl.SetGravity magic number.

local SAVE_FILE = "Gadgets/mission_orbital_drop.lua"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

local Spring = Spring
local emptyTable = {}
local LOS_ACCESS = {inlos = true}

----- Settings -----------------------------------------------------------------

local defTimeToGround = 160 --customizable (frame).
local defFallGravity = Game.gravity/30/30 --customizable (elmo/frame^2) positive is upward
local defSpawnHeight = 3000 --height above groundlevel, is customizable (in elmo)
local defBrakeHeight = 500 --height above groundlevel,is customizable (in elmo)

----------------------------------------------------------------------------------
----- Auto-Configure --------------------------------------------------------------
--NOTE: might look convoluted but it work.
--To call for unit drop simply do "GG.DropUnit(unitDefName|unitDefID, x, y, z, facing, teamID,[useSetUnitVelocity,[timeToGround, [fallGravity,[absSpawnHeight,[absBrakeHeight]]]]])"
--For safety, please don't use 0 as timeToGround.
--Use "useSetUnitVelocity=true" when MoveCtrl usage cause problem (MoveCtrl is prefered by this gadget).
--TODO: remove safety, make unit crash and explode like asteroid as a feature.

local units = {} -- the only thing that needs saving
local cachedResult = {} -- caches the falling behaviour based on time to ground, fall gravity, unit spawn height and unit brake height

_G.units = units

local function GetFallProfile(timeToGround, fallGravity,unitSpawnHeight,unitBrakeHeight)
	--INFO: this create drop behaviour using the value in argument. All argument can be either custom value or default value or mixed
	--see Appendix for sources of used formula:
	local speedProfile
	local cacheIndex = timeToGround .."@".. fallGravity .. "@" .. unitSpawnHeight .. "@" .. unitBrakeHeight
	speedProfile = cachedResult[cacheIndex]
	if (not cachedResult[cacheIndex]) then
		local fallPeriod_est =  timeToGround/(1+(2*unitBrakeHeight)/(unitSpawnHeight-unitBrakeHeight)) --estimated
		
		local initFallDist = (unitSpawnHeight-unitBrakeHeight)
		local a= fallGravity/2
		local b=2*unitBrakeHeight+initFallDist
		local c=timeToGround*initFallDist
		local nextEstimateFallPeriod =fallPeriod_est
		count = 0
		repeat --find exact fall period:
			--THIS IS NEWTON METHOD: x_next = x_current - f(x_current)/f'(x_current) (USED TO SOLVE POLYNOMIAL EQUATION SUCH AS FINDING SQUARE ROOT, LIKE IN CALCULATOR)
			estimateFallPeriod = nextEstimateFallPeriod
			nextEstimateFallPeriod = estimateFallPeriod - ((timeToGround-estimateFallPeriod)*a*(estimateFallPeriod^2) + b*estimateFallPeriod - c)/((timeToGround-estimateFallPeriod)*a*2*estimateFallPeriod + b)
			count = count +1
		until ((count > 22) or (math.modf(nextEstimateFallPeriod)==math.modf(estimateFallPeriod))) --loop until next estimate == previous estimate. Note: typically only took 4 loop
		
		local fallPeriod = nextEstimateFallPeriod
		local brakePeriod = -(2*unitBrakeHeight)/(-initFallDist/fallPeriod+fallGravity*fallPeriod/2)
		local brakeGravity = (initFallDist/fallPeriod-fallGravity*fallPeriod/2)/brakePeriod -- in elmo/frame^2
		local initialFallVelocity = -initFallDist/fallPeriod-fallGravity*fallPeriod/2 --in elmo/frame
		local finalFallVelocity =initialFallVelocity + fallGravity*fallPeriod
		
		speedProfile={} --NOTE: we set velocity instead of letting Spring to simulate them (with acceleration) because simulation always not accurate.
		for i=1, fallPeriod do --falling phase
			speedProfile[#speedProfile+1]= initialFallVelocity + fallGravity*i
		end
		for i=1, brakePeriod do --brake phase + 15 frame extra
			speedProfile[#speedProfile+1]= finalFallVelocity + brakeGravity*i
		end
		cachedResult[cacheIndex]=speedProfile --remember reference to this speed profile for repeated use
	end
	return speedProfile
end
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

local function StartsWith(s, startString)
  return string.sub(s, 1, #startString) == startString
end


function GG.DropUnit(unitDefName, x, y, z, facing, teamID, useSetUnitVelocity, timeToGround, fallGravity, absSpawnHeight, absBrakeHeight, dyncommID, staticDyncommLevel, dynamicCommanderOnly)
  local gy = Spring.GetGroundHeight(x, z)
  if y < gy then
    y = gy
  end
  local unitID = (dyncommID and GG.Upgrades_CreateStarterDyncomm and GG.Upgrades_CreateStarterDyncomm(dyncommID, x, y, z, facing, teamID, staticDyncommLevel))
  if (not unitID) and (not dynamicCommanderOnly) then
    unitID = Spring.CreateUnit(unitDefName, x, y, z, facing, teamID)
  end
  if not Spring.ValidUnitID(unitID) then
    Spring.Echo("Orbital Drop error: unitID from" .. unitDefName .." is invalid. No orbital drop for this unit.")
	return
  end
  if type(unitDefName)=='number' then --incase other gadget use unitDefID, then convert to unitDefNames
    unitDefName = UnitDefs[unitDefName].name
  end
  if StartsWith(unitDefName, "chicken") then -- don't drop chickens, make them appear in a cloud of dirt instead
    Spring.SpawnCEG("dirt3", x, y, z)
    return unitID
  end
  local unitDef = UnitDefNames[unitDefName]
  if (unitDef == nil) then -- dynamic comm
    unitDef = UnitDefs[Spring.GetUnitDefID(unitID)]
  end
  if not unitDef.isImmobile and Spring.GetGameFrame() > 1 and ((not timeToGround) or timeToGround > 0) then
	timeToGround,fallGravity,absSpawnHeight,absBrakeHeight = timeToGround or defTimeToGround,fallGravity or defFallGravity,absSpawnHeight or defSpawnHeight,absBrakeHeight or defBrakeHeight --check input for NIL
    y = gy + absSpawnHeight+10 --spawn height
	local speedProfile = GetFallProfile(timeToGround, fallGravity,absSpawnHeight,absBrakeHeight)
    local heading =0
	if useSetUnitVelocity then
		Spring.SetUnitPosition(unitID, x, y, z) --set unit position in the air
		Spring.AddUnitImpulse(unitID,0,4,0) --wiggle hax. this prevent unit from teleporting to ground. Note: Spring91 need +1/-1 for wiggle hax, but Spring 94 need +4/-4
		Spring.AddUnitImpulse(unitID,0,-4,0) --FIXME: if fixed, remove this +4/-4 hax.
		Spring.SetUnitVelocity(unitID,0,speedProfile[1],0) --apply initial velocity
		heading = Spring.GetUnitHeading(unitID) --get current heading (to be maintained during drop, else unit will tumble)
		heading = -heading*(math.pi*2/2^16) --convert Spring's heading unit into radian. note:heading must be multiply by negative for use by SetUnitRotation()
	else
		Spring.MoveCtrl.Enable(unitID)
		Spring.MoveCtrl.SetPosition(unitID, x, y, z)
		Spring.MoveCtrl.SetVelocity(unitID,0,speedProfile[1],0) --apply initial velocity & first gravity
		Spring.MoveCtrl.SetGravity(unitID,0)
	end
	units[unitID] = {2,absBrakeHeight+gy,heading,useSetUnitVelocity,speedProfile} --store speed profile index, store braking height , store heading , store speed profile
	gadgetHandler:UpdateCallIn("GameFrame")

	Spring.SetUnitRulesParam(unitID, "orbitalDrop", 1, LOS_ACCESS)

	-- prevent units from shooting while falling
	if GG.UpdateUnitAttributes then
		Spring.SetUnitRulesParam(unitID, "selfReloadSpeedChange", 0, LOS_ACCESS)
		GG.UpdateUnitAttributes(unitID)
	end
	-- can't be shot either (in Spring ~100 enemies will shoot at the ground below them)
	-- problem is enemies won't re-engage even after neutrality is removed
	--Spring.SetUnitNeutral(unitID, true)
  end

  return unitID
end


function gadget:GameFrame(frame)
  if not next(units) then
    gadgetHandler:RemoveCallIn("GameFrame")
    return
  end

  for unitID, controlValue in pairs(units) do
    if Spring.ValidUnitID(unitID) then
      local x, y, z = Spring.GetUnitPosition(unitID)
      local groundH = Spring.GetGroundHeight(x, z)
      local _,dy= Spring.GetUnitVelocity(unitID)
	  local index = controlValue[1]
	  local brakeAltitude = controlValue[2] --get unit's braking height
	  local heading = controlValue[3] --original heading
	  local useSetUnitVelocity = controlValue[4] --is using MoveCtrl?
	  local speedProfile =  controlValue[5]
	  if speedProfile[index+4] then --if next 4 index have content
		units[unitID][1] = controlValue[1] +1 -- ++index
	  end
	  if useSetUnitVelocity then
	    Spring.SetUnitVelocity(unitID,0,0,0) --Note: adding zero speed first & then desired speed later will make unit obey speed more accurately!
		Spring.SetUnitVelocity(unitID,0,speedProfile[index],0)
		Spring.SetUnitRotation(unitID,0,heading,0)
	  else
	    Spring.MoveCtrl.SetVelocity(unitID,0,0,0) --Note: adding zero speed first & then desired speed later will make unit obey speed more accurately!
		Spring.MoveCtrl.SetVelocity(unitID,0,speedProfile[index],0)
	  end
      
      if y < groundH+10  or dy >= 0.1 then --if unit touch the ground or missed its landing point (ie: landing height is set above ground)
		-- unit has landed
		if useSetUnitVelocity then
			Spring.SetUnitVelocity(unitID,0,0,0) --nullify unit's remaining speed
		else
			Spring.MoveCtrl.SetVelocity(unitID,0,0,0)
			Spring.MoveCtrl.Disable(unitID)
			--Spring.AddUnitImpulse(unitID,0,4,0) --wiggle hax. this prevent 1 rare bug that could happen if MoveCtrl unit is launch upward and then aborted (unit will appear to stay in the air but actually is on ground). Note: Spring91 need +1/-1 for wiggle hax, but Spring 94 need +4/-4
			--Spring.AddUnitImpulse(unitID,0,-4,0) --FIXME: when fixed, remove this +4/-4 hax.
		end
		Spring.GiveOrderToUnit(unitID, CMD.WAIT, emptyTable, 0)	-- WAIT WAIT to make unit continue with any orders it has
		Spring.GiveOrderToUnit(unitID, CMD.WAIT, emptyTable, 0)
		--Spring.Echo(units[unitID][1]) --see if it match desired timeToGround
		if GG.UpdateUnitAttributes then
			Spring.SetUnitRulesParam(unitID, "selfReloadSpeedChange", 1, LOS_ACCESS)
			Spring.SetUnitRulesParam(unitID, "orbitalDrop", 0, LOS_ACCESS)
			GG.UpdateUnitAttributes(unitID)
		end
		units[unitID]= nil --remove from watchlist
      elseif y < brakeAltitude+10  then
        -- unit is braking
		if frame % 2 == 0 then
			Spring.SpawnCEG("vindiback", x, y - 20, z) -- black dust
			Spring.SpawnCEG("banishertrail", x + 10, y - 40, z + 10) -- braking thrusters
			Spring.SpawnCEG("banishertrail", x - 10, y - 40, z + 10)
			Spring.SpawnCEG("banishertrail", x + 10, y - 40, z - 10)
			Spring.SpawnCEG("banishertrail", x - 10, y - 40, z - 10)
		end
		--if Spring.GetUnitNeutral(unitID) then
		--	Spring.SetUnitNeutral(unitID, true)
		--end
      else
	  	-- unit is falling
		if frame % 2 == 0 then
			Spring.SpawnCEG("raventrail", x, y - 40, z) -- meteor trail
		end
      end
    else
      units[unitID]= nil --unit is dead
    end
  end
end

function gadget:Load(zip)
	if not (GG.SaveLoad and GG.SaveLoad.ReadFile) then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	
	local loadData = GG.SaveLoad.ReadFile(zip, "Orbital Drop", SAVE_FILE) or {}
	local currGameFrame = Spring.GetGameRulesParam("lastSaveGameFrame") or 0
	local loadedUnits = {}
	for oldID,entry in pairs(loadData) do
		local unitID = GG.SaveLoad.GetNewUnitID(oldID)
		local speedProfile = GetFallProfile(defTimeToGround, defFallGravity, defSpawnHeight, defBrakeHeight)
		entry[5] = speedProfile
		local x,y,z = Spring.GetUnitPosition(unitID)
		
		if entry[4] then	-- velocity-based drop
			Spring.AddUnitImpulse(unitID,0,4,0) --wiggle hax. this prevent unit from teleporting to ground. Note: Spring91 need +1/-1 for wiggle hax, but Spring 94 need +4/-4
			Spring.AddUnitImpulse(unitID,0,-4,0) --FIXME: if fixed, remove this +4/-4 hax.
			Spring.SetUnitVelocity(unitID,0,speedProfile[1],0) --apply initial velocity
			heading = Spring.GetUnitHeading(unitID) --get current heading (to be maintained during drop, else unit will tumble)
			heading = -heading*(math.pi*2/2^16) --convert Spring's heading unit into radian. note:heading must be multiply by negative for use by SetUnitRotation()
		else	-- movectrl drop
			Spring.MoveCtrl.Enable(unitID)
			Spring.MoveCtrl.SetPosition(unitID, x, y, z)
			Spring.MoveCtrl.SetVelocity(unitID,0,speedProfile[1],0) --apply initial velocity & first gravity
			Spring.MoveCtrl.SetGravity(unitID,0)
		end
		
		loadedUnits[unitID] = entry
	end
	units = loadedUnits
	_G.units = units

	if next(units) then
		gadgetHandler:UpdateCallIn("GameFrame")
	else
		gadgetHandler:RemoveCallIn("GameFrame")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------

function gadget:Save(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	
	local toSave = Spring.Utilities.MakeRealTable(SYNCED.units, "Orbital Drop")
	for unitID, data in pairs(toSave) do
		data[5] = nil
	end
	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, toSave)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end

--Appendix for auto-configure algorithm (FOR REFERENCE ONLY!) by msafwan
--[[
NOTE, all start with equation of motion:

--Case 1: fall phase initial velocity
-fallDist = initVel*fallPeriod + fallAcc*(fallPeriod^2)/2
-fallDist/fallPeriod = initVel + fallAcc*(fallPeriod)/2
initVel = -fallDist/fallPeriod - fallAcc*fallPeriod/2

--Case 2: fall phase final velocity
finalVel = initVel + fallAcc*fallPeriod
finalVel = (-fallDist/fallPeriod - fallAcc*fallPeriod/2) + fallAcc*fallPeriod --inserted case 1 here
finalVel = -fallDist/fallPeriod + fallAcc*fallPeriod/2

--Case 3: brake phase deacceleration
0 = finalVel + brakeAcc* brakePeriod --inserted case 2 here
0 = -fallDist/fallPeriod + fallAcc*fallPeriod/2 + brakeAcc* brakePeriod
- brakeAcc* brakePeriod = -fallDist/fallPeriod + fallAcc*fallPeriod/2
-brakeAcc = (-fallDist/fallPeriod + fallAcc*fallPeriod/2)/brakePeriod
brakeAcc = (fallDist/fallPeriod - fallAcc*fallPeriod/2)/brakePeriod

--Case 4: braking period
-brakeDist = finalVel*brakePeriod + brakeAcc*(brakePeriod^2)/2 --inserted case 3 and case 2 here
-brakeDist = (-fallDist/fallPeriod + fallAcc*fallPeriod/2)*brakePeriod + ((fallDist/fallPeriod - fallAcc*fallPeriod/2)/brakePeriod)(brakePeriod^2)/2
-brakeDist = (-fallDist/fallPeriod + fallAcc*fallPeriod/2)*brakePeriod + (fallDist/fallPeriod - fallAcc*fallPeriod/2)*brakePeriod/2
-brakeDist = (-fallDist/fallPeriod + fallAcc*fallPeriod/2)*brakePeriod - (-fallDist/fallPeriod + fallAcc*fallPeriod/2)*brakePeriod/2
-brakeDist = (-fallDist/fallPeriod + fallAcc*fallPeriod/2)*brakePeriod*(1-1/2)
-brakeDist = (-fallDist/fallPeriod + fallAcc*fallPeriod/2)*brakePeriod*(1/2)
-2*brakeDist/brakePeriod = (-fallDist/fallPeriod + fallAcc*fallPeriod/2)
brakePeriod = -2*brakeDist/(-fallDist/fallPeriod + fallAcc*fallPeriod/2)

--Case 5: total time for both phase
totalTime = fallPeriod + brakePeriod
totalTime = fallPeriod -2*brakeDist/(-fallDist/fallPeriod + fallAcc*fallPeriod/2) --inserted case 4 here. This is equation (A)
totalTime = fallPeriod -2*brakeDist/(-fallDist/fallPeriod + fallAcc*fallPeriod/2)
totalTime - fallPeriod = -2*brakeDist/(-fallDist/fallPeriod + fallAcc*fallPeriod/2)
(totalTime - fallPeriod)*(-fallDist/fallPeriod + fallAcc*fallPeriod/2) = -2*brakeDist
-totalTime*fallDist/fallPeriod + totalTime*fallAcc*fallPeriod/2 + fallPeriod*fallDist/fallPeriod - fallPeriod*fallAcc*fallPeriod/2 = -2*brakeDist
-totalTime*fallDist/fallPeriod + totalTime*fallAcc*fallPeriod/2 + fallDist - fallAcc*fallPeriod^2/2 = -2*brakeDist
-totalTime*fallDist/fallPeriod + totalTime*fallAcc*fallPeriod/2 - fallAcc*fallPeriod^2/2 = -2*brakeDist - fallDist
-totalTime*fallDist + totalTime*fallAcc*fallPeriod^2/2 - fallAcc*fallPeriod^3/2 = (-2*brakeDist - fallDist)*fallPeriod
-totalTime*fallDist +(2*brakeDist + fallDist)*fallPeriod + totalTime*fallAcc*fallPeriod^2/2 - fallAcc*fallPeriod^3/2  = 0
-totalTime*fallDist +(2*brakeDist + fallDist)*fallPeriod + (totalTime - fallPeriod)*fallAcc*fallPeriod^2/2  = 0
a= fallAcc/2
b=2*brakeDist+fallDist
c=totalTime*fallDist
-c +b*fallPeriod + (totalTime - fallPeriod)*a*fallPeriod^2  = 0
f(fallPeriod) = (totalTime-fallPeriod)*a*fallPeriod^2 + b*fallPeriod - c
f'(fallPeriod) = (totalTime-fallPeriod)*a*2*fallPeriod + b --derivative of f()
*USE NEWTON METHOD TO GET fallPeriod USING f() AND f'()

--Case6: assume fall acceleration in equation (A) is insignificant, then: create estimate
totalTime_est = fallPeriod*(1+ 2*brakeDist/fallDist)
fallPeriod_est = totalTime/(1+ 2*brakeDist/fallDist)
--]]
