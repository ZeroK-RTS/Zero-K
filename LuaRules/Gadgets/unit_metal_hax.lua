-- $Id: unit_metal_hax.lua 3171 2008-11-06 09:06:29Z det $
----------------------------------------------------------------
--Metal Hax
----------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Mex Hax",
    desc      = "Takes over mexes from the engine.",
    author    = "Evil4Zerggin",
    date      = "24 May 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

if (gadgetHandler:IsSyncedCode()) then

----------------------------------------------------------------
--parameters
----------------------------------------------------------------
local maxMetal = 0.001 --scale metal by this value; acts like extractsMetal
local desiredEnergy = 0.8 -- on which percentage to hover
local storedEnergyWeight = 0.2 -- how much to weight the energy to spend on how much energy is stored
local deltaEWeight = 0.2 --how much to weight the energy to spend on how quickly energy is changing

----------------------------------------------------------------
--speed-ups
----------------------------------------------------------------
local mapSizeX = Game.mapSizeX
local mapSizeZ = Game.mapSizeZ
local extractorRadius = Game.extractorRadius

local GetGroundInfo = Spring.GetGroundInfo
local GetUnitPosition = Spring.GetUnitPosition
local SetUnitResourcing = Spring.SetUnitResourcing
local SetUnitMetalExtraction = Spring.SetUnitMetalExtraction
local GetTeamResources = Spring.GetTeamResources
local GetUnitTeam = Spring.GetUnitTeam

----------------------------------------------------------------
--constants
----------------------------------------------------------------

local metalMapScale = 16
local metalMapScaleSq = 256

local metalMapMaxX = math.floor(mapSizeX / metalMapScale) - 1
local metalMapMaxZ = math.floor(mapSizeZ / metalMapScale) - 1
local extractSearchMax = math.floor(extractorRadius / metalMapScale)

----------------------------------------------------------------
--locals
----------------------------------------------------------------

--2-D array that stores the metal map
local metalMap = {}

--3-D array that stores what mexes are lined up to control each particular square on the metal map
local controlMap = {}

--circle indicating whether a particular metal map square is within the extractor radius of the origin
local circleMask = {}

--table of mexes; entries are {amount of metal that the mex is over, shares of energy the mex takes}
local mexes = {}

--indexed by teams, entries are {table of mexes, autoManage, doUpdate, energy, energy shares, }
local teamInfos = {}

----------------------------------------------------------------
--initialization
----------------------------------------------------------------

--setup metal map, control map
local function SetupMaps()
  for i = 0, metalMapMaxX do
    metalMap[i] = {}
    controlMap[i] = {}
    for j = 0, metalMapMaxZ do
      local metal
      _, metal, _, _, _, _, _, _ = GetGroundInfo(metalMapScale * i + 8, metalMapScale * j + 8)
      metalMap[i][j] = metal * maxMetal
      controlMap[i][j] = {}
    end
  end
end

--setup circle mask
local function SetupCircleMask()
  do
    local radiusSq = extractorRadius * extractorRadius
    for i = 0, extractSearchMax do
      circleMask[i] = {}
      circleMask[-i] = {}
      for j = 0, extractSearchMax do
        if ((i*i + j*j) * metalMapScaleSq < radiusSq) then
          circleMask[i][j] = true
          circleMask[-i][j] = true
          circleMask[i][-j] = true
          circleMask[-i][-j] = true
        end
      end
    end
  end
end

local function SetupTeamList()
  local teamList = Spring.GetTeamList()
  for i=1,#teamList do
    local teamID = teamList[i]
    teamInfos[teamID] = {{}, true, false, 0, 0,}
  end
end

----------------------------------------------------------------
--functions
----------------------------------------------------------------

local function GetMexMod(energy, baseMetal)
  if (baseMetal <= 0) then return 0 end
  
  return 1 + math.sqrt(0.2 * energy / baseMetal)
end

local function GetMexShares(baseMetal)
  return baseMetal
end

local function GetOverdriveEnergy(teamID)
  local teamInfo = teamInfos[teamID]
  if (teamInfo) then
    return teamInfo[4]
  else
    return nil
  end
end

local function GetOverdriveMetal(teamID)
  local teamInfo = teamInfos[teamID]
  if (teamInfo) then
    return math.sqrt(0.2 * teamInfo[4] * teamInfo[5])
  else
    return nil
  end
end

local function GetDifferentialEnergyPerMetal(teamID)
  local teamInfo = teamInfos[teamID]
  if (teamInfo and teamInfo[5] > 0) then
    return math.sqrt(20 * teamInfo[4] / teamInfo[5])
  else
    return nil
  end
end

local function GetTotalGlobalMetal()
  local result = 0
  for i = 0, metalMapMaxX do
    for j = 0, metalMapMaxZ do
      result = result + metalMap[i][j]
    end
  end
  return result
end

local function GetMetalMapCoords(posX, posZ)
  return math.floor(posX / metalMapScale), math.floor(posZ / metalMapScale)
end

