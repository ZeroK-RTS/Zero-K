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

local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetAllUnits = Spring.GetAllUnits

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local flameFX = {
	layer        = 0,
	speed        = 0.65,
	life         = 30,
	lifeSpread   = 10,
	delaySpread  = 20,
	colormap     = {
		{0, 0, 0, 0.},
		{0.4, 0.4, 0.4, 0.01},
		{0.35, 0.15, 0.15, 0.20},
		{0, 0, 0, 0}
	},
	rotSpeed     = 1,
	rotSpeedSpread = -2,
	rotSpread    = 360,
	sizeSpread   = 1,
	sizeGrowth   = 0.9,
	emitVector   = {0, 1, 0},
	emitRotSpread = 60,
	texture      = 'bitmaps/GPL/flame.png',
	count        = 5,

	-- fields that differ per instance (here for reference and static tables)
	force = {0, 1, 0},
	pos = {0, 0, 0},
	partpos = "",
	size = 1,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local AddParticles

local GetWind = Spring.GetWind
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRadius   = Spring.GetUnitRadius

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if not WG.Lups then
		widgetHandler:RemoveCallIn("GameFrame")
		return
	end
	AddParticles = WG.Lups.AddParticles
end

local CHECK_INTERVAL = 6

local burningUnits = { count = 0 }
function widget:GameFrame(n)
	if n % CHECK_INTERVAL ~= 0 then
		return
	end

	burningUnits.count = 0
	local units = spGetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		if spGetUnitRulesParam(unitID, "on_fire") == 1 then
			burningUnits.count = burningUnits.count + 1
			burningUnits[burningUnits.count] = unitID
		end
	end

	if burningUnits.count == 0 then
		return
	end

	local wx, wy, wz = GetWind()
	flameFX.force[1] = wx * 0.09
	flameFX.force[2] = wy * 0.09 + 3
	flameFX.force[3] = wz * 0.09

	for i = 1, burningUnits.count do
		local unitID = burningUnits[i]

		local x, y, z = spGetUnitPosition(unitID)
		local r = spGetUnitRadius(unitID)
		if (r and x) and math.random(400) < (400 - burningUnits.count) then
			flameFX.pos[1] = x
			flameFX.pos[2] = y
			flameFX.pos[3] = z
			flameFX.partpos = "r*sin(alpha),0,r*cos(alpha) | alpha=rand()*2*pi, r=rand()*0.6*" .. r
			flameFX.size    = r * 0.35
			AddParticles('SimpleParticles2', flameFX)
		end
	end
end
