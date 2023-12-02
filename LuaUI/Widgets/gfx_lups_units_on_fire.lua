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
local spGetUnitHealth = Spring.GetUnitHealth

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local trackedUnits = IterableMap.New()

local CHECK_INTERVAL = 6
local UNIT_TIMEOUT = 140

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local flameFX = {
	layer        = 0,
	speed        = 0.65,
	life         = 25,
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
	sizeGrowth   = 0.8,
	emitVector   = {0, 1, 0},
	emitRotSpread = 60,
	texture      = 'bitmaps/GPL/flame.png',
	count        = 5,

	-- fields that differ per instance (here for reference and static tables)
	force = {0, 1, 0},
	pos = {0, 0, 0},
	partpos = "",
	size = 2,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local AddParticles

local GetWind           = Spring.GetWind
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRadius   = Spring.GetUnitRadius

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateFlameFxToDuration(unitID, flameFX, frame)
	local endFrame = spGetUnitRulesParam(unitID, "on_fire_max_frame") or frame
	local remaining = math.max(0, endFrame - frame)
	
	flameFX.life = remaining * 0.05 + 25
	flameFX.lifeSpread = flameFX.life * 0.2 + 5
	flameFX.speed = math.min(0.65, 0.8 * math.pow(0.99, remaining))
	flameFX.force[2] = 1.5 + math.min(1.5, 1.8 * math.pow(0.999, remaining))
	flameFX.emitRotSpread = math.max(25, 70 - remaining * 0.006)
	
	flameFX.colormap[3][1] = math.max(0.15, 0.35 - remaining * 0.001)
end

local function UpdateBurningUnit(unitID, timeoutFrame, index, flameFX, gameFrame, passsChance)
	if not spGetUnitHealth(unitID) then
		--  Dead or outside LOS, just wait until update time to remove
		return (timeoutFrame > gameFrame)
	end
	if not (spGetUnitRulesParam(unitID, "on_fire") == 1) then
		return true -- Remove
	end
	
	local x, y, z = spGetUnitPosition(unitID)
	local r = spGetUnitRadius(unitID)
	if (r and x) and math.random() < passsChance then
		local intensity = UpdateFlameFxToDuration(unitID, flameFX, gameFrame)
		flameFX.pos[1] = x
		flameFX.pos[2] = y
		flameFX.pos[3] = z
		flameFX.partpos = "r*sin(alpha),0,r*cos(alpha) | alpha=rand()*2*pi, r=rand()*0.6*" .. r
		flameFX.size    = r * 0.35
		AddParticles('SimpleParticles2', flameFX)
	end
end

function widget:GameFrame(n)
	local unitOnFireUpdateUnitID = Spring.GetGameRulesParam("unitOnFireUpdateUnitID")
	if unitOnFireUpdateUnitID then
		IterableMap.Add(trackedUnits, unitOnFireUpdateUnitID, n + UNIT_TIMEOUT)
	end

	if n % CHECK_INTERVAL ~= 0 then
		return
	end

	if IterableMap.IsEmpty(trackedUnits) then
		return
	end

	local wx, wy, wz = GetWind()
	flameFX.force[1] = wx * 0.04
	flameFX.force[3] = wz * 0.04
	local count = IterableMap.GetIndexMax(trackedUnits)
	IterableMap.Apply(trackedUnits, UpdateBurningUnit, flameFX, n, math.max(0, math.min(1, 1 - (count - 400)/400)))
end

function widget:Initialize()
	if not WG.Lups then
		widgetHandler:RemoveCallIn("GameFrame")
		return
	end
	AddParticles = WG.Lups.AddParticles
end
