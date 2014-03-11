local version = "1.0.3"

function gadget:GetInfo()
  return {
    name      = "Ore mexes!",
    desc      = "Prespawn mex spots and make them spit ore. Version "..version,
    author    = "Tom Fyuri",
    date      = "Mar 2014",
    license   = "GPL v2 or later",
    layer     = -5,
    enabled   = true	-- now it comes with design!
  }
end

--SYNCED-------------------------------------------------------------------

--TODO storage should drop ore on death should you have no allies left to transfer ore to.
--TODO units should refuse to reclaim ore once entire allyteam is full on metal.
--TODO if dmg is enabled it should corrupt terrain!!!
--TODO different ore colors.

-- changelog
-- 11 march 2014 - 1.0.3. Growth rewrite, ore metal yield change, ore harm units now. Disobey OD fix. And transfer logic improvement.
-- 10 march 2014 - 1.0.2. Could be considered first working version.

local modOptions = Spring.GetModOptions()
if (gadgetHandler:IsSyncedCode()) then
  
local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spCallCOBScript  		= Spring.CallCOBScript
local spGetGroundHeight		= Spring.GetGroundHeight
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetTeamInfo 	    	= Spring.GetTeamInfo
local spCreateFeature		= Spring.CreateFeature
local spSetFeatureReclaim	= Spring.SetFeatureReclaim
local spSetFeatureDirection	= Spring.SetFeatureDirection
local spGetFeaturePosition 	= Spring.GetFeaturePosition
local spCreateUnit		= Spring.CreateUnit
local spGetUnitRulesParam	= Spring.GetUnitRulesParam
local spSetUnitRulesParam	= Spring.SetUnitRulesParam
local spGetUnitDefID		= Spring.GetUnitDefID
local GaiaTeamID		= Spring.GetGaiaTeamID()
local spGetUnitTeam		= Spring.GetUnitTeam
local spGetFeaturesInRectangle	= Spring.GetFeaturesInRectangle
local spGetUnitsInRectangle	= Spring.GetUnitsInRectangle
local GaiaAllyTeamID		= select(6,spGetTeamInfo(GaiaTeamID))
local spGetFeatureDefID		= Spring.GetFeatureDefID
local spTransferUnit		= Spring.TransferUnit
local spGetAllUnits		= Spring.GetAllUnits
local spGetGameFrame		= Spring.GetGameFrame
local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetTeamList		= Spring.GetTeamList
local spSetUnitNeutral		= Spring.SetUnitNeutral
local spValidUnitID	    	= Spring.ValidUnitID
local spGetUnitHealth		= Spring.GetUnitHealth
local spSetUnitHealth 		= Spring.SetUnitHealth
local spAddUnitDamage		= Spring.AddUnitDamage
local spDestroyUnit		= Spring.DestroyUnit
local spGetAllFeatures          = Spring.GetAllFeatures
local OreMexByID = {} -- by UnitID
local OreMex = {} -- for loop
local random = math.random
local cos   = math.cos
local sin   = math.sin
local pi    = math.pi
local floor = math.floor
local abs   = math.abs

local mapWidth
local mapHeight
local teamIDs
local UnderAttack = {} -- holds frameID per mex so it goes neutral, if someone attacks it, for 5 seconds, it will not return to owner if no grid connected.
local Ore = {} -- hold features should they emit harm they will ongameframe

local TiberiumProofDefs = {
  [UnitDefNames["armestor"].id] = true,
  [UnitDefNames["armwin"].id] = true,
  [UnitDefNames["armsolar"].id] = true,
  [UnitDefNames["armfus"].id] = true,
  [UnitDefNames["cafus"].id] = true,
  [UnitDefNames["geo"].id] = true,
  [UnitDefNames["amgeo"].id] = true,
  [UnitDefNames["cormex"].id] = true,
  [UnitDefNames['pw_generic'].id] = true,
  [UnitDefNames['pw_hq'].id] = true,
  [UnitDefNames['ctf_flag'].id] = true,
  [UnitDefNames['ctf_center'].id] = true,
  [UnitDefNames['tele_beacon'].id] = true, -- why not
  [UnitDefNames['terraunit'].id] = true, -- totally why not
} -- also any unit that has "chicken" inside its unitname and anything that can reclaim is also tiberium proof
-- more setup
for i=1,#UnitDefs do
  local ud = UnitDefs[i]
  if (ud.isBuilder and not(ud.isFactory) and not(ud.customParams.commtype)) or ud.name:find("chicken") then -- I pray this works and doesn't slow down load times too much
