--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spGetLocalAllyTeamID   = Spring.GetLocalAllyTeamID
local spGetGameFrame		 = Spring.GetGameFrame
local spGetPositionLosState  = Spring.GetPositionLosState
local spGetSpectatingState   = Spring.GetSpectatingState
local spGetTeamUnits         = Spring.GetTeamUnits
local spGetUnitDefID		 = Spring.GetUnitDefID
local spGetUnitHealth        = Spring.GetUnitHealth
local spGetUnitIsCloaked     = Spring.GetUnitIsCloaked
local spGetUnitIsDead        = Spring.GetUnitIsDead
local spGetUnitPosition      = Spring.GetUnitPosition
local spIsUnitVisible        = Spring.IsUnitVisible
local spSetUnitHealth        = Spring.SetUnitHealth
local spSetUnitRulesParam	 = Spring.SetUnitRulesParam

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Particle Sheath",
		desc = "Protoss-type shields",
		author = "KDR_11k (David Becker), KingRaptor (L.J. Lim)",
		date = "2008-03-08",
		license = "Public Domain",
		layer = -899,
		enabled = false
	}
end

local sheathDefs = include "LuaRules/Configs/sheath_defs.lua"

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local sheathed = {}	--unitID key, sheath HP value
local recharge = {} --unitID key, gameframe value

function gadget:UnitFinished(u,ud,team)
	local stats = sheathDefs[ud]
	--Spring.Echo(stats)
	if stats then
		sheathed[u] = stats.initHP
		if stats.initHP < stats.maxHP then recharge[u] = spGetGameFrame() end
	end
end

function gadget:UnitDestroyed(u, ud, team)
	sheathed[u]=nil
	recharge[u]=nil
end

function gadget:Initialize()
	_G.recharge = recharge
	_G.sheathed = sheathed
	local units = Spring.GetAllUnits()
	for i=1, #units do
		local unitID = units[i]
		gadget:UnitFinished(unitID, Spring.GetUnitDefID(unitID))
	end
end

function gadget:UnitPreDamaged(u, ud, team, damage, para, weapon)
	if not sheathed[u] then return damage end
	local dmg = 0
	recharge[u] = spGetGameFrame() + sheathDefs[ud].regenDelay
	local surplus = sheathed[u] - damage
	if surplus < 0 then
		sheathed[u] = 0
		dmg = -surplus
	else
		sheathed[u] = surplus
	end
	spSetUnitRulesParam(u, "sheathState", sheathed[u]/sheathDefs[ud].maxHP)
	return dmg
end

function gadget:GameFrame(n)
	if n%30 < 0.1 then
		for id, frame in pairs(recharge) do
			local udid = spGetUnitDefID(id)
			if frame < n then
				sheathed[id] = sheathed[id] + sheathDefs[udid].regen
				if sheathed[id] > sheathDefs[udid].maxHP then
					sheathed[id] = sheathDefs[udid].maxHP
					recharge[id] = nil
				end
				spSetUnitRulesParam(id, "sheathState", sheathed[id]/sheathDefs[udid].maxHP)
			end
		end
	end
end

else

--UNSYNCED
--currently draws only for recharging units to save resources
local recharge
local sheathed
local phase=0

local GL_BACK                = GL.BACK
local GL_LEQUAL              = GL.LEQUAL
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local glBlending             = gl.Blending
local glColor                = gl.Color
local glCulling              = gl.Culling
local glDepthTest            = gl.DepthTest
local glLighting             = gl.Lighting
local glPolygonOffset        = gl.PolygonOffset
local glUnit                 = gl.Unit
local Unit = glUnit
local IsUnitVisible = spIsUnitVisible
local GetUnitPosition = spGetUnitPosition
local GetPositionLosState=spGetPositionLosState
local GetUnitIsCloaked = spGetUnitIsCloaked

function gadget:Initialize()
	sheathed=SYNCED.sheathed
	recharge=SYNCED.recharge
end

function gadget:DrawWorld()
	local c1=math.sin(phase)*.1 + .1
	local c2=math.sin(phase+ math.pi)*.2 + .2
	phase = phase + .06
	local ateam = spGetLocalAllyTeamID()
	local _,specView = spGetSpectatingState()
	glBlending(GL_ONE, GL_ONE)
	glDepthTest(GL_LEQUAL)
	--glLighting(true)
	glPolygonOffset(-10, -10)
	glCulling(GL_BACK)
	for u,_ in spairs(recharge) do
		local x,y,z = GetUnitPosition(u)
		local _,los = GetPositionLosState(x,y,z,ateam)
		local mult = sheathed[u]/sheathDefs[Spring.GetUnitDefID(u)].maxHP
		glColor(0,c1*mult,c2*mult,1)
		los =  specView or (los and not GetUnitIsCloaked(u))
		if IsUnitVisible(u, 1, true) and los then	--FIXME: no idea what the radius arg in IsUnitVisible does
			Unit(u, true)
		end
	end
	glColor(1,1,1,1)
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	glLighting(false)
	glPolygonOffset(false)
	glCulling(false)
	glDepthTest(false)
end

end