local function AddMex(unitID, unitDefID, unitTeam)
  local unitDef = UnitDefs[unitDefID]
  if ((unitDef.speed or 0) ~= 0) then return end

  local metal = 0
  local posX, _, posZ = GetUnitPosition(unitID)
  local mPosX, mPosZ = GetMetalMapCoords(posX, posZ)
  
  --establish how far we are willing to search
  local backX = math.min(extractSearchMax, mPosX)
  local frontX = math.min(extractSearchMax, metalMapMaxX - mPosX)
  local backZ = math.min(extractSearchMax, mPosZ)
  local frontZ = math.min(extractSearchMax, metalMapMaxZ - mPosZ)
  
  --iterate over the search area
  for i = -backX, frontX do
    for j = -backZ, frontZ do
      --check our pre-calculated mask to see if each spot is within the extractor radius
      if (circleMask[i][j]) then
        --position on metal map
        local iPos = mPosX + i
        local jPos = mPosZ + j
        
        --if spot not already claimed, give the metal to the mex
        if (not controlMap[iPos][jPos][1]) then
          metal = metal + metalMap[iPos][jPos]
        end
        
        --add the mex to the queue of controllers
        table.insert(controlMap[iPos][jPos], unitID)
      end
    end
  end
  mexes[unitID] = {metal, GetMexShares(metal),}
  --doUpdate
  teamInfos[unitTeam][1][unitID] = true
  teamInfos[unitTeam][3] = true
end

local function RemoveMex(unitID, unitTeam)
  if (not mexes[unitID]) then return end
  
  local metal = 0
  local posX, _, posZ = GetUnitPosition(unitID)
  local mPosX, mPosZ = GetMetalMapCoords(posX, posZ)
  
  --establish how far we are willing to search
  local backX = math.min(extractSearchMax, mPosX)
  local frontX = math.min(extractSearchMax, metalMapMaxX - mPosX)
  local backZ = math.min(extractSearchMax, mPosZ)
  local frontZ = math.min(extractSearchMax, metalMapMaxZ - mPosZ)
  
  --iterate over the search area
  for i = -backX, frontX do
    for j = -backZ, frontZ do
      --position on metal map
      local iPos = mPosX + i
      local jPos = mPosZ + j
      
      --if we control this spot, give it to the next in line
      if (controlMap[iPos][jPos][1] == unitID) then
        --remove any mexes in line which no longer exist
        local nextID
        
        repeat
          table.remove(controlMap[iPos][jPos], 1)
          nextID = controlMap[iPos][jPos][1]
        until (not nextID or mexes[nextID])
        
        --add the metal to the new owner
        if (nextID) then
          mexes[nextID][1] = mexes[nextID][1] + metalMap[iPos][jPos]
          mexes[nextID][2] = GetMexShares(mexes[nextID][1])
          teamInfos[GetUnitTeam(nextID)][3] = true
        end
      end
    end
  end
  --remove mex
  teamInfos[unitTeam][1][unitID] = nil
  mexes[unitID] = nil
  --doUpdate
  teamInfos[unitTeam][3] = true
end

----------------------------------------------------------------
--callins
----------------------------------------------------------------

function gadget:Initialize()
  SetupMaps()
  SetupCircleMask()
  Spring.SendMessage("Total Global Metal:" .. GetTotalGlobalMetal())
  SetupTeamList()
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  AddMex(unitID, unitDefID, unitTeam)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  RemoveMex(unitID, unitTeam)
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
  RemoveMex(unitID, oldTeamID)
  AddMex(unitID, unitDefID, teamID)
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
  RemoveMex(unitID, oldTeamID)
  AddMex(unitID, unitDefID, teamID)
end

function gadget:GameFrame(n)
  if (((n+30) % 32) > 0.1) then return end
  
  for teamID, teamInfo in pairs(teamInfos) do
  
    --cleanup
    if (teamInfo[4] < 0) then
      teamInfo[4] = 0
    end
    if (teamInfo[5] < 0) then
      teamInfo[5] = 0
    end
    
    if (teamInfo[2] or teamInfo[3]) then
      --automanage
      if (teamInfo[2]) then
        --determine how much to spend
        if (teamInfo[5] > 0) then
          local eCur, eMax, ePull, eInc, eExp, _, eSent, eRec = GetTeamResources(teamID, "energy")
          if (eCur == nil) then return end
          local deltaE = eInc - eExp + eRec - eSent
          local eChange = storedEnergyWeight * (eCur - eMax * desiredEnergy) + deltaEWeight * deltaE
          teamInfo[4] = teamInfo[4] + eChange
          
          if (teamInfo[4] < 0) then
            teamInfo[4] = 0
          end
        else
          --if no mexes, reset energy budget to zero
          teamInfo[4] = 0
        end
      end
      
      --update
      if (teamInfo[3]) then
        --recalculate shares
        local shares = 0
        for unitID, _ in pairs(teamInfo[1]) do
          shares = shares + mexes[unitID][2]
        end
        teamInfo[5] = shares
        
        --done
        teamInfo[3] = false
      end
      
      Spring.SendMessage("Player " .. teamID .. " Energy Budget: " .. teamInfo[4] .. " Shares: " .. teamInfo[5])
      
      --pump the energy
      for unitID, _ in pairs(teamInfo[1]) do
        local energyThisMex = teamInfo[4] * mexes[unitID][2] / teamInfo[5]
        local metalThisMex = GetMexMod(energyThisMex, mexes[unitID][1]) * mexes[unitID][1]
        Spring.SetUnitResourcing(unitID, "cue", energyThisMex * 2)
        Spring.SetUnitResourcing(unitID, "cmm", metalThisMex * 2)
      end
    end
  end
end

----------------------------------------------------------------
--UNSYNCED
----------------------------------------------------------------
else

end