--   if (ud.isBuilder and not(ud.isFactory)) or (ud.customParams.commtype) or ud.name:find("chicken") then -- I pray this works and doesn't slow down load times too much
    TiberiumProofDefs[i] = true
  end
end
-- probably ore should damage commander, despite it having reclaim ability, otherwise you can stay in ore field and have advantage against raiders...
-- also maybe only pylon should be tiberium proof...

-- NOTE probably below defs could be generated on gamestart too
local energyDefs = { -- if gaia mex get's in range of any of below structures, it will trasmit it ownership
  [UnitDefNames["armestor"].id] = UnitDefNames["armestor"].customParams.pylonrange,
  [UnitDefNames["armwin"].id] = UnitDefNames["armwin"].customParams.pylonrange,
  [UnitDefNames["armsolar"].id] = UnitDefNames["armsolar"].customParams.pylonrange,
  [UnitDefNames["armfus"].id] = UnitDefNames["armfus"].customParams.pylonrange,
  [UnitDefNames["cafus"].id] = UnitDefNames["cafus"].customParams.pylonrange,
  [UnitDefNames["geo"].id] = UnitDefNames["geo"].customParams.pylonrange,
  [UnitDefNames["amgeo"].id] = UnitDefNames["amgeo"].customParams.pylonrange,
}
local mexDefs = {
  [UnitDefNames["cormex"].id] = true,
}
local PylonRange = UnitDefNames["armestor"].customParams.pylonrange

local INVULNERABLE_EXTRACTORS = (tonumber(modOptions.oremex_invul) == 1) -- invulnerability of extractors. they can still switch team side should OD get connected
local LIMIT_PRESPAWNED_METAL = modOptions.oremex_metal
if (tonumber(LIMIT_PRESPAWNED_METAL)==nil) then LIMIT_PRESPAWNED_METAL = 220 end
local PRESPAWN_EXTRACTORS = (tonumber(modOptions.oremex_prespawn) == 1)
local OBEY_OD = (tonumber(modOptions.oremex_overdrive) == 1)
local INFINITE_GROWTH = (tonumber(modOptions.oremex_inf) == 1) -- this causes performance drop you know...
local ORE_DMG = modOptions.oremex_harm
if (tonumber(ORE_DMG)==nil) then ORE_DMG = 0 end -- it's both slow and physical damage, be advised. albeit range is small. also it stacks, ore damages adjacent tiles!!
local ORE_DMG_RANGE = 81 -- so standing in adjacent tile is gonna harm you
local OBEY_ZLEVEL = (tonumber(modOptions.oremex_uphill) == 1) -- slower uphill growth
if (modOptions.oremex_uphill == nil) then OBEY_ZLEVEL = true end
local ZLEVEL_PROTECTION = 400 -- if adjacent tile is over 400 it's not gonna grow there at all -- lower Z tiles do not give speed boost though
local MAX_STEPS = 15 -- vine length
local MAX_PIECES = 144 -- anti spam measure, 144, it looks like cute ~7x7 square rotated 45 degree
local MIN_PRODUCE = 5 -- no less than 5 ore per 40x40 square otherwise spam lol...

if (INFINITE_GROWTH) then -- not enabled by default
  MAX_STEPS = 40 -- 40*40 = 1600 distance is maximum in length per mex, considering there are usually more than 1 mex on 2000x2000 map, it's supposed to surely cover entire map in "tiberium"
end

