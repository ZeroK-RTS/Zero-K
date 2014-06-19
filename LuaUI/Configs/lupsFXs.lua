VFS.Include("LuaRules/Utilities/tablefunctions.lua")

----------------------------------------------------------------------------
-- GROUNDFLASHES -----------------------------------------------------------
----------------------------------------------------------------------------
groundFlash = {
  life       = 40,
  size       = 30,
  sizeGrowth = 7,
  colormap   = { {1, 1, 0.5, 0.3},{1, 1, 0, 0.04},{1, 0.3, 0, 0} }
}

groundFlashRed = {
  life       = 20,
  size       = 100,
  texture    = "bitmaps/GPL/Lups/groundflash.png",
  colormap   = { {1, 0.2, 0.2, 0.3},{1, 0.2, 0.2, 0.4},{1, 0.2, 0.2, 0.4},{1, 0.2, 0.2, 0.3}, },
  repeatEffect = true,
}

groundFlashOrange = {
  life       = 20,
  size       = 100,
  texture    = "bitmaps/GPL/Lups/groundflash.png",
  colormap   = { {0.85, 0.5, 0.25, 0.3},{0.85, 0.5, 0.25, 0.4},{0.85, 0.5, 0.25, 0.4},{0.85, 0.5, 0.25, 0.3}, },
  repeatEffect = true,
}

groundFlashGreen = {
  life       = 20,
  size       = 100,
  texture    = "bitmaps/GPL/Lups/groundflash.png",
  colormap   = { {0.3, 1.0, 0.3, 0.3},{0.3, 1.0, 0.3, 0.4},{0.3, 1.0, 0.3, 0.4},{0.3, 1.0, 0.3, 0.3}, },
  repeatEffect = true,
}

groundFlashBlue = {
  life       = 20,
  size       = 100,
  texture    = "bitmaps/GPL/Lups/groundflash.png",
  colormap   = { {0.5, 0.5, 1.0, 0.3},{0.5, 0.5, 1.0, 0.4},{0.5, 0.5, 1.0, 0.4},{0.5, 0.5, 1.0, 0.3}, },
  repeatEffect = true,
}

groundFlashViolet = {
  life       = 50,
  size       = 80,
  texture    = "bitmaps/GPL/Lups/groundflash.png",
  colormap   = { {0.9, 0.1, 0.9, 0.1},{0.9, 0.1, 0.9, 0.2},{0.9, 0.1, 0.9, 0.2},{0.9, 0.1, 0.9, 0.1}, },
  repeatEffect = true,
}

groundFlashShield = {
  life       = 50,
  size       = 360,
  texture    = "bitmaps/GPL/Lups/groundringBW.png",
  colormap   = { {0.9, 0.1, 0.9, 0.2},{0.9, 0.1, 0.9, 0.3},{0.9, 0.1, 0.9, 0.2},{0.9, 0.1, 0.9, 0.2}, },
  repeatEffect = true,
}

groundFlashCorestor = {
  life       = 50,
  size       = 80,
  texture    = "bitmaps/GPL/Lups/gf_corestor.png",
  colormap   = { {0.9, 0.9, 0.0, 0.15},{0.9, 0.9, 0.0, 0.20},{0.9, 0.9, 0.0, 0.20},{0.9, 0.9, 0.0, 0.15}, },
  repeatEffect = true,
}
groundFlashArmestor = {
  life       = 50,
  size       = 80,
  texture    = "bitmaps/GPL/Lups/gf_armestor.png",
  colormap   = { {0.9, 0.9, 0.0, 0.2},{0.9, 0.9, 0.0, 0.3},{0.9, 0.9, 0.0, 0.3},{0.9, 0.9, 0.0, 0.2}, },
  repeatEffect = true,
}

