local version = "0.9"

function gadget:GetInfo()
  return {
    name      = "Ore mexes!",
    desc      = "Prespawn mex spots and make them spit metal. Version "..version,
    author    = "Tom Fyuri",
    date      = "Mar 2014",
    license   = "GPL v2 or later",
    layer     = -5,
    enabled   = true	-- now it comes with design!
  }
end

--SYNCED-------------------------------------------------------------------

-- TODO annoying units try to attack invulnerable mexes if you enable that modoption
-- something needs to be done...
-- Also ore spawn algo should be improved, although it's fair and if it can't spawn feature for any reason
-- it will store how much it needs to spawn and simply try to spawn more fat ore next second

local modOptions = Spring.GetModOptions()
if (gadgetHandler:IsSyncedCode()) then
  
local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0
-- currently oremex obeys zero-k OD system, personally I don't think it shouldn't, though implementing option for not obeying it isn't hard to do.
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spCallCOBScript  		= Spring.CallCOBScript
local spGetGroundHeight		= Spring.GetGroundHeight
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetTeamInfo 	    	= Spring.GetTeamInfo
local spCreateFeature		= Spring.CreateFeature
local spSetFeatureReclaim	= Spring.SetFeatureReclaim
local spSetFeatureDirection	= Spring.SetFeatureDirection
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
local OreMexByID = {} -- by UnitID
local OreMex = {} -- for loop
local Ore = {} -- by FeatureID, should feature die (reclaimed) it will tell oremex to spawn more ore if it's fine.
-- NOTE ore extractors will keep ore inside if they already spawned a lot, they will drop fat should more ore get reclaimed or on death though.
-- this is intended so ore features do not flood map and 'cause perfomence drop.

local random = math.random
local cos   = math.cos
local sin   = math.sin
local pi    = math.pi
local floor = math.floor

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

local INVULNERABLE_EXTRACTORS = tonumber(modOptions.oremex_invul or 0) -- invulnerability of extractors. they can still switch team side should OD get connected
local LIMIT_PRESPAWNED_METAL = floor(tonumber(modOptions.oremex_metal) or 120)
local PRESPAWN_EXTRACTORS = (tonumber(modOptions.oremex_prespawn)==1)

-- godmode stuff
function gadget:UnitPreDamaged(unitID)
  if (OreMexByID[unitID]) then
    return 0
  end
end