local function TransferMexTo(unitID, mexID, unitTeam)
  if (spValidUnitID(unitID)) and (mexID) then
    spSetUnitRulesParam(unitID, "mexIncome", OreMex[mexID].income)
    spCallCOBScript(unitID, "SetSpeed", 0, OreMex[mexID].income * 500) 
    -- ^ hacks?
    UnderAttack[unitID] = spGetGameFrame()+160
    spTransferUnit(unitID, unitTeam, false)
    spSetUnitNeutral(unitID, true)
  end
end

local function disSQ(x1,y1,x2,y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam)
  if (OreMexByID[unitID]) then
    if (unitTeam ~= GaiaTeamID) then
      TransferMexTo(unitID, OreMexByID[unitID], GaiaTeamID)
    end
    return 0
  end
end

local TransferLoop = function()
  for i=1,#OreMex do
    if (OreMex[i]~=nil) then
      local unitID = OreMex[i].unitID
      local x = OreMex[i].x
      local z = OreMex[i].z
      local unitTeam = spGetUnitTeam(unitID)
      local allyTeam = spGetUnitAllyTeam(unitID)
      if (x) and ((unitTeam==GaiaTeamID) or (INVULNERABLE_EXTRACTORS)) and (UnderAttack[unitID] <= spGetGameFrame()) then
	local units = spGetUnitsInCylinder(x, z, PylonRange+41)
	local best_eff = -1 -- lel
	local best_team
	local best_ally
	local enearby = false
	for i=1,#units do
	  local targetID = units[i]
	  local targetDefID = spGetUnitDefID(targetID)
	  local targetTeam = spGetUnitTeam(targetID)
	  local targetAllyTeam = spGetUnitAllyTeam(targetID)
	  if (energyDefs[targetDefID]) and (targetTeam~=GaiaTeamID) then
	    local maxdist = energyDefs[targetDefID]
	    maxdist=maxdist*maxdist
	    local x2,_,z2 = spGetUnitPosition(targetID)
	    if (disSQ(x,z,x2,z2) <= maxdist) then
	      enearby = true
	      local eff = spGetUnitRulesParam(targetID,"gridefficiency")
-- 	      Spring.MarkerAddPoint(x2,0,z2,eff)
	      if (eff~=nil) and (best_eff < eff) then
		best_eff = eff
		best_team = targetTeam
		best_ally = targetAllyTeam
	      end
	    end
	  end
	end
	if (best_team ~= nil) and (unitTeam ~= best_team) and (allyTeam ~= best_ally) then
	  TransferMexTo(unitID, i, best_team)
	elseif (INVULNERABLE_EXTRACTORS) and not(enearby) and (best_team == nil) and (unitTeam ~= GaiaTeamID) then -- back to Gaia you go
	  TransferMexTo(unitID, i, GaiaTeamID)
	end
      end
    end
  end
end

local function OreHarms(unitID)
  local health = spGetUnitHealth(unitID)
  if (health ~= nil) then
    if (health > ORE_DMG) then
      GG.addSlowDamage(unitID, ORE_DMG*2)
--       spAddUnitDamage(unitID, ORE_DMG, 0, GaiaTeamID) -- FIXME doesnt work, adds 40 damage regardless and instakills bots
      spSetUnitHealth(unitID, health-ORE_DMG) -- works flawlessly albeit regen doesnt disable, i can live with that
    else
      spDestroyUnit(unitID, false, false, GaiaTeamID)
    end
  end
end

-- damage is cylinder, not spherical
local InflictOreDamage = function()
  for oreID, _ in pairs(Ore) do
    local x,y,z = spGetFeaturePosition(oreID)
    if (x) then
      local units = spGetUnitsInCylinder(x,z,ORE_DMG_RANGE)
      for i=1,#units do
	local unitID = units[i]
	local unitDefID = spGetUnitDefID(unitID)
	if not(TiberiumProofDefs[unitDefID]) then
	  local ux,uy,uz = spGetUnitPosition(unitID)
	  if (abs(y-uy) <= ORE_DMG_RANGE) then
	    OreHarms(unitID)
	  end
	end
      end
    end
  end
end