----------------------------------------------------------------------------
-- BURSTS ------------------------------------------------------------------
----------------------------------------------------------------------------
corfusBursts = {
  delay      = 30,
  life       = math.huge,
  pos        = {0,40,0},
  rotSpeed   = 2,
  rotSpread  = 1,
  rotairdrag = 1,
  arc        = 90,
  arcSpread  = 0,
  size       = 17,
  sizeSpread = 5,
  --colormap   = { {0.10, 0.8, 0.8, 0.4} },
  colormap   = { {0.8, 0.4, 0.1, 0.4} },
  directional= true,
  repeatEffect = true,
  count      = 17,
}

cafusBursts = {
  life       = math.huge,
  pos        = {0,58,-5},
  rotSpeed   = 0.5,
  rotSpread  = 1,
  arc        = 90,
  arcSpread  = 0,
  size       = 35,
  sizeSpread = 10,
  colormap   = { {1.0, 0.7, 0.5, 0.3} },
  directional= true,
  repeatEffect = true,
  count      = 20,
}

corjamtBursts = {
  layer      = -35,
  life       = math.huge,
  piece      = "glow",
  rotSpeed   = 0.7,
  rotSpread  = 0,
  arc        = 50,
  arcSpread  = 0,
  size       = 14,
  sizeSpread = 10,
  texture    = "bitmaps/GPL/Lups/shieldbursts5.png",
  --colormap   = { {1, 0.6, 1, 0.8} },
  colormap   = { {1, 0.3, 1, 0.8} },
  directional= true,
  repeatEffect = true,
  count      = 20,
}

----------------------------------------------------------------------------
-- COLORSPHERES ------------------------------------------------------------
----------------------------------------------------------------------------
cafusShieldSphere = {
  layer=-35,
  life=20,
  pos={0,58.9,-4.5},
  size=24,
  colormap1 = { {0.9, 0.9, 1, 0.75},{0.9, 0.9, 1, 1.0},{0.9, 0.9, 1, 1.0},{0.9, 0.9, 1, 0.75} },
  colormap2 = { {0.2, 0.2, 1, 0.7},{0.2, 0.2, 1, 0.75},{0.2, 0.2, 1, 0.75},{0.2, 0.2, 1, 0.7} },
  repeatEffect=true
}

corfusShieldSphere = {
  layer=-35,
  life=20,
  pos={0,40.5,0},
  size=21.5,
  colormap1 = { {0.9, 0.9, 1, 0.75},{0.9, 0.9, 1, 1.0},{0.9, 0.9, 1, 1.0},{0.9, 0.9, 1, 0.75} },
  colormap2 = { {0.05, 0.35, .44, 0.7},{0.05, 0.35, .44, 0.75},{0.05, 0.35, .44, 0.75},{0.05, 0.35, .44, 0.7} },
  repeatEffect=true
}

teleShieldSphere = {
  life=20,
  pos={0,0,0},
  size=9,
  colormap1 = { {0.9, 0.9, 1, 0.75},{0.9, 0.9, 1, 1.0},{0.9, 0.9, 1, 1.0},{0.9, 0.9, 1, 0.75} },
  colormap2 = { {0.2, 0.2, 1, 0.7},{0.2, 0.2, 1, 0.75},{0.2, 0.2, 1, 0.75},{0.2, 0.2, 1, 0.7} },
  repeatEffect=true
}

valkShieldSphere = {
  life=20,
  pos={0,0,0},
  size=4,
  colormap1 = { {0.9, 0.9, 1, 0.75},{0.9, 0.9, 1, 1.0},{0.9, 0.9, 1, 1.0},{0.9, 0.9, 1, 0.75} },
  colormap2 = { {0.2, 0.2, 1, 0.7},{0.2, 0.2, 1, 0.75},{0.2, 0.2, 1, 0.75},{0.2, 0.2, 1, 0.7} },
  repeatEffect=true
}

commandShieldSphere = {
  life			= math.huge,
  heightFactor	= 0.75,
  radiusFactor	= 1.75, 
  repeatEffect	= true
}

