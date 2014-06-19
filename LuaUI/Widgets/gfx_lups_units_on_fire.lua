-- $Id: gfx_lups_units_on_fire.lua 3171 2008-11-06 09:06:29Z det $

function widget:GetInfo()
  return {
    name      = "Units on Fire",
    desc      = "Graphical effect for burning units",
    author    = "jK/quantum",
    date      = "Sep, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 10,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function MergeTable(outtable,intable)
  for i,v in pairs(intable) do 
    if (outtable[i]==nil) then
      if (type(v)=='table') then
        if (type(outtable[i])~='table') then outtable[i] = {} end
        MergeTable(outtable[i],v)
      else
        outtable[i] = v
      end
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local flameFX = {
    layer        = 0,
    speed        = 0.65,
    life         = 30,
    lifeSpread   = 10,
    delaySpread  = 20,
    colormap     = { {0, 0, 0, 0.},
                     {0.4, 0.4, 0.4, 0.01},
                     {0.35, 0.15, 0.15, 0.20},
                     {0, 0, 0, 0} },
    partpos      = "a,b,c | a=10*(rand()-0.5),b=10*(rand()-0.5),c=10*(rand()-0.5)",
    rotSpeed     = 1,
    rotSpeedSpread = -2,
    rotSpread    = 360,
    size         = 22,
    sizeSpread   = 1,
    sizeGrowth   = 0.9,
    emitVector   = {0,1,0},
    emitRotSpread = 60,
    texture      = 'bitmaps/GPL/flame.png',
    count        = 5,
}

local smokeFX = {
    layer     = 1,

    life         = 50,
    lifeSpread   = 20,

    colormap  = { {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0.15, 0.1, 0.1, 0.4}, {0.03, 0.03, 0.03, 0.25}, {0, 0, 0, 0} },

    texture      = 'bitmaps/GPL/smoke_orange.png',
}

--// merge with shared data in flameLarge
MergeTable(smokeFX, flameFX)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Lups  -- Lua Particle System
local AddParticles
local particleIDs = {}

local random,pi = math.random,math.pi
local sin,cos   = math.sin,math.cos

local GetWind = Spring.GetWind
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRadius   = Spring.GetUnitRadius

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  widgetHandler:RegisterGlobal('onFire', onFire)
end

function widget:Shutdown()
  widgetHandler:DeregisterGlobal('onFire', onFire)
  if (initialized) then
    Lups  = WG['Lups']
    for _,particleID in pairs(particleIDs) do
      Lups.RemoveParticles(particleID)
    end
  end
end

local t = 1
local totalFxCount = 0 --// total lups effects
function widget:Update()
  if (t>2) then
    Lups  = WG['Lups']
    if (Lups) then
      totalFxCount = Lups.GetStats()
      AddParticles = Lups.AddParticles
    end
    t=1
  end
  t=t+1
end


function onFire(burningUnits)
  if (Lups==nil)or(totalFxCount>175) then return end

  --// get wind and random values
  local alpha = 2*pi*random()
  local r = 20*random()
  local wx, wy, wz = GetWind()
  wx, wy, wz = wx*0.09, wy*0.09, wz*0.09
  flameFX.force       = {wx,wy+3,wz}
  smokeFX.force       = flameFX.force

  for i=1,#burningUnits do
    local unitID = burningUnits[i]

    --// send particles to LUPS
    local x, y, z = spGetUnitPosition(unitID)
    local r = spGetUnitRadius(unitID)
    if (r and x) then
      flameFX.pos     = {x,y,z}
      flameFX.partpos = "r*sin(alpha),0,r*cos(alpha) | alpha=rand()*2*pi, r=rand()*0.6*" .. r
      flameFX.size    = r * 0.35
      particleIDs[#particleIDs+1] = AddParticles('SimpleParticles2',flameFX)

      --smokeFX.pos     = flameFX.pos 
      --smokeFX.partpos = flameFX.partpos
      --smokeFX.size    = flameFX.size
      --particleIDs[#particleIDs+1] = AddParticles('SimpleParticles2',smokeFX)
    end

  end
end