-- if mex OD is off and it's godmode on, transfer mex to gaia team
-- if mex is inside energyDefs transfer mex to ally team having most gridefficiency (if im correct team having most gridefficiency should produce most E for M?)
function gadget:GameFrame(f)
  if ((f%32)==1) then
    TransferLoop()
    InflictOreDamage()
  end
end

function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
  if (attackerID) and (targetID) and (OreMexByID[targetID]) then
    return false, 1
  end
  return true, 1
end

local function UnitFin(unitID, unitDefID, unitTeam)
--   if (unitTeam ~= GaiaTeamID) and (OBEY_OD) then
--     if (energyDefs[unitDefID]) then
--       local x,_,z = spGetUnitPosition(unitID)
--       if (x) then
-- 	local units = spGetUnitsInCylinder(x, z, energyDefs[unitDefID]+10)
-- 	for i=1,#units do
-- 	  local targetID = units[i]
-- 	  if (OreMexByID[targetID]) and (spGetUnitTeam(targetID)==GaiaTeamID) and (UnderAttack[targetID] <= spGetGameFrame()) then
-- 	    TransferMexTo(targetID, i, unitTeam)
-- 	  end
-- 	end
--       end
--     end
--   end
  if (mexDefs[unitDefID]) then
    local x,y,z = spGetUnitPosition(unitID)
    if (x) then
      id = 1
      while (OreMex[id]~=nil) do
	id=id+1
      end
      OreMex[id] = {
	unitID = unitID,
	ore = 0, -- metal.
	income = spGetUnitRulesParam(unitID,"mexIncome"),
	x = x,
	z = z,
      }
      OreMexByID[unitID] = id
      UnderAttack[unitID] = -100
      if not(OBEY_OD) then -- this blocks OD should oremex_overdrive==false
	TransferMexTo(unitID, id, GaiaTeamID)
      end
    end
  end
end

local function CanSpawnOreAt(x,z)
  local features = spGetFeaturesInRectangle(x-30,z-30,x+30,z+30)
  for i=1,#features do
    local featureID = features[i]
    local featureDefID = spGetFeatureDefID(featureID)
    if (FeatureDefs[featureDefID].name=="ore") then
      return false
    end
  end
  return true
end

-- lets pick a direction where to grow, west/east/north/south
-- try to grow there, if it's not possible and map end reached, do not grow there and fail that "try"
-- hopefully random number will roll better direction next time, ore is not wasted anyway
local GrowBranch = function(x,y,z)
  local steps=0
  local direction = random(0,3)
  while (steps < MAX_STEPS) do
    if (CanSpawnOreAt(x,z)) then return x,z
    else -- could be slightly better optimised
      local way = random(0,3)
      if (way ~= direction) then
	if (way==0) then
	  if ((x-40)<=0) then
	    return nil -- fail
	  end
	  x=x-40
	elseif (way==2) then
	  if ((x+40)>=mapWidth) then
	    return nil -- fail
	  end
	  x=x+40
	elseif (way==1) then
	  if ((z-40)<=0) then
	    return nil -- fail
	  end
	  z=z-40
	elseif (way==3) then
	  if ((z+40)>=mapHeight) then
	    return nil -- fail
	  end
	  z=z+40
	end -- otherwise stay at place
      end
    end
    steps = steps+1
  end
  return nil
