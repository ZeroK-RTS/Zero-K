function gadget:GetInfo()
  return {
    name      = "lavarise",
    desc      = "gayly hot",
    author    = "Adapted from knorke's gadget by jseah",
    date      = "Feb 2011, 2011; May 2012",
    license   = "weeeeeee iam on horse",
    layer     = -3,
    enabled   = true
  }
end


if (gadgetHandler:IsSyncedCode()) then
--- SYNCED:

local sin    = math.sin
local random = math.random
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetAllUnits         = Spring.GetAllUnits
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitBasePosition = Spring.GetUnitBasePosition
local spDestroyUnit         = Spring.DestroyUnit
local spEcho                = Spring.Echo
local GAME_SPEED            = Game.gameSpeed

local terraunitDefID = UnitDefNames["terraunit"].id

local tideRhym = {}
local tideIndex = 1
local currentTide
local tideContinueFrame = 0

local modOptions = Spring.GetModOptions()
local lavaRiseCycles = (modOptions.lavarisecycles or 7)
local lavaRisePeriod = (modOptions.lavariseperiod or 120)
local lavaGrowSpeed = 0.25

local minheight, maxheight = Spring.GetGroundExtremes()
local lavaRise = (maxheight - minheight) / lavaRiseCycles
local lavaGrow = lavaGrowSpeed
local lavaLevel = minheight - lavaRise - 20

local nextMessageFrame = -1


local function addTideRhym (targetLevel, speed, remainTime)
  local newTide = {
    targetLevel = targetLevel,
    speed       = speed,
    remainTime  = remainTime
  }
  tideRhym[#tideRhym + 1] = newTide
end


function gadget:Initialize()
  if (modOptions.zkmode ~= "lavarise") then
    gadgetHandler:RemoveGadget()
  end
  addTideRhym (lavaLevel + lavaRise, lavaGrowSpeed, lavaRisePeriod)

  --addTideRhym (-21, 0.25, 5)
  --addTideRhym (150, 0.25, 3)
  --addTideRhym (-20, 0.25, 5)
  --addTideRhym (150, 0.25, 5)
  --addTideRhym (-20, 1, 5)
  --addTideRhym (180, 0.5, 60)
  --addTideRhym (240, 0.2, 10)

  currentTide = tideRhym[tideIndex]
end


local function updateLava (gameframe)
  if (lavaGrow < 0 and lavaLevel < currentTide.targetLevel)
  or (lavaGrow > 0 and lavaLevel > currentTide.targetLevel) then
    tideContinueFrame = gameframe + currentTide.remainTime * GAME_SPEED
    lavaGrow = 0
    if (nextMessageFrame <= gameframe) then
      spEcho ("Next LAVA LEVEL change in " .. (tideContinueFrame-gameframe) / GAME_SPEED .. " seconds", "Lava Height now " .. currentTide.targetLevel, "Next Lava Height " .. currentTide.targetLevel + lavaRise)
      nextMessageFrame = gameframe + 30 * GAME_SPEED
    end
  end

  if (gameframe == tideContinueFrame) then
    addTideRhym (lavaLevel + lavaRise, lavaGrowSpeed, lavaRisePeriod)
    tideIndex = tideIndex + 1
    currentTide = tideRhym[tideIndex]

    --spEcho ("tideIndex=" .. tideIndex .. " target=" .. currentTide.targetLevel )
    if (lavaLevel < currentTide.targetLevel) then
      lavaGrow = currentTide.speed
    else
      lavaGrow = -currentTide.speed
    end
  end
end


local function lavaDeathCheck ()
  local allUnits = spGetAllUnits()
  for i = 1, #allUnits do
    local unitID = allUnits[i]
    local unitDefID = spGetUnitDefID(unitID)
    if (unitDefID ~= terraunitDefID) then
      _,y,_ = spGetUnitBasePosition (unitID)
      if (y and y < lavaLevel) then
        --Spring.AddUnitDamage (unitID,1000)
        spDestroyUnit (unitID)
        --Spring.SpawnCEG("tpsmokecloud", x, y, z)
      end
    end
  end
end


function gadget:GameFrame (f)
  --if (f%2==0) then
    updateLava (f)
    lavaLevel = lavaLevel+lavaGrow

    --if (lavaLevel == 160) then lavaGrow=-0.5 end
    --if (lavaLevel == -10) then lavaGrow=0.25 end
  --end

  if (f%10==0) then
    lavaDeathCheck()
  end

  _G.lavaLevel = lavaLevel + sin(f/30)*2  --make it visible from unsynced
  _G.frame = f

  --[[
  if (f%10==0) then
    local x = random(1,Game.mapSizeX)
    local z = random(1,Game.mapSizeY)
    local y = spGetGroundHeight(x,z)
    if y < lavaLevel then
      Spring.SpawnCEG("tpsmokecloud", x, lavaLevel, z)
    end
  end
  --]]
end


else
--- UNSYNCED:


local sin          = math.sin
local glTexCoord   = gl.TexCoord
local glVertex     = gl.Vertex
local glPushAttrib = gl.PushAttrib
local glDepthTest  = gl.DepthTest
local glDepthMask  = gl.DepthMask
local glTexture    = gl.Texture
local glColor      = gl.Color
local glBeginEnd   = gl.BeginEnd
local glPopAttrib  = gl.PopAttrib
local GL_QUADS           = GL.QUADS
local GL_ALL_ATTRIB_BITS = GL.ALL_ATTRIB_BITS

local lavaTexture = ":a:" .. "bitmaps/lava2.jpg"

local mapSizeX = Game.mapSizeX
local mapSizeY = Game.mapSizeZ


local function DrawGroundHuggingSquareVertices(x1,z1, x2,z2, HoverHeight)
  local y = HoverHeight  --+Spring.GetGroundHeight(x,z)
  local s = 2+sin(SYNCED.frame/50)/10
  glTexCoord(-s,-s)
  glVertex(x1 ,y, z1)

  glTexCoord(-s,s)
  glVertex(x1,y,z2)

  glTexCoord(s,s)
  glVertex(x2,y,z2)

  glTexCoord(s,-s)
  glVertex(x2,y,z1)
end


local function DrawGroundHuggingSquare(red,green,blue,alpha, x1,z1,x2,z2, HoverHeight)
  glPushAttrib(GL_ALL_ATTRIB_BITS)
  glDepthTest(true)
  glDepthMask(true)
  glTexture(lavaTexture)  -- Texture file
  glColor(red,green,blue,alpha)
  glBeginEnd(GL_QUADS, DrawGroundHuggingSquareVertices, x1,z1, x2,z2, HoverHeight)
  glTexture(false)
  glDepthMask(false)
  glDepthTest(false)
  glPopAttrib()
end


function gadget:DrawWorld ()
  if (SYNCED.lavaLevel) then
    --glColor(1-cm1,1-cm1-cm2,0.5,1)

    --DrawGroundHuggingSquare(1-cm1,1-cm1-cm2,0.5,1, 0, 0, mapSizeX, mapSizeY, SYNCED.lavaLevel) --***map.width bla
    DrawGroundHuggingSquare(1,1,1,1, -1000, -1000, mapSizeX + 1000, mapSizeY + 1000, SYNCED.lavaLevel) --***map.width bla
    --DrawGroundHuggingSquare(0,0.5,0.8,0.8, 0, 0, mapSizeX, mapSizeY, SYNCED.lavaLevel) --***map.width bla
  end
end

end  --UNSYNCED