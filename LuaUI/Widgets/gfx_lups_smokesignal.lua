function widget:GetInfo()
  return {
    name      = "Smoke Signal",
    desc      = "Adds a Lups smoke signal to marker points",
    author    = "jK/quantum",
    date      = "Sep, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 10,
    enabled   = false  --  loaded by default?
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

local smokeFX = {
    layer     = 1,
	alwaysVisible = true,
	speed        = 0.65,
	count        = 300,
	
	colormap     = { {0, 0, 0, 0.01},
				     {0.4, 0.4, 0.4, 0.01},
                     {0.35, 0.15, 0.15, 0.20},
                     {0, 0, 0, 0.01} },
	
    life         = 50,
    lifeSpread   = 20,
	delaySpread  = 900,
    rotSpeed     = 1,
    rotSpeedSpread = -2,
    rotSpread    = 360,	
	size = 30,
    sizeSpread   = 5,
    sizeGrowth   = 0.9,
    emitVector   = {0,1,0},
    emitRotSpread = 60,
	
    texture      = 'bitmaps/smoke/smoke01.tga',
}

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
end

function widget:Shutdown()
  if (initialized) then
    Lups  = WG['Lups']
    for _,particleID in pairs(particleIDs) do
      Lups.RemoveParticles(particleID)
    end
  end
end

local t = 1
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

function widget:MapDrawCmd(playerID, cmdType, px, py, pz, caption)
  if (cmdType ~= 'point') or not(Spring.GetGameSeconds()>0) or (Lups==nil) then return end
  --// get wind and random values
  local wx, wy, wz = GetWind()
  wx, wy, wz = wx*0.09, wy*0.09, wz*0.09
  smokeFX.force       = {wx,wy+3,wz}

  local _,_,spec,team = Spring.GetPlayerInfo(playerID)
  if not team then return end
  local r, g, b = Spring.GetTeamColor(team)
  if spec then r, g, b = 1, 1, 1 end
  
    --// send particles to LUPS
  smokeFX.pos     = {px,py,pz}
  smokeFX.partpos = "r*sin(alpha),0,r*cos(alpha) | alpha=rand()*2*pi, r=rand()*20"
  smokeFX.colormap[2] = { r, g, b, smokeFX.colormap[2][4]}
  smokeFX.colormap[3] = { r, g, b, smokeFX.colormap[3][4]}
  smokeFX.texture = "bitmaps/smoke/smoke0" .. math.random(1,9) .. ".tga"
  particleIDs[#particleIDs+1] = AddParticles('SimpleParticles2',smokeFX)
end