end
if (OBEY_ZLEVEL) then -- more expensive algo if we obey z level (dont grow uphill)
  GrowBranch = function(x,y,z)
    local ox = x
    local oz = z
    local steps=0
    local direction = random(0,3)
    while (steps < MAX_STEPS) do
      if (CanSpawnOreAt(x,z)) then return x,z
      else -- could be slightly better optimised
	local way = random(0,3)
	if (way ~= direction) then
	  if (way==0) then
	    if ((x-40)<=0) then
	      return nil -- fail
	    end
	    if (spGetGroundHeight(x-40,z)-random(0,ZLEVEL_PROTECTION) <= spGetGroundHeight(x,z)) then 
	      x=x-40
	    else -- try again, can't grow there
	      x = ox
	      z = oz
	      steps = floor(steps/2)
	    end
	  elseif (way==2) then
	    if ((x+40)>=mapWidth) then
	      return nil -- fail
	    end
	    if (spGetGroundHeight(x+40,z)-random(0,ZLEVEL_PROTECTION) <= spGetGroundHeight(x,z)) then 
	      x=x+40
	    else -- try again, can't grow there
	      x = ox
	      z = oz
	      steps = floor(steps/2)
	    end
	  elseif (way==1) then
	    if ((z-40)<=0) then
	      return nil -- fail
	    end
	    if (spGetGroundHeight(x,z-40)-random(0,ZLEVEL_PROTECTION) <= spGetGroundHeight(x,z)) then 
	      z=z-40
	    else -- try again, can't grow there
	      x = ox
	      z = oz
	      steps = floor(steps/2)
	    end
	  elseif (way==3) then
	    if ((z+40)>=mapHeight) then
	      return nil -- fail
	    end
	    if (spGetGroundHeight(x,z+40)-random(0,ZLEVEL_PROTECTION) <= spGetGroundHeight(x,z)) then 
	      z=z+40
	    else -- try again, can't grow there
	      x = ox
	      z = oz
	      steps = floor(steps/2)
	    end
	  end -- otherwise stay at place
	end
      end
      steps = steps+1
    end
    return nil
  end
end

local function SpawnOre(a, b, spawn_amount, teamID)
  local oreID = spCreateFeature("ore", a, spGetGroundHeight(a, b), b, "n", teamID)
  if (oreID) then
    spSetFeatureReclaim(oreID, spawn_amount)
    local rd = random(360) * pi / 180
    spSetFeatureDirection(oreID,sin(rd),0,cos(rd))
    Ore[oreID] = true
    return true
  end
  return false
end

function gadget:FeatureDestroyed(featureID, allyTeam)
  if (Ore[featureID]) then
    Ore[featureID] = nil
  end
end