----------------------------------------------------------------------------
-- LIGHT -------------------------------------------------------------------
----------------------------------------------------------------------------
cafusCorona = {
  pos         = {0,58.9,0},
  life        = math.huge,
  lifeSpread  = 0,
  size        = 90,
  sizeGrowth  = 0,
  --colormap    = { {0.7, 0.6, 0.5, 0.01} },
  colormap    = { {0.9, 0.4, 0.2, 0.01} },
  texture     = 'bitmaps/GPL/groundflash.tga',
  count       = 1,
  repeatEffect = true,
}

corfusCorona = {
  delay       = 25,
  pos         = {0,40.5,0},
  life        = math.huge,
  lifeSpread  = 0,
  size        = 55,
  sizeGrowth  = 0,
  colormap    = { {0.3, 0.7, 1, 0.005}  },
  texture     = 'bitmaps/GPL/groundflash.tga',
  count       = 1,
  repeatEffect = true,
}

corfusNova = {
  layer       = 1,
  pos         = {0,40.5,0},
  life        = 26,
  lifeSpread  = 0,
  size        = 0,
  sizeGrowth  = 3,
  colormap    = { {1.0, 0.6, 0.1, 0.005}, {1.0, 0.6, 0.1, 0.005}, {1.0, 0.6, 0.1, 0.005}, {0, 0, 0, 0.005} },
  texture     = 'bitmaps/GPL/smallflare.tga',
  count       = 1,
}


corfusNova2 = {
  layer       = 1,
  delay       = 10,
  pos         = {0,40.5,0},
  life        = 35,
  lifeSpread  = 0,
  size        = 0,
  sizeGrowth  = 2,
  colormap    = { {0.5, 0.35, 0.15, 0.005}, {0.5, 0.35, 0.15, 0.005}, {0.5, 0.35, 0.15, 0.005}, {0, 0, 0, 0.005} },
  texture     = 'bitmaps/GPL/groundflash.tga',
  count       = 1,
}


corfusNova3 = {
  layer       = -10,
  delay       = 25,
  pos         = {0,40.5,0},
  life        = math.huge,
  lifeSpread  = 0,
  size        = 50,
  sizeGrowth  = 0,
  colormap    = { {1.0, 0.5, 0.1, 0.005} },
  texture     = 'bitmaps/GPL/smallflare.tga',
  count       = 1,
  repeatEffect= true,
}


corfusNova4 = {
  layer       = -5,
  delay       = 25,
  pos         = {0,40.5,0},
  life        = math.huge,
  lifeSpread  = 0,
  size        = 50,
  sizeGrowth  = 0,
  colormap    = { {0.6, 0.15, 0.04, 0.005}, {0, 0, 0, 0.005} },
  texture     = 'bitmaps/Saktoths/groundring.tga',
  count       = 1,
  repeatEffect= true,
}


radarBlink = {
  piece       = "head_3",
  onActive    = true,
  pos         = {0.5,31,1.2},
  life        = 120,
  size        = 5,
  sizeGrowth  = 2,
  colormap    = { {0.3, 1, 1, 0.005}, {0, 0, 0, 0.005},{0, 0, 0, 0.005},{0, 0, 0, 0.005},{0, 0, 0, 0.005},{0, 0, 0, 0.005},{0, 0, 0, 0.005},{0, 0, 0, 0.005},{0, 0, 0, 0.005},{0, 0, 0, 0.005},{0, 0, 0, 0.005},{0, 0, 0, 0.005} },
  texture     = 'bitmaps/GPL/smallflare.tga',
  count       = 1,
  repeatEffect= true,
}

warpgateCorona = {
  pos         = {0,58.9,0},
  life        = math.huge,
  lifeSpread  = 0,
  size        = 210,
  sizeGrowth  = 0,
  --colormap    = { {0.7, 0.6, 0.5, 0.01} },
  colormap    = { {0.1, 0.3, 0.8, 0.01} },
  texture     = 'bitmaps/GPL/groundflash.tga',
  count       = 1,
  repeatEffect = true,
}

zenithCorona = {
  pos         = {0,130,0},
  life        = math.huge,
  lifeSpread  = 0,
  size        = 160,
  sizeGrowth  = 0,
  colormap    = { {0.4, 0.2, 0.9, 0.01} },
  texture     = 'bitmaps/GPL/groundflash.tga',
  count       = 1,
  repeatEffect = true,
}

