-- $Id: unit_chicken_factory.lua 4597 2009-05-09 20:15:34Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Chicken Factories",
    desc      = "Factory build power depends on metal extraction.",
    author    = "quantum",
    date      = "July 19, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-- BEGIN SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gridSize        = 16
local metalExtraction = 0.004
local lines           = false -- set to true for debugging
local radius          = Game.extractorRadius

local metalMult       = metalExtraction * 8^2 * gridSize^-2 
local usedMetal       = {}

local cfBaseBuildPower = {}
local cfBuildPower     = {}

local sendMetalEvent = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local mexAndChickenFacDefs = {}

for i=1, #UnitDefs do
  local ud = UnitDefs[i]
  if (ud.customParams.chickenfac) then
    mexAndChickenFacDefs[i] = "chickenfac"
  elseif (ud.isMetalExtractor) then
    mexAndChickenFacDefs[i] = "mex"
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Automatically generated local definitions

local floor               = math.floor
local spGetGroundInfo     = Spring.GetGroundInfo
local spGetUnitPosition   = Spring.GetUnitPosition
local spSetUnitBuildSpeed = Spring.SetUnitBuildSpeed
local spGetUnitBuildSpeed = Spring.GetUnitBuildSpeed
local spGetUnitDefID      = Spring.GetUnitDefID
local spUseUnitResource	  = Spring.UseUnitResource
local spGetUnitTeam       = Spring.GetUnitTeam
local spGetUnitIsBuilding = Spring.GetUnitIsBuilding
local spGetFactoryCommands= Spring.GetFactoryCommands

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local circleCoords = {}
for x = -radius, radius, gridSize do
  for z = -radius, radius, gridSize do
    if ((x*x + z*z) <= radius*radius) then
      circleCoords[#circleCoords+1] = {x, z}
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MetalEvent()
  if (lines) then
    _G.usedMetal = usedMetal
    SendToUnsynced"MetalEvent"
    _G.usedMetal = nil
  end
end


local function TakeMetal(mexX, mexZ, unitID)
  mexX = floor(mexX/gridSize+0.5)*gridSize
  mexZ = floor(mexZ/gridSize+0.5)*gridSize
  local totalMetal = 0
  for i=1, #circleCoords do
    local x = circleCoords[i][1] + mexX
    local z = circleCoords[i][2] + mexZ
    usedMetal[x] = usedMetal[x] or {}
    if (not usedMetal[x][z]) then
      local _, localMetal = spGetGroundInfo(x, z)
      totalMetal = totalMetal + localMetal
      usedMetal[x][z] = {unitID, localMetal}
    end
  end
  sendMetalEvent = true
  return totalMetal * metalMult
end


local function FreeMetal(mexX, mexZ)
  mexX = floor(mexX/gridSize+0.5)*gridSize
  mexZ = floor(mexZ/gridSize+0.5)*gridSize
  for i=1, #circleCoords do
    local x = circleCoords[i][1] + mexX
    local z = circleCoords[i][2] + mexZ
    if (usedMetal[x]) then
      usedMetal[x][z] = nil
    end
    if (usedMetal[x] and not next(usedMetal[x])) then
      usedMetal[x] = nil
    end
  end
  sendMetalEvent = true
end


local function setChickenFac(unitID, teamID, buildSpeed)
	if buildSpeed == -1 then
		if cfBaseBuildPower[teamID] then
			cfBaseBuildPower[teamID][unitID] 	= nil
			cfBuildPower[teamID][unitID] 		= nil
		end
	else
		if not cfBaseBuildPower[teamID] then
			cfBaseBuildPower[teamID] = {}
			cfBuildPower[teamID] = {}
		end
		cfBaseBuildPower[teamID][unitID] 	= buildSpeed
		cfBuildPower[teamID][unitID] 		= buildSpeed	
	end
end


local function RefreshMetal(x, z, ignore)
  local units
  if (x) then
    units = Spring.GetUnitsInCylinder(x, z, radius*2)
  else
    units = Spring.GetAllUnits()
  end

  for i=1, #units do 
    local x, _, z = Spring.GetUnitPosition(units[i])
    FreeMetal(x, z)
  end

  for i=1, #units do 
    local unitDefID = spGetUnitDefID(units[i])
    if (mexAndChickenFacDefs[unitDefID] == "mex") and (units[i] ~= ignore) then
      local x, _, z = spGetUnitPosition(units[i])
      TakeMetal(x, z, units[i])
    end
  end

  for i=1, #units do
    local unitDefID = spGetUnitDefID(units[i])
    if (mexAndChickenFacDefs[unitDefID] == "chickenfac") and (units[i] ~= ignore) then
      local x, _, z = spGetUnitPosition(units[i])
      local metal =  TakeMetal(x, z, units[i])
      spSetUnitBuildSpeed(units[i], metal)
      setChickenFac(units[i], spGetUnitTeam(units[i]), metal)
    end
  end
end


local function overdriveChickenFacs(teamID, chickenFacs)
	local again = true
	for unitID, buildPower in pairs(chickenFacs) do
		cfBuildPower[teamID][unitID] = cfBaseBuildPower[teamID][unitID]
	end

	local countout = 9000 -- just in case
	while again and countout > 0 do
		countout = countout - 1
		again = false
		for unitID, buildPower in pairs(chickenFacs) do
			local fc = spGetFactoryCommands(unitID)
			local waiting = fc and fc[1] and CMD[fc[1].id] == 'WAIT' 
			if spGetUnitIsBuilding(unitID) and not waiting then
				local newState = spUseUnitResource(unitID, 'e', 1)
				if (newState) then
					again = true
					cfBuildPower[teamID][unitID] = cfBuildPower[teamID][unitID] + 0.1
				end
			end
		end
	end
	for unitID, buildPower in pairs(chickenFacs) do
		spSetUnitBuildSpeed(unitID, cfBuildPower[teamID][unitID])
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local anyChickenFacs = false

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  local mexOrChickenFac = mexAndChickenFacDefs[unitDefID]
  if (mexOrChickenFac) then
    if (mexOrChickenFac == "chickenfac") then
      local x, _, z = spGetUnitPosition(unitID)
      local metal = TakeMetal(x, z, unitID)
      spSetUnitBuildSpeed(unitID, metal)
      setChickenFac(unitID, unitTeam, metal)

      if (not anyChickenFacs) then
        RefreshMetal()
        anyChickenFacs = true
      end
    end

    if (anyChickenFacs) and (mexOrChickenFac == "mex") then
      local x, _, z = spGetUnitPosition(unitID)
      -- quick hack: normal mexes have priority over mexfacs
      -- refreshes can break first come, first served
      -- not needed if all mexes are managed by lua
      RefreshMetal(x, z)
    end
  end
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  local mexOrChickenFac = mexAndChickenFacDefs[unitDefID]
  if (mexOrChickenFac) then
    local x, _, z = spGetUnitPosition(unitID)
    RefreshMetal(x, z, unitID)
    setChickenFac(unitID, unitTeam, -1)
  end
end


function gadget:GameFrame(frameNum)
	if sendMetalEvent then
		sendMetalEvent = false
		MetalEvent()
	end

	if frameNum %32 ~= 0 then return end

	for teamID, chickenFacs in pairs(cfBaseBuildPower) do
		overdriveChickenFacs(teamID, chickenFacs)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- END SYNCED
else
-- BEGIN UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GL_LINES          = GL.LINES
local GL_POINTS         = GL.POINTS
local glBeginEnd        = gl.BeginEnd
local glCallList        = gl.CallList
local glColor           = gl.Color
local glCreateList      = gl.CreateList
local glDeleteList      = gl.DeleteList
local glDepthTest       = gl.DepthTest
local glLineWidth       = gl.LineWidth
local glPointSize       = gl.PointSize
local glVertex          = gl.Vertex
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitPosition = Spring.GetUnitPosition

local list
local metalWidth = 0.02
local minWidth   = 0.01
local pointSize  = 0.1
local minSize    = 0.01

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function SyncedCopy(original)   
  local copy = {}
  for k, v in spairs(original) do
    if (type(v) == "table") then
      copy[k] = SyncedCopy(v)
    else
      copy[k] = v
    end
  end
  return copy
end


local function Line(a, b, c, x, y, z)
  glVertex(x, y, z)
  glVertex(a, b, c)
end


local function MetalLines(usedMetal)
  glColor(1, 1, 1, 0.5)
  for x , t in pairs(usedMetal) do
    for z, t in pairs(t) do
      local y = spGetGroundHeight(x, z)
      local a, b, c = spGetUnitPosition(t[1])

      local width = t[2]*metalWidth
      glLineWidth(width > minWidth and width or minWidth)
      glDepthTest(true)
      glBeginEnd(GL_LINES, Line, a, b, c, x, y, z)
      glDepthTest(false)

      local size = t[2]*pointSize
      glPointSize(size > minSize and size or minSize)
      glBeginEnd(GL_POINTS, glVertex, x, y, z)
    end
  end
  glDepthTest(true)
end

local function MetalEvent()
  local usedMetal = SyncedCopy(SYNCED.usedMetal)
  glDeleteList(list)
  list = glCreateList(MetalLines, usedMetal)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  gadgetHandler:AddSyncAction('MetalEvent', MetalEvent)
end


function gadget:DrawWorld()
  if (list) then
    glCallList(list)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end
-- END UNSYNCED
--------------------------------------------------------------------------------














