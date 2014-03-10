local version = "1.0.1"

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

--TODO some people want actual tiberium (hurt units modoption) ;) ;)
--TODO if modoptions return nil, make all options enabled by default..

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
local spSetUnitNoSelect		= Spring.SetUnitNoSelect
local spSetUnitNeutral		= Spring.SetUnitNeutral
local spValidUnitID	    	= Spring.ValidUnitID
local OreMexByID = {} -- by UnitID
local OreMex = {} -- for loop
local random = math.random
local cos   = math.cos
local sin   = math.sin
local pi    = math.pi
local floor = math.floor

local mapWidth
local mapHeight
local teamIDs

local UnderAttack = {} -- holds frameID per mex so it goes neutral, if someone attacks it, for 5 seconds, it will not return to owner if no grid connected.

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
local LIMIT_PRESPAWNED_METAL = floor(tonumber(modOptions.oremex_metal) or 300)
local PRESPAWN_EXTRACTORS = (tonumber(modOptions.oremex_prespawn) == 1)
local OBEY_OD = (tonumber(modOptions.oremex_overdrive) == 1)
local MAX_STEPS = 15 -- vine length
local MIN_PRODUCE = 5 -- no less than 5 ore per 40x40 square otherwise spam lol...

local function TransferMexTo(unitID, mexID, unitTeam)
  if (spValidUnitID(unitID) and (mexID) then
    spSetUnitRulesParam(unitID, "mexIncome", OreMex[mexID].income)
    spCallCOBScript(unitID, "SetSpeed", 0, OreMex[mexID].income * 500) 
    -- ^ hacks?
    UnderAttack[unitID] = spGetGameFrame()+160
    spTransferUnit(unitID, unitTeam, false)
    spSetUnitNeutral(unitID, true)
  end
end

-- godmode stuff
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam)
  if (OreMexByID[unitID]) then
    if (unitTeam ~= GaiaTeamID) then
      TransferMexTo(unitID, OreMexByID[unitID], GaiaTeamID)
    end
    return 0
  end
end

