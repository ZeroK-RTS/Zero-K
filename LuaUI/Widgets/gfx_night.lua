-- $Id: gfx_night.lua 3171 2008-11-06 09:06:29Z det $
local versionNumber = "v1.5.12"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Night",
    desc      = versionNumber .. " Makes map appear as nighttime and gives units searchlights.\n",
    author    = "Evil4Zerggin; based on jK's darkening widget",
    date      = "28 September 2008,2012,12 September 2013",
    license   = "GNU LGPL, v2.1 or later",
    layer     = 6, --draw stuff after gui_showeco_action.lua(0) & gui_ally_cursor.lua(5) have drawn theirs to avoid disturbing their color
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--config
--------------------------------------------------------------------------------

local nightColorMap        = {{0.2, 0.2, 0.2}, --midnight
                              {0.2, 0.2, 0.2},
                              {0.2, 0.2, 0.2},
                              
							  {0.2, 0.4, 0.6}, --dawn
                              {1, 0.8, 0.6},
                              {1, 1, 1},
                              {1, 1, 1},
                              
                              {1, 1, 1}, --noon
                              {1, 1, 1},
                              {1, 1, 1},
                              
                              {1, 0.8, 0.6}, --sunset
                              {0.2, 0.4, 0.6},
							  {0.2, 0.2, 0.2},
                              {0.2, 0.2, 0.2},}
                              
local searchlightBeamColor = {1, 1, 0.75, 0.05}  --searchlight beam color
local searchlightStrength  = 0.6                 --searchlight strength; <= 0 to turn off
local searchlightHeightOffset = 1              --raises searchlight above unit's feet by this multiple of the unit's radius
local preUnit              = true                --if true, night is applied pre-unit
local drawBeam             = true                --if true, will draw the searchlight beam
local baseType             = 2               --0: off, 1: simple, 2: full

local searchlightVertexCount       = 16          --roughly many vertices to use

local searchlightAirLeadTime       = 0.5           --roughly how many seconds ahead the searchlight aims
local searchlightGroundLeadTime    = 1           --roughly how many seconds ahead the searchlight aims

local dayNightCycle        = true                --enables day/night cycle
local startDayTime         = 0                   --start time, between 0 and 1; 0 = midnight, 0.5 = noon
local secondsPerDay        = 600                 --seconds per day

local maxBeamDivergent = 2 					--how big the light beam can expand if unit get further away from ground

--------------------------------------------------------------------------------
--other vars
--------------------------------------------------------------------------------

local currColor, currColorInverse

local hoursPerDay = #nightColorMap --14hours per day

local currDayTime

local searchlightVertexIncrement = (math.pi * 2) / searchlightVertexCount

local searchlightBuildingAngle = 0

local noLightList = {}

local vsx, vsy

local cache = {} --cache some calculation result for efficiency

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function UpdateColors() end	-- redefined below
local function UpdateDayPeriod() end