local function disSQ(x1,y1,x2,y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

-- if mex OD is <= 1 and it's godmode on, transfer mex to gaia team
-- if mex is inside energyDefs transfer mex to ally team having most gridefficiency (if im correct team having most gridefficiency should produce most E for M?)
local function GaiaLoopTransfer()
  for i=1,#OreMex do
    if (OreMex[i]~=nil) then
      local unitID = OreMex[i].unitID
--       Spring.Echo(spGetUnitTeam(unitID).." "..GaiaTeamID)
--       Spring.Echo("spit "..OreMex[i].income)
      MineMoreOre(unitID, OreMex[i].income, false)
      if (spGetUnitTeam(unitID)==GaiaTeamID) then
	local x = OreMex[i].x
	local z = OreMex[i].z
	if (x) then
-- 	  Spring.Echo(PylonRange)
	  local units = spGetUnitsInCylinder(x, z, PylonRange+10)
	  local best_eff = 0
	  local best_team
	  for i=1,#units do
	    local targetID = units[i]
	    local targetDefID = spGetUnitDefID(targetID)
	    local targetTeam = spGetUnitTeam(targetID)
	    if (energyDefs[targetDefID]) and (targetTeam~=GaiaTeamID) then
-- 	      Spring.Echo(UnitDefs[targetDefID].humanName)
	      local maxdist = energyDefs[targetDefID]
	      maxdist=maxdist*maxdist
	      local x2,_,z2 = spGetUnitPosition(targetID)
	      if (disSQ(x,z,x2,z2) <= maxdist) then
		local eff = spGetUnitRulesParam(targetID,"gridefficiency")
-- 		Spring.Echo(tostring(eff))
		if (eff) and (eff >= 0.1) and (best_eff < eff) then
		  best_eff = eff
		  best_team = targetTeam
		end
	      end
	    end
	  end
	  if (best_team ~= nil) then
	    spTransferUnit(unitID, best_team, false)
	  end
	end
      end
    end
  end
end

-- godmode stuff end

function gadget:GameFrame(f)
  if ((f%32)==1) then
    GaiaLoopTransfer()
  end
end

function gadget:AllowWeaponTarget(unitID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
  if (unitID) and (targetID) and (mexDefs[spGetUnitDefID(targetID)]) then
    return false
  end
end

local function UnitFin(unitID, unitDefID, unitTeam)
  if (unitTeam ~= GaiaTeamID) then
    if (energyDefs[unitDefID]) then
      local x,_,z = spGetUnitPosition(unitID)
      if (x) then
	local units = spGetUnitsInCylinder(x, z, energyDefs[unitDefID]+10)
	for i=1,#units do
	  local targetID = units[i]
	  if (OreMexByID[targetID]) and (spGetUnitTeam(targetID)==GaiaTeamID) then
	    spTransferUnit(targetID, unitTeam, false)
	  end
	end
      end
    end
  end
  if (mexDefs[unitDefID]) then
    local x,y,z = spGetUnitPosition(unitID)
    if (x) then
      id = 1
      while (OreMex[id]~=nil) do
	id=id+1
      end
--       Spring.Echo(unitID.." is now mex number "..id)
      local income = 0
      if (GG.metalSpots) then --byPos didnt work :(
	for i=1,#GG.metalSpots do
	  if (GG.metalSpots[i].x == x) and (GG.metalSpots[i].z == z) then
	    income = GG.metalSpots[i].metal
	    break
	  end
	end
      end
--       Spring.Echo(income)
      OreMex[id] = {
	unitID = unitID,
	ore = 0, -- metal.
	income = income, -- should mex have bigger income it will drop ore less frequent but more fat ore.
	ore_count = 0, -- number of features.
	x = x,
	z = z,
      }
      OreMexByID[unitID] = id
    end
  end
end

local function get_grid_coord(size)
--   Spring.Echo("full_size "..full_size)
  if (size == 1) then return 0,0
  else
    if (random(0,1)==1) then
      local mid = (size+1)*0.5
      local i = random(1,size)-mid
      local j = size
      if (random(0,1)==1) then j = 1 end
      j=j-mid
--       Spring.Echo(i.." "..j)
      return i*40, j*40
    else
      local mid = (size+1)*0.5
      local i = size
      if (random(0,1)==1) then i = 1 end
      i=i-mid
      local j = random(1,size)-mid
--       Spring.Echo(i.." "..j)
      return i*40, j*40
    end
  end
end

local function grid_size(ore_count)
  if (ore_count == 0) then return 1 end
  local size = 1
  local count = ore_count
  while (count >= (size*size-2)) do
    size = size+2
  end
--   Spring.Echo(size.."x"..size.." can hold "..count.." ore")
  return size
  -- 3x3 grid can hold 9 ore
  -- 5x5 grid can hold 25 ore
  -- etc
end

local function CanSpawnOreAt(x,z)
  local features = spGetFeaturesInRectangle(x-30,z-30,x+30,z+30)
  for i=1,#features do
    local featureID = features[i]
    local featureDefID = spGetFeatureDefID(featureID)
--     Spring.Echo(FeatureDefs[featureDefID].name)
    if (FeatureDefs[featureDefID].name=="ore") then
--       Spring.Echo("cant spawn at "..x.." "..z)
      return false
    end
  end
  return true
end

function MineMoreOre(unitID, howMuch, forcefully)
  -- ore extractor make 3x3 grid always, albeit if it's forcefully is true, it can make bigger grids
  local MexID = OreMexByID[unitID]
  if not(OreMex[MexID]) then return end -- probably just built, otherwise should never happen...
  OreMex[MexID].ore = OreMex[MexID].ore + howMuch
  local ore = OreMex[MexID].ore
  if not(forcefully) then
    OreMex[MexID].income = howMuch
  end
  -- try spawning 3 ore rocks for every mex until we fill entire field on low income, other go fat
  -- if any or all spawns fail, ore extractor simply "stores" ore to spawn next time
  local sp_count = 3
  if (ore < 6) then
    sp_count = 2
    if (ore < 3) then
      sp_count = 1
    end
  end
--   Spring.Echo("spcount: "..sp_count)
--   Spring.Echo("hold: "..ore)
  local ore_count = OreMex[MexID].ore_count
  local x,_,z = spGetUnitPosition(unitID)
--   Spring.Echo("unreclaimed ore: "..ore_count)
  if ((ore >= 1) and ((ore_count+sp_count)<81)) or (forcefully) then
    -- time to spawn!
    try=0
    while (try < sp_count) do
      local a,b = get_grid_coord(grid_size(ore_count))
      a = x+a
      b = z+b
      if (CanSpawnOreAt(a,b)) then
	local spawn_amount = ore*0.5
-- 	Spring.Echo("want to spawn: "..spawn_amount)
	if (spawn_amount>10) then
	  if (forcefully) then
	    spawn_amount = howMuch*0.5 -- 0.33
	  else
	    spawn_amount = 10
	  end
	elseif (spawn_amount<1) then
	  spawn_amount = 1
	end
	if (spawn_amount >= (ore-spawn_amount)) then
-- 	  Spring.Echo(x.." "..z)
-- 	  Spring.Echo("grid size: "..grid_size(ore_count))
	  local oreID = spCreateFeature("ore", a, spGetGroundHeight(a, b), b)
	  if (oreID) then
	    Ore[oreID] = MexID
	    spSetFeatureReclaim(oreID, spawn_amount)
	    local rd = random(360) * pi / 180
	    spSetFeatureDirection(oreID,sin(rd),0,cos(rd))
	    ore = ore - spawn_amount
	    ore_count=ore_count+1
	  end
	end
      end
      try=try+1
    end
  end
  if (forcefully) and (ore>=1) then -- drop all thats left on mex
    local oreID = spCreateFeature("ore", x, spGetGroundHeight(x, z), z)
    if (oreID) then
      Ore[oreID] = MexID
      spSetFeatureReclaim(oreID, ore)
      local rd = random(360) * pi / 180
      spSetFeatureDirection(oreID,sin(rd),0,cos(rd))
      ore_count=ore_count+1
      ore = 0
    end
  end
  OreMex[MexID].ore_count = ore_count
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
    OreMex[OreMexByID[unitID]]=nil
    OreMexByID[unitID]=nil
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
	    income = GG.metalSpots[i].metal, -- should mex have bigger income it will drop ore less frequent but more fat ore.
	    ore_count = 0, -- number of features.
	    x = GG.metalSpots[i].x,
	    z = GG.metalSpots[i].z,
	  }
	  OreMexByID[unitID] = id
-- 	  Spring.Echo(GG.metalSpots.metal)
	  spSetUnitRulesParam(unitID, "mexIncome", GG.metalSpots[i].metal)
	  spCallCOBScript(unitID, "SetSpeed", 0, GG.metalSpots[i].metal * 500) 
	  local prespawn = 0
	  while (prespawn < LIMIT_PRESPAWNED_METAL) do
	    MineMoreOre(unitID, 30, true)
	    prespawn=prespawn+30
	  end
	  if (LIMIT_PRESPAWNED_METAL-prespawn)>=5 then -- i dont want to spawn ~5 m "leftovers", chunks are ok
	    MineMoreOre(unitID, LIMIT_PRESPAWNED_METAL-prespawn, true)
	  end
	end
      end
    end
  end
end
    
function gadget:Initialize()
  if not(tonumber(modOptions.oremex) == 1) then
    gadgetHandler:RemoveGadget()
  end
  if (INVULNERABLE_EXTRACTORS == 0) then
    gadgetHandler:RemoveCallIn("UnitPreDamaged")
--     gadgetHandler:RemoveCallIn("GameFrame")
  end
  -- partial luarules reload support, you have to reclaim all ore nearby mex for it to begin working again
  local units = spGetAllUnits()
  for i=1,#units do
    UnitFin(units[i], spGetUnitDefID(units[i]), spGetUnitTeam(units[i]))
  end
  if (PRESPAWN_EXTRACTORS) then
    PreSpawn()
  end
end

function gadget:GameStart()
  if (PRESPAWN_EXTRACTORS) then
    PreSpawn()
  end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  UnitFin(unitID, unitDefID, unitTeam)
end

function gadget:FeatureDestroyed(featureID, allyTeam)
  if (Ore[featureID]) then
    local ownerID = Ore[featureID]
    if (OreMex[ownerID]) then
      OreMex[ownerID].ore_count=OreMex[ownerID].ore_count-1
    end
  end
end

end