function MineMoreOre(unitID, howMuch, forcefully)
  local MexID = OreMexByID[unitID]
  if not(OreMex[MexID]) then return end -- in theory never happens...
  OreMex[MexID].ore = OreMex[MexID].ore + howMuch
  local ore = OreMex[MexID].ore
  if not(forcefully) then
    OreMex[MexID].income = howMuch
  end
  local x,y,z = spGetUnitPosition(unitID)
  if not(INFINITE_GROWTH) then -- rejoice Killer
    local features = spGetFeaturesInRectangle(x-240,z-240,x+240,z+240)
    if (#features > MAX_PIECES) and not(forcefully) then return end -- too much reclaim, please reclaim
  end
  local sp_count = 3
  if (ore < 6) then
    sp_count = 2
    if (ore < 3) then
      sp_count = 1
    end
  end
  local teamID = spGetUnitTeam(unitID)
  if (#teamIDs>1) then
    teamID = random(0,#teamIDs)
    while (teamID == GaiaTeamID) do
      teamID = random(0,#teamIDs)
    end
  end
  if (ore>=1) then
    try=0
    -- lets see, it tries to spawn 3 ore chunks every time
    -- lets try spawning 40% of ore amount every time
    local spawn_amount = ore*0.4
    if (forcefully) then
      spawn_amount = ore*0.6 -- more chance to drop everything, regardless
    elseif (spawn_amount<MIN_PRODUCE) then -- try to spawn minchunk
      spawn_amount = MIN_PRODUCE
    end
    while (try < sp_count) do
      local a,b = GrowBranch(x,y,z) -- v2, pick direction grow there, do not go back in direction, it should be more like a tree, probably
      if (a~=nil) then
	if (ore >= spawn_amount) then -- is it enough?
	  if (SpawnOre(a,b,spawn_amount,teamID)) then
	    ore = ore - spawn_amount
	  end
	end
      end
      try=try+1
    end
    if (forcefully) and (ore >= 1) then -- drop all thats left on mex
      if (SpawnOre(x,z,ore,teamID)) then
	ore = 0
      end
    end
  end
  OreMex[MexID].ore = ore
end
GG.SpawnMoreOre = MineMoreOre

local function GetFloatHeight(x,z)
  local height = spGetGroundHeight(x,z)
  if (height < waterLevel) then
    return waterLevel
  end
  return height
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
  if (OreMexByID[unitID]) then
    MineMoreOre(unitID, 0, true) -- this will order it to spawn everything it has left
    local mexID = OreMexByID[unitID]
    OreMex[mexID]=nil
    OreMexByID[unitID]=nil
    UnderAttack[unitID]=0
  end
end

local function PreSpawn()
  if (GG.metalSpots) then -- if map has metal spots, prespawn mexes, otherwise players can build them themselves. also prespawn 120 metal ore. scattered.
    for i = 1, #GG.metalSpots do
      local units = spGetUnitsInRectangle(GG.metalSpots[i].x-1,GG.metalSpots[i].z-1,GG.metalSpots[i].x+1,GG.metalSpots[i].z+1)
      if (units == nil) or (#units==0) then
	local unitID = spCreateUnit("cormex",GG.metalSpots[i].x, GetFloatHeight(GG.metalSpots[i].x,GG.metalSpots[i].z), GG.metalSpots[i].z, "n", GaiaTeamID)
	if (unitID) then
	  local id = #OreMex+1
	  OreMex[id] = {
	    unitID = unitID,
	    ore = 0, -- metal.
	    income = GG.metalSpots[i].metal,
	    x = GG.metalSpots[i].x,
	    z = GG.metalSpots[i].z,
	  }
	  if (INVULNERABLE_EXTRACTORS) then
	    spSetUnitNeutral(unitID, true)
	  end
	  OreMexByID[unitID] = id
	  UnderAttack[unitID] = -100
	  spSetUnitRulesParam(unitID, "mexIncome", GG.metalSpots[i].metal)
	  spCallCOBScript(unitID, "SetSpeed", 0, GG.metalSpots[i].metal * 500) 
	  local prespawn = 0
	  while (prespawn < LIMIT_PRESPAWNED_METAL) do
	    MineMoreOre(unitID, 30, true)
	    prespawn=prespawn+30
	  end
	  if (LIMIT_PRESPAWNED_METAL-prespawn)>=5 then -- i dont want to spawn ~1m "leftovers", chunks are ok
	    MineMoreOre(unitID, LIMIT_PRESPAWNED_METAL-prespawn, true)
	  end
	end
      end
    end
    return true
  else
    return false
  end
end

local function ReInit(reinit)
  mapWidth = Game.mapSizeX
  mapHeight = Game.mapSizeZ
  teamIDs = spGetTeamList()
  if (PRESPAWN_EXTRACTORS) then
    if not(PreSpawn()) and INVULNERABLE_EXTRACTORS then
      INVULNERABLE_EXTRACTORS = false
      gadgetHandler:RemoveCallIn("AllowWeaponTarget")
      gadgetHandler:RemoveCallIn("UnitPreDamaged")
    end
  end
  if (reinit) then
    local units = spGetAllUnits()
    for i=1,#units do
      UnitFin(units[i], spGetUnitDefID(units[i]), spGetUnitTeam(units[i]))
    end
    local features = spGetAllFeatures()
    for i=1,#features do
      local featureDefID = spGetFeatureDefID(features[i])
      if (FeatureDefs[featureDefID].name == "ore") then
	Ore[features[i]] = true
      end
    end
  end
end
    
function gadget:Initialize()
  if not(tonumber(modOptions.oremex) == 1) then
    gadgetHandler:RemoveGadget()
  end
  if not(INVULNERABLE_EXTRACTORS) then
    gadgetHandler:RemoveCallIn("AllowWeaponTarget")
    gadgetHandler:RemoveCallIn("UnitPreDamaged")
  end
  if not(INVULNERABLE_EXTRACTORS) or not(OBEY_OD) then
    TransferLoop = function() end
  end
  if (ORE_DMG==0) then
    InflictOreDamage = function() end
  end
  if (spGetGameFrame() > 1) then
    ReInit(true)
  end
end

function gadget:GameStart()
  ReInit(false)
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  UnitFin(unitID, unitDefID, unitTeam)
end

end