options_path = 'Settings/Graphics/Effects/Night View'
options_order = {"coloredUnits", "cycle", "time","secperday", "beam", "bases"}
options = {
	--[[
	night = {
		name = 'Night View',
		desc = 'Turns night widget on/off.',
		type = 'bool',
		value = 0,
	},
	]]--
	coloredUnits = {
		name = "Bright Units",
		type = 'bool',
		value = true,
		desc = 'Bright units even at night',
		noHotkey = true,
	},
	cycle = {
		name = "Day/night cycle",
		type = 'bool',
		value = true,
		desc = 'Enable day/night cycle',
		noHotkey = true,
	},
	time = {
		name = "Time of day",
		type = 'number',
		min = 0,
		max = 0.5,
		step = 0.05,
		value = 0.4,
		desc = 'Starting Time of day.\n <--Midnight, Noon-->',
		OnChange = function(self)
			currDayTime = self.value
			UpdateColors()
		end,
	},
	secperday = {
		name = "Game Minute Per Day",
		type = 'number',
		min = 1,
		max = 20,
		step = 1,
		value = 2,
		OnChange = function(self)
			secondsPerDay = self.value*60
			UpdateDayPeriod()
			Spring.Echo(self.value .. " Minute")
		end,
	},
	beam = {
		name = "Searchlight Beams",
		type = 'bool',
		value = true,
		desc = 'Display searchlight beams',
		noHotkey = true,
	},
	bases = {
		name = "Searchlight Bases",
		type = 'radioButton',
		items = {
			{ key = 'none', name = 'None', },
			{ key = 'simple', name = 'Simple', },
			{ key = 'full', name = 'Full', },
		},
		value = 'full',
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
-- speedups and constants
--------------------------------------------------------------------------------

local GetMapDrawMode = Spring.GetMapDrawMode
local GetVisibleUnits = Spring.GetVisibleUnits
local GetUnitPosition = Spring.GetUnitPosition
local GetUnitHeight = Spring.GetUnitHeight
local GetGroundHeight = Spring.GetGroundHeight
local GetUnitHeading = Spring.GetUnitHeading
local GetUnitDefID = Spring.GetUnitDefID
local GetUnitVelocity = Spring.GetUnitVelocity
local GetUnitIsCloaked = Spring.GetUnitIsCloaked
local GetUnitIsDead = Spring.GetUnitIsDead
local GetUnitHealth = Spring.GetUnitHealth
local GetUnitRadius = Spring.GetUnitRadius
local GetGameSpeed = Spring.GetGameSpeed
local GetCameraPosition = Spring.GetCameraPosition
local GetUnitTransporter = Spring.GetUnitTransporter
local SendMessage = Spring.SendMessage

local glMatrixMode = gl.MatrixMode
local glLoadIdentity = gl.LoadIdentity
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glColor = gl.Color
local glRect = gl.Rect
local glTranslate = gl.Translate
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local glPolygonMode = gl.PolygonMode
local glDepthTest = gl.DepthTest
local glBlending = gl.Blending

local GL_TRIANGLE_FAN = GL.TRIANGLE_FAN
local GL_PROJECTION = GL.PROJECTION
local GL_MODELVIEW = GL.MODELVIEW
local GL_FRONT_AND_BACK = GL.FRONT_AND_BACK
local GL_FILL = GL.FILL
local GL_POLYGON = GL.POLYGON
local GL_SRC_COLOR = GL.SRC_COLOR
local GL_DST_COLOR = GL.DST_COLOR
local GL_SRC_ALPHA = GL.SRC_ALPHA
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_ONE = GL.ONE
local GL_ZERO = GL.ZERO

local RADIANS_PER_COBANGLE = math.pi / 32768

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
UpdateColors = function()
  local currHour = math.floor(currDayTime * hoursPerDay) + 1 -- (realnumber(0..1) * 14)roundedToNearest_0 + 1 = integer[1..14]
  local currHourPart = currDayTime * hoursPerDay - currHour + 1 -- (realnumber(0..1) * 14) - integer[1..14] + 1 = realnumber(0..1)
  local startColor = nightColorMap[currHour]
  local endColor
  if (currHour == hoursPerDay) then
    endColor = nightColorMap[1]
  else
    endColor = nightColorMap[currHour+1]
  end
  
  currColor = {(1 - currHourPart) * startColor[1] + currHourPart * endColor[1],
               (1 - currHourPart) * startColor[2] + currHourPart * endColor[2],
               (1 - currHourPart) * startColor[3] + currHourPart * endColor[3],
               1}
  currColorInverse = {(1 / currColor[1] - 1) * searchlightStrength,
                      (1 / currColor[2] - 1) * searchlightStrength,
                      (1 / currColor[3] - 1) * searchlightStrength,
                       1}
end

local function BaseVertices(baseX, baseZ, radius, ecc, heading,yOffset)
  if yOffset then
	yOffset = GetGroundHeight(baseX, baseZ) + yOffset
  end
  local theta = heading
  while theta < heading + 2 * math.pi do
    local denom = (1 - ecc * math.cos(theta - heading))
    local vx = baseX + radius * math.cos(theta) / denom
    local vz = baseZ + radius * math.sin(theta) / denom
    local vy = yOffset or math.max(GetGroundHeight(vx, vz), 0) --follow ground contour
    glVertex(vx, vy, vz)
    theta = theta + searchlightVertexIncrement * denom
  end
  local denom = 1 - ecc
  local vx = baseX + radius * math.cos(heading) / denom
  local vz = baseZ + radius * math.sin(heading) / denom
  local vy = yOffset or  math.max(GetGroundHeight(vx, vz), 0)
  glVertex(vx, vy, vz)
end

local function ConeVertices(baseX, baseZ, radius, ecc, heading, cx, cy, cz)
  local groundy = math.max(GetGroundHeight(baseX, baseZ), 0)
  local dx = cx - baseX
  local dy = cy - groundy
  local dz = cz - baseZ
  local mult = radius / math.sqrt(dx*dx + dy*dy + dz*dz)
  dx = dx * mult
  dy = dy * mult
  dz = dz * mult
  glVertex(baseX + dx, groundy + dy, baseZ + dz)
  BaseVertices(baseX, baseZ, radius, ecc, heading)
end

local function BeamVertices(baseX, baseZ, radius, ecc, heading, px, py, pz, yOffset)
  glVertex(px, py, pz)
  BaseVertices(baseX, baseZ, radius, ecc, heading,yOffset)
end

local function DrawNight()
  glBlending(GL_ZERO, GL_SRC_COLOR)
  
  glMatrixMode(GL_PROJECTION)
  glPushMatrix()
  glLoadIdentity()
  glMatrixMode(GL_MODELVIEW)
  glPushMatrix()
  glLoadIdentity()

  glColor(currColor)
  glRect(-1,1,1,-1)

  glMatrixMode(GL_PROJECTION)
  glPopMatrix()
  glMatrixMode(GL_MODELVIEW)
  glPopMatrix()
  
  glColor(1, 1, 1, 1)
  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end

local function DrawSearchlights()
  if (searchlightVertexCount < 2) then return end
  if (options.bases.value == "none") and (options.beam.value == false) then return end
  
  local visibleUnits = GetVisibleUnits(-1, 30, false)
  local cx, cy, cz = GetCameraPosition()
  local timeFromNoon = math.abs(currDayTime - 0.5)
  
  glTranslate(0, 0, 0)
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
  
  for _, unitID in pairs(visibleUnits) do
	if GetUnitPosition(unitID) and not GetUnitIsDead(unitID) then
		local _, _, _, _, buildProgress = GetUnitHealth(unitID)
		local defID = GetUnitDefID(unitID)
		local unitRadius = GetUnitRadius(unitID) or 10
		local px, py, pz = GetUnitPosition(unitID) --get position.
		local relativeHeight = searchlightHeightOffset * unitRadius
		py = py + relativeHeight
		local groundy = math.max(GetGroundHeight(px, pz), 0)
		local absHeight = py - groundy
		local unitDef = UnitDefs[defID]
		
		if (unitDef
			and absHeight > 0
			and (not buildProgress or buildProgress >= 1)
			and not noLightList[defID]
			and timeFromNoon > (0.25 + ((unitID * 97) % 256) / 8192)
			and not GetUnitIsCloaked(unitID)
			and not GetUnitTransporter(unitID)
			) then
		  local leadDistance
		  local radius
		  local ecc
		  local heading
		  local baseX, baseZ
		  local leadDist_to_height_ratio = 1
		  local isAboveNominalHeight = false
		  
		  if unitDef.isImmobile then
			cache[defID]= cache[defID] or {}
			if not cache[defID].leadDist then
				leadDistance = unitRadius * 2
				leadDist_to_height_ratio = leadDistance/relativeHeight
				--cache
				cache[defID].leadDist = leadDistance
				cache[defID].lhRatio = leadDist_to_height_ratio
			end
			heading = searchlightBuildingAngle * (0.5 + ((unitID * 137) % 256) / 512)
			leadDistance = cache[defID].leadDist
			leadDist_to_height_ratio = cache[defID].lhRatio
			radius = unitRadius
		  elseif unitDef.isBomberAirUnit or unitDef.isFighterAirUnit then
			local vx, _, vz = GetUnitVelocity(unitID)
			if not vx or not vz then --sometimes happen when seeing enemy airplane
				vx=0
				vz=0
			end
			heading = math.atan2(vz, vx)
			leadDistance = searchlightAirLeadTime * math.sqrt(vx * vx + vz * vz) * 30
			relativeHeight = relativeHeight+unitDef.wantedHeight--nominal search light height is unit height + flying height distance
			leadDist_to_height_ratio = leadDistance/relativeHeight
			radius = unitRadius * 2
		  elseif (unitDef.canFly) then
			cache[defID]= cache[defID] or {}
			if not cache[defID].leadDist then
				local range = math.max(unitDef.buildDistance, unitDef.maxWeaponRange)
				leadDistance = math.sqrt(math.max(range * range - unitDef.wantedHeight * unitDef.wantedHeight,0)) * 0.8
				relativeHeight = relativeHeight+unitDef.wantedHeight
				leadDist_to_height_ratio = leadDistance/relativeHeight
				--cache
				cache[defID].leadDist = leadDistance
				cache[defID].relativeY = relativeHeight
				cache[defID].lhRatio = leadDist_to_height_ratio
			end
		    heading = -1*(GetUnitHeading(unitID) or 0) * RADIANS_PER_COBANGLE + math.pi / 2
			leadDistance = cache[defID].leadDist
			relativeHeight = cache[defID].relativeY
			leadDist_to_height_ratio = cache[defID].lhRatio
			radius = unitRadius * 2
		  else
			local speed = unitDef.speed
		    cache[defID]= cache[defID] or {}
			if not cache[defID].leadDist then
				leadDistance = searchlightGroundLeadTime * speed
				leadDist_to_height_ratio = leadDistance/relativeHeight
				--cache
				cache[defID].leadDist = leadDistance
				cache[defID].lhRatio = leadDist_to_height_ratio
			end
			heading = -1*(not (GetUnitIsDead(unitID)) and GetUnitHeading(unitID) or 0) * RADIANS_PER_COBANGLE + math.pi / 2
			leadDistance = cache[defID].leadDist
			leadDist_to_height_ratio = cache[defID].lhRatio
			radius = unitRadius
		  end
		  --scale lenght based on height--
		  local newLeadDist = math.min(leadDist_to_height_ratio*absHeight,leadDistance*maxBeamDivergent) --limit searchlight distance to 1.25x the expected distance (beam distance usually become longer if unit jump and become shorter if a gunship/airplane land)
		  baseX = px + newLeadDist * math.cos(heading)
		  baseZ = pz + newLeadDist * math.sin(heading)
		  ecc = math.min(1 - 2 / (newLeadDist / absHeight + 2), 0.75)
		  
		  --base
		  glBlending(GL_DST_COLOR, GL_ONE)
		  glColor(currColorInverse)
		  
		  --scale radius based on height--
		  if cache[defID] and not cache[defID].rlRatio then
			cache[defID].rlRatio = radius/math.sqrt(leadDistance*leadDistance+ relativeHeight*relativeHeight)
		  end
		  local cached_rlRatio = cache[defID] and cache[defID].rlRatio
		  local radius_to_leadDist_ratio= cached_rlRatio or radius/math.sqrt(leadDistance*leadDistance+ relativeHeight*relativeHeight) --ratio of radius-over-distance for original beam
		  local newRadius = radius_to_leadDist_ratio*math.sqrt(newLeadDist*newLeadDist+ absHeight*absHeight) --explaination: newRadius/newHeight = oldRadius/oldHeight (The same radius-over-distance ratio must apply for all height)
		  --limit size
		  if newRadius/radius >= maxBeamDivergent then
			isAboveNominalHeight = true
			radius = radius*maxBeamDivergent
		  else
			radius = newRadius
		  end
		  
		  if not isAboveNominalHeight then
			  if (options.bases.value == "full") then --highlight ground
				glDepthTest(true)
				glBeginEnd(GL_TRIANGLE_FAN, ConeVertices, baseX, baseZ, radius, ecc, heading, cx, cy, cz)
			  elseif (options.bases.value == "simple") then
				glDepthTest(false)
				glBeginEnd(GL_POLYGON, BaseVertices, baseX, baseZ, radius, ecc, heading)
			  end
		  end
		  
		  --beam
		  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
		  
		  if (options.beam.value) then
			glColor(searchlightBeamColor)
			glDepthTest(true)
			glBeginEnd(GL_TRIANGLE_FAN, BeamVertices, baseX, baseZ, radius, ecc, heading, px, py, pz,isAboveNominalHeight and absHeight-relativeHeight*maxBeamDivergent)
		  end
		  
		  glColor(1, 1, 1, 1)
		  glDepthTest(false)
		  
		end
	end
  end
  
end

local function TogglePreUnit()
  preUnit = not preUnit
  if (preUnit) then
    SendMessage("Night preunit turned on.")
  else
    SendMessage("Night preunit turned off.")
  end
end

local function SetBaseType(_,_,words)
  baseType = tonumber(words[1]) or 0
  if (baseType == 2) then
    SendMessage("Full searchlight bases.")
  elseif (baseType == 1) then
    SendMessage("Simple searchlight bases.")
  else
    SendMessage("No searchlight bases.")
  end
end

local function ToggleBeam()
  drawBeam = not drawBeam
  if (drawBeam) then
    SendMessage("Night beams turned on.")
  else
    SendMessage("Night beams turned off.")
  end
end

local function SetSearchlightStrength(_,_,words)
  searchlightStrength = tonumber(words[1])
  UpdateColors()
end

local function ToggleDayNightCycle()
  dayNightCycle = not dayNightCycle
  if (dayNightCycle) then
    SendMessage("Day/night cycle turned on.")
  else
    SendMessage("Day/night cycle turned off.")
  end
end

--------------------------------------------------------------------------------
--callins
--------------------------------------------------------------------------------

function widget:Initialize()
  currDayTime = options.time.value or startDayTime
  UpdateColors()
  vsx, vsy = widgetHandler:GetViewSizes()
  
  for unitDefID, unitDef in pairs(UnitDefs) do
    if (   string.find(unitDef.name, "chicken")
        or string.find(unitDef.name, "roost")
        or string.find(unitDef.humanName, "Chicken")
        or string.find(unitDef.humanName, "Montro")
        or (unitDef.isImmobile and not
             (unitDef.weapons and unitDef.weapons[1]))
       ) then
      noLightList[unitDefID] = true
    end
  end

  --[[
  widgetHandler:AddAction("night_preunit", TogglePreUnit, nil, "t")
  widgetHandler:AddAction("night_basetype", SetBaseType, nil, "t")
  widgetHandler:AddAction("night_beam", ToggleBeam, nil, "t")
  widgetHandler:AddAction("night_setsearchlight", SetSearchlightStrength, nil, "t")
  widgetHandler:AddAction("night_cycle", ToggleDayNightCycle, nil, "t")
  ]]--
end

function widget:Shutdown()
  --[[
  widgetHandler:RemoveAction("night_preunit")
  widgetHandler:RemoveAction("night_basetype")
  widgetHandler:RemoveAction("night_beam")
  widgetHandler:RemoveAction("night_setsearchlight")
  widgetHandler:RemoveAction("night_cycle")
  ]]--
end

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end

local update = 0
local updatePeriod = 7
local updateSecond = updatePeriod*0.0333
local dayPerUpdate = updateSecond/secondsPerDay --dayPerUpdate range from 0 -> 1

UpdateDayPeriod = function()
	dayPerUpdate = updateSecond/secondsPerDay
end

function widget:GameFrame(n)
	update = update + 1
	searchlightBuildingAngle = searchlightBuildingAngle + 0.0333
	if update > updatePeriod then
		if (options.cycle.value) then
			currDayTime = currDayTime + dayPerUpdate
			currDayTime = currDayTime - math.floor(currDayTime) --currDayTime range from 0 -> 1
			UpdateColors()
		end
		update = 0
	end
end

function widget:DrawWorldPreUnit()
  if (options.coloredUnits.value) then
    DrawNight()
  end
end

function widget:DrawWorld()
  if (not options.coloredUnits.value) then
    DrawNight()
  end
  if (searchlightStrength > 0 and math.abs(currDayTime - 0.5) > 0.25) then
    DrawSearchlights()
  end
end