teleCorona = {
  pos	      = {0,0,0},
  life        = math.huge,
  lifeSpread  = 0,
  size        = 50,
  sizeGrowth  = 0,
  colormap    = { {0, 0.4, 1, 0.01} },
  texture     = 'bitmaps/GPL/groundflash.tga',
  count       = 1,
  repeatEffect = true,
}

valkCorona = {
  pos	      = {0,0,0},
  life        = math.huge,
  lifeSpread  = 0,
  size        = 30,
  sizeGrowth  = 0,
  colormap    = { {0, 0.4, 1, 0.01} },
  texture     = 'bitmaps/GPL/groundflash.tga',
  count       = 1,
  repeatEffect = true,
}

commandCoronaWhite = {
  heightFactor = 0.75,
  life        = 60,
  lifeSpread  = 0,
  radiusFactor = 8,
  sizeGrowth  = 0,
  colormap    = { {1, 1, 1, 0.01}, {0.8, 0.8, 0.8, 0.01}, {1, 1, 1, 0.01}, },
  texture     = 'bitmaps/GPL/groundflash.tga',
  count       = 1,
  repeatEffect = true,
}

local commandCoronaColors = {
	Red = { {0.6, 0.05, 0.05, 0.01}, {0.48, 0.04, 0.04, 0.01}, {0.6, 0.05, 0.05, 0.01}, },
	Blue = { {0.05, 0.05, 0.6, 0.01}, {0.04, 0.04, 0.48, 0.01}, {0.05, 0.05, 0.6, 0.01}, },
	Green = { {0.05, 0.5, 0.05, 0.01}, {0.04, 0.4, 0.04, 0.01}, {0.05, 0.5, 0.05, 0.01}, },
	Orange = { {0.4, 0.15, 0.05, 0.01}, {0.32, 0.12, 0.04, 0.01}, {0.4, 0.15, 0.05, 0.01}, },
}

local function InterpolateColors(startColor, endColor, steps)
	local output = { startColor }
	local alpha = startColor[4]
	for i=1,steps do
		output[i+1] = {}
		for j=1,3 do
			local stepSize = (endColor[j] - startColor[j])/steps
			output[i+1][j] = output[i][j] + stepSize
		end
		output[i+1][4] = alpha
	end
	output[#output+1] = endColor
	return output
end

--commandCoronaWhite.colorMap = InterpolateColors(commandCoronaWhite.colormap[1], commandCoronaWhite.colormap[2], 3)

for name, color in pairs(commandCoronaColors) do
	--color = InterpolateColors(color[1], color[2], 5)
	local key = "commandCorona"..name
	widget[key] = Spring.Utilities.CopyTable(commandCoronaWhite, true)
	widget[key]["colormap"] = color
end

jackGlow = {
  life        = 60,
  lifeSpread  = 0,
  size        = 60,
  sizeSpread  = 5,
  colormap    = { {1.0, 0.6, 0.2, 0.02}, {0.66, 0.4, 0.133, 0.02}, {1.0, 0.6, 0.2, 0.02} },
  texture     = 'bitmaps/GPL/smallflare.tga',
  count       = 1,
  repeatEffect = true,
}

blinkyLightWhite = {
  life        = 60,
  lifeSpread  = 0,
  size        = 20,
  sizeSpread  = 0,
  colormap    = { {1, 1, 1, 0.02}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0} },
  texture     = 'bitmaps/GPL/smallflare.tga',
  count       = 1,
  repeatEffect = true,
}

local blinkyLightColors = {
	Red = {1, 0.1, 0.1, 0.02},
	Blue = {0.1, 0.1, 1, 0.02},
	Green = {0, 1, 0.2, 0.02},
	Orange = {0.8, 0.2, 0., 0.02},
	Violet = {0.5, 0, 0.6, 0.02},
}