local function disSQ(x1,y1,x2,y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

-- if mex OD is <= 1 and it's godmode on, transfer mex to gaia team
-- if mex is inside energyDefs transfer mex to ally team having most gridefficiency (if im correct team having most gridefficiency should produce most E for M?)
function gadget:GameFrame(f)
  if ((f%32)==1) then
    for i=1,#OreMex do
      if (OreMex[i]~=nil) then
	local unitID = OreMex[i].unitID
	local x = OreMex[i].x
	local z = OreMex[i].z
	local unitTeam = spGetUnitTeam(unitID)
	local allyTeam = spGetUnitAllyTeam(unitID)
	if (x) and ((unitTeam==GaiaTeamID) or (INVULNERABLE_EXTRACTORS)) and (UnderAttack[unitID] <= spGetGameFrame()) then
	  local units = spGetUnitsInCylinder(x, z, PylonRange+21)
	  local best_eff = 0
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
end
-- godmode stuff end

function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
  if (attackerID) and (targetID) and (OreMexByID[targetID]) then
    return false, 1
  end
  return true, 1
end

local function UnitFin(unitID, unitDefID, unitTeam)
  if (unitTeam ~= GaiaTeamID) then
    if (energyDefs[unitDefID]) then
      local x,_,z = spGetUnitPosition(unitID)
      if (x) then
	local units = spGetUnitsInCylinder(x, z, energyDefs[unitDefID]+10)
	for i=1,#units do
	  local targetID = units[i]
	  if (OreMexByID[targetID]) and (spGetUnitTeam(targetID)==GaiaTeamID) and (UnderAttack[targetID] <= spGetGameFrame()) then
	    TransferMexTo(targetID, i, unitTeam)
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
      OreMex[id] = {
	unitID = unitID,
	ore = 0, -- metal.
	income = spGetUnitRulesParam(unitID,"mexIncome"),
	x = x,
	z = z,
      }
      OreMexByID[unitID] = id
      UnderAttack[unitID] = -100
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

local function spDrawVine(x,z)
  local steps=0
  while (steps < MAX_STEPS) do
    if (CanSpawnOreAt(x,z)) then return x,z
    else
      local way = random(0,3)
      if (way==0) and (x-40>0) then
	x=x-40
      elseif (way==2) and (x+40<mapWidth) then
	x=x+40
      elseif (way==1) and (z-40>0) then
	z=z-40
      elseif (way==3) and (z+40<mapHeight) then
	z=z+40
      end -- otherwise stay at place
    end
    steps = steps+1
  end
  return nil
end

function MineMoreOre(unitID, howMuch, forcefully)
  local MexID = OreMexByID[unitID]
  if not(OreMex[MexID]) then return end -- in theory never happens...
  OreMex[MexID].ore = OreMex[MexID].ore + howMuch
  local ore = OreMex[MexID].ore
  if not(forcefully) then
    OreMex[MexID].income = howMuch
  end
  local sp_count = 3
  if (ore < 6) then
    sp_count = 2
    if (ore < 3) then
      sp_count = 1
    end
  end
  local x,_,z = spGetUnitPosition(unitID)
  local features = spGetFeaturesInRectangle(x-240,z-240,x+240,z+240)
  local teamID = spGetUnitTeam(unitID)
  if (#teamIDs>1) and (teamID == GaiaTeamID) then
    teamID = random(0,#teamIDs)
    while (teamID == GaiaTeamID) do
      teamID = random(0,#teamIDs)
    end
  end
  if (#features > 144) and not(forcefully) then return end -- too much reclaim, please reclaim
  if (ore>=1) then
    try=0
    while (try < sp_count) do
      local a,b = spDrawVine(x,z) -- simply go left,right,top,bottom randomly until vine is build, max amount of steps is MAX_STEPS, if fail -> dont spawn
      if (a~=nil) then
	local spawn_amount = ore*0.5
	if (spawn_amount>10) then
	  if (forcefully) then
	    spawn_amount = howMuch*0.5 -- 0.33
	  elseif (10 < ore*0.01) then
	    spawn_amount = ore*0.01
	  else
	    spawn_amount = 10
	  end
	elseif (spawn_amount<MIN_PRODUCE) then
	  spawn_amount = MIN_PRODUCE
	end
	if (ore >= spawn_amount) then
	  local oreID = spCreateFeature("ore", a, spGetGroundHeight(a, b), b, "n", teamID)
	  if (oreID) then
	    spSetFeatureReclaim(oreID, spawn_amount)
	    local rd = random(360) * pi / 180
	    spSetFeatureDirection(oreID,sin(rd),0,cos(rd))
	    ore = ore - spawn_amount
	  end
	end
      end
      try=try+1
    end
    if (forcefully) then -- drop all thats left on mex
    local oreID = spCreateFeature("ore", x, spGetGroundHeight(x, z), z, "n", teamID)
      if (oreID) then
	spSetFeatureReclaim(oreID, ore)
	local rd = random(360) * pi / 180
	spSetFeatureDirection(oreID,sin(rd),0,cos(rd))
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
-- 	    spSetUnitNoSelect(unitID, true)
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
  end
end
    
function gadget:Initialize()
  if not(tonumber(modOptions.oremex) == 1) then
    gadgetHandler:RemoveGadget()
  end
  Spring.Echo(tostring(INVULNERABLE_EXTRACTORS))
  Spring.Echo(tostring(OBEY_OD))
  if not(INVULNERABLE_EXTRACTORS) then
    gadgetHandler:RemoveCallIn("AllowWeaponTarget")
    gadgetHandler:RemoveCallIn("UnitPreDamaged")
  end
  mapWidth = Game.mapSizeX
  mapHeight = Game.mapSizeZ
  teamIDs = spGetTeamList()
  if not(INVULNERABLE_EXTRACTORS) or not(OBEY_OD) then
    gadgetHandler:RemoveCallIn("GameFrame")
  end
  if (spGetGameFrame() > 1) then
    local units = spGetAllUnits()
    for i=1,#units do
      UnitFin(units[i], spGetUnitDefID(units[i]), spGetUnitTeam(units[i]))
    end
    if (PRESPAWN_EXTRACTORS) then
      PreSpawn()
    end
  end
end

function gadget:GameStart()
  mapWidth = Game.mapSizeX
  mapHeight = Game.mapSizeZ
  teamIDs = spGetTeamList()
  if (PRESPAWN_EXTRACTORS) then
    PreSpawn()
  end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  UnitFin(unitID, unitDefID, unitTeam)
end

end