for name, color in pairs(blinkyLightColors) do
	local key = "blinkyLight"..name
	widget[key] = Spring.Utilities.CopyTable(blinkyLightWhite, true)
	widget[key]["colormap"][1] = color
end

----------------------------------------------------------------------------
-- OverDrive FXs -----------------------------------------------------------
----------------------------------------------------------------------------

cormexGlow = {
  layer       = -5,
  delay       = 0,
  pos         = {0,0,0},
  piece       = "furnace",

  partpos = "x,y,z|"..
	"y = ((i>3) and 59) or 49,"..
	"local i = i%4,"..
	"local d = 5,"..
	"x = ((i>1) and -d) or d,"..
	"z = (((i==0)or(i==3)) and -d) or d",

  life        = math.huge,
  lifeSpread  = 0,
  sizeGrowth  = 0,

  size        = 11,
  size1       = 11,
  size2       = 13,

  colormap    = { {0.13, 0.1, 0.001, 0.002}, },
  color1      = {0.1, 0.1, 0.001, 0.002},
  color2      = {0.9, 0.4, 0.005, 0.005},

  texture     = 'bitmaps/GPL/groundflash.tga',
  count       = 8,
  repeatEffect= true,
  onActive    = true,
}


----------------------------------------------------------------------------
-- SimpleParticles ---------------------------------------------------------
----------------------------------------------------------------------------
roostDirt = {
  layer        = 10,
  speed        = 0,
  speedSpread  = 0.45,
  life         = 170,
  lifeSpread   = 10,
  partpos      = "x,0,z | alpha=(i/6)*pi*2, r=5+rand()*10, x=r*cos(alpha),z=r*sin(alpha)",
  colormap     = { {0, 0, 0, 0.02}, {0.28, 0.30, 0.30, 0.5}, {0.25, 0.25, 0.30, 0.5}, {0, 0, 0, 0.02} },
  rotSpeed     = 0.3,
  rotFactor    = 1.0,
  rotFactorSpread = -2.0,
  rotairdrag   = 0.99,
  rotSpread    = 360,
  size         = 30,
  sizeSpread   = 10,
  sizeGrowth   = 0.08,
  emitVector   = {0,1,0},
  emitRotSpread = 70,
  texture      = 'bitmaps/GPL/smoke_orange.png',
  count        = 5,
  repeatEffect = true,
}

sparks = {
  speed        = 0,
  speedSpread  = 0,
  life         = 90,
  lifeSpread   = 10,
  partpos      = "x,0,0 | if(rand()*2>1) then x=0 else x=20 end",
  colormap     = { {0.8, 0.8, 0.8, 0.01}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, },
  rotSpeed     = 0.1,
  rotFactor    = 1.0,
  rotFactorSpread = -2.0,
  rotairdrag   = 0.99,
  rotSpread    = 360,
  size         = 10,
  sizeSpread   = 12,
  sizeGrowth   = 0.4,
  emitVector   = {0,0,0},
  emitRotSpread = 70,
  texture      = 'bitmaps/PD/Lightningball.TGA',
  count        = 6,
  repeatEffect = true,
}
sparks1 = {
  speed        = 0,
  speedSpread  = 0,
  life         = 20,
  lifeSpread   = 20,
  partpos      = "5-rand()*10, 5-rand()*10, 5-rand()*10 ",
  --partpos      = "0,0,0",
  colormap     = { {0.8, 0.8, 0.2, 0.01}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, },
  rotSpeed     = 0.1,
  rotFactor    = 1.0,
  rotFactorSpread = -2.0,
  rotairdrag   = 0.99,
  rotSpread    = 360,
  size         = 10,
  sizeSpread   = 12,
  sizeGrowth   = 0.4,
  emitVector   = {0,0,0},
  emitRotSpread = 70,
  texture      = 'bitmaps/PD/Lightningball.TGA',
  count        = 6,
  repeatEffect = true,
}

----------------------------------------------------------------------------
-- Ribbons
----------------------------------------------------------------------------
--commandTrailRed = {color={1,0.1,0.1,1}, width=10, piece